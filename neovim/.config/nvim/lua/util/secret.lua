-- Read secrets (tokens, private names) from the OS secret store so they never live
-- in shell rc files or this repo.
--
--   macOS:   login Keychain, generic password with service = <name>
--   Windows: DPAPI-encrypted PSCredential at %LOCALAPPDATA%\nvim-secrets\<name>.xml
--            (decryptable only by the same Windows user on the same machine)
--
-- Values are cached for the session after the first lookup.
local platform = require("core.platform")

local M = {}
local cache = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function run(cmd)
  local out = vim.system(cmd, { text = true }):wait()
  if out.code ~= 0 or not out.stdout then
    return nil
  end
  local value = trim(out.stdout)
  return value ~= "" and value or nil
end

local function lookup(name)
  if platform.is_mac then
    return run({ "security", "find-generic-password", "-s", name, "-w" })
  elseif platform.is_win then
    local path = vim.fs.joinpath(vim.env.LOCALAPPDATA, "nvim-secrets", name .. ".xml")
    if vim.fn.filereadable(path) == 0 then
      return nil
    end
    local ps = ("(Import-Clixml -LiteralPath '%s').GetNetworkCredential().Password"):format(path)
    return run({ "powershell", "-NoProfile", "-NonInteractive", "-Command", ps })
  end
  return nil
end

--- Return the secret stored under `name`, or nil (with a warning) if missing.
---@param name string
---@return string|nil
function M.get(name)
  if cache[name] == nil then
    local value = lookup(name)
    if not value then
      vim.notify(("Secret %q not found in the OS secret store"):format(name), vim.log.levels.WARN)
    end
    cache[name] = value or false
  end
  return cache[name] or nil
end

return M
