-- Builds vim-dadbod connection URLs from environment variables, so no
-- credentials ever land in the repo. Anything whose env vars are missing is
-- simply skipped.
local M = {}

-- Nothing else puts a project's `.env` into nvim's environment: there is no
-- direnv here, and the shell never sources it. Without this the SF_*/MSSQL_*
-- lookups below all come back nil and g:dbs ends up empty, which reads as
-- "dadbod is broken" rather than "no credentials found". Walk up from the cwd
-- for the nearest `.env` and fill in only what the real environment lacks, so
-- an explicit export always wins.
---@param start string|nil
local function load_dotenv(start)
  local dir = vim.fn.fnamemodify(start or vim.fn.getcwd(), ":p")
  local found = vim.fs.find(".env", { path = dir, upward = true, type = "file" })[1]
  if not found then
    return
  end
  for line in io.lines(found) do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.*)$")
    if key and not line:match("^%s*#") then
      value = value:gsub("%s+$", "")
      -- Strip one matching pair of surrounding quotes; a shell sourcing the
      -- same file would, and the paths in there are written expecting it.
      local unquoted = value:match('^"(.*)"$') or value:match("^'(.*)'$")
      value = unquoted or value
      if (vim.env[key] == nil or vim.env[key] == "") and value ~= "" then
        vim.env[key] = value
      end
    end
  end
end

---@param name string
---@return string|nil
local function env(name)
  local value = vim.env[name]
  if value == nil or value == "" then
    return nil
  end
  return value
end

-- dadbod percent-decodes URL params and turns `+` into a space, so paths and
-- passwords have to go in encoded.
---@param value string
---@return string
local function encode(value)
  return (value:gsub("[^%w%-%._~]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

---@param params string[]
---@param key string
---@param value string|nil
local function add(params, key, value)
  if value then
    table.insert(params, key .. "=" .. encode(value))
  end
end

--- Snowflake over snowsql with key-pair auth.
--- Reads SF_ACCOUNT, SF_USER, SF_ROLE, SF_WAREHOUSE, SF_DATABASE, SF_SCHEMA,
--- SF_PRIVATE_KEY_PATH, SF_PRIVATE_KEY_PASSPHRASE.
---@return string|nil url
function M.snowflake()
  local account, user = env("SF_ACCOUNT"), env("SF_USER")
  if not (account and user) then
    return nil
  end

  -- dadbod forwards every query param to snowsql as `--<param>=<value>`, so
  -- these have to be snowsql's *long* option names. It has no `--role` or
  -- `--schema`; passing those makes it exit 2 before it ever connects.
  local params = {}
  add(params, "warehouse", env("SF_WAREHOUSE"))
  add(params, "rolename", env("SF_ROLE"))
  add(params, "schemaname", env("SF_SCHEMA"))

  local key = env("SF_PRIVATE_KEY_PATH")
  if key then
    add(params, "private-key-path", vim.fn.expand(key))
    -- snowsql only takes the passphrase from the environment, never a flag.
    if env("SF_PRIVATE_KEY_PASSPHRASE") then
      vim.env.SNOWSQL_PRIVATE_KEY_PASSPHRASE = env("SF_PRIVATE_KEY_PASSPHRASE")
    end
  end

  local url = ("snowflake://%s@%s/%s"):format(encode(user), account, encode(env("SF_DATABASE") or ""))
  if #params > 0 then
    url = url .. "?" .. table.concat(params, "&")
  end
  return url
end

--- SQL Server over the Go rewrite of sqlcmd (`microsoft/go-sqlcmd`), which is
--- the one that speaks Entra ID. MSSQL_AUTH defaults to
--- ActiveDirectoryInteractive: it pops a browser and completes whatever MFA
--- method the account is enrolled in. ActiveDirectoryDeviceCode works over SSH.
--- Reads MSSQL_SERVER, MSSQL_PORT, MSSQL_DATABASE, MSSQL_USER, MSSQL_AUTH.
---@return string|nil url
function M.sqlserver()
  local server = env("MSSQL_SERVER")
  if not server then
    return nil
  end

  local params = { "authentication=" .. encode(env("MSSQL_AUTH") or "ActiveDirectoryInteractive") }
  add(params, "encrypt", "true")

  local url = "sqlserver://"
  local user = env("MSSQL_USER")
  if user then
    url = url .. encode(user) .. "@"
  end
  url = url .. server
  if env("MSSQL_PORT") then
    url = url .. ":" .. env("MSSQL_PORT")
  end
  url = url .. "/" .. encode(env("MSSQL_DATABASE") or "")
  return url .. "?" .. table.concat(params, "&")
end

--- Connection list in the shape dadbod-ui expects for g:dbs.
---@return { name: string, url: string }[]
function M.connections()
  load_dotenv()
  local dbs = {}
  for name, builder in pairs({ Snowflake = M.snowflake, SQLServer = M.sqlserver }) do
    local url = builder()
    if url then
      table.insert(dbs, { name = name, url = url })
    end
  end
  table.sort(dbs, function(a, b)
    return a.name < b.name
  end)
  return dbs
end

return M
