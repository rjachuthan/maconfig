local M = {}

M._formatters = {}

---@param entry { name: string, priority: integer, resolve: fun(buf: integer): table|nil }
function M.register(entry)
  table.insert(M._formatters, entry)
  table.sort(M._formatters, function(a, b) return a.priority > b.priority end)
end

---@param buf integer
---@return { name: string, formatter: table }|nil
local function resolve(buf)
  for _, entry in ipairs(M._formatters) do
    local formatter = entry.resolve(buf)
    if formatter then
      return { name = entry.name, formatter = formatter }
    end
  end
  return nil
end

M.register({
  name = "lsp",
  priority = 10,
  resolve = function(buf)
    local has_client = false
    for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client:supports_method("textDocument/formatting") then
        has_client = true
        break
      end
    end
    if not has_client then
      return nil
    end
    return {
      format = function(_, opts)
        vim.lsp.buf.format(vim.tbl_extend("force", { bufnr = buf }, opts or {}))
      end,
    }
  end,
})

---@param buf integer|nil
---@return boolean
function M.enabled(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local buf_value = vim.b[buf].autoformat
  if buf_value == nil then
    return vim.g.autoformat == true
  end
  return buf_value == true
end

---@param state boolean
---@param buf integer|nil
local function notify_state(state, buf)
  vim.notify(
    "Autoformat " .. (state and "enabled" or "disabled") .. (buf and " (buffer)" or ""),
    vim.log.levels.INFO,
    { title = "format" }
  )
end

---@param global boolean
function M.toggle(global)
  if global then
    vim.g.autoformat = not (vim.g.autoformat == true)
    notify_state(vim.g.autoformat)
  else
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].autoformat = not M.enabled(buf)
    notify_state(vim.b[buf].autoformat, buf)
  end
end

function M.enable(global)
  if global then
    vim.g.autoformat = true
  else
    vim.b.autoformat = true
  end
end

function M.disable(global)
  if global then
    vim.g.autoformat = false
  else
    vim.b.autoformat = false
  end
end

---@param opts { buf?: integer, force?: boolean }|nil `force` bypasses M.enabled()
function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if not opts.force and not M.enabled(buf) then
    return
  end
  local found = resolve(buf)
  if not found then
    return
  end
  found.formatter.format(buf, { async = false, lsp_format = "fallback" })
end

---@return integer
function M.formatexpr()
  if vim.bo.filetype == "" then
    return 1
  end
  local buf = vim.api.nvim_get_current_buf()
  for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client:supports_method("textDocument/rangeFormatting") then
      return vim.lsp.formatexpr({ timeout_ms = 3000 })
    end
  end
  return 1
end

function M.setup()
  vim.o.formatexpr = "v:lua.require'util.format'.formatexpr()"

  local augroup = vim.api.nvim_create_augroup("nvim_util_format", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    callback = function(ev)
      M.format({ buf = ev.buf })
    end,
    desc = "Format on save (see M.enabled for the toggle)",
  })

  vim.api.nvim_create_user_command("FormatInfo", function()
    M.info()
  end, { desc = "Show which formatter(s) would run for the current buffer" })
end

function M.info()
  local buf = vim.api.nvim_get_current_buf()
  local lines = {
    "autoformat: " .. (M.enabled(buf) and "enabled" or "disabled") .. " (buffer=" .. tostring(vim.b[buf].autoformat) .. ", global=" .. tostring(vim.g.autoformat) .. ")",
    "",
  }
  local found = resolve(buf)
  if found then
    table.insert(lines, "would run: " .. found.name)
  else
    table.insert(lines, "would run: nothing (no formatter claims this buffer)")
  end
  table.insert(lines, "")
  table.insert(lines, "registered sources, in priority order:")
  for _, entry in ipairs(M._formatters) do
    table.insert(lines, ("  %-8s priority=%d"):format(entry.name, entry.priority))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "FormatInfo" })
end

return M
