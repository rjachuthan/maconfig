--- ===========================================================================
--- FORMAT
--- ===========================================================================
--- Replaces `LazyVim.format`.
---
--- IMPORTANT: format-on-save is NOT conform's built-in `format_on_save`.
--- LazyVim owned that behaviour itself -- `vim.g.autoformat` plus a
--- BufWritePre hook living in ITS code, not conform's. Removing LazyVim
--- removes format-on-save entirely unless something reimplements that hook.
--- This module is that something. See plugins/lsp.lua's conform spec for the
--- matching "do NOT set format_on_save there" comment.
---
--- Formatters register themselves here (conform at priority 100, the LSP
--- fallback below it) so `M.format()` doesn't need to know conform exists --
--- it just runs whichever registered formatter claims the buffer.
--- ===========================================================================

local M = {}

--- ---------------------------------------------------------------------------
--- Registry
--- ---------------------------------------------------------------------------
--- Each entry: { name, priority, resolve = fn(buf) -> formatter|nil }.
--- `formatter` is a table with `:format(buf)`, so both conform's API and the
--- built-in `vim.lsp.buf.format` fallback fit the same shape here.
M._formatters = {}

--- Register a formatter source. Higher `priority` runs first when more than
--- one source can handle the buffer.
---@param entry { name: string, priority: integer, resolve: fun(buf: integer): table|nil }
function M.register(entry)
  table.insert(M._formatters, entry)
  table.sort(M._formatters, function(a, b) return a.priority > b.priority end)
end

--- Resolve the formatter that would actually run for `buf`, in priority
--- order. Returns nil if nothing claims it.
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

--- Built-in fallback: plain `vim.lsp.buf.format`, used when conform has no
--- formatter configured for the filetype. Always "available" -- it defers to
--- whether an LSP client that supports formatting is attached at format time.
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

--- conform.nvim registers itself at priority 100 (higher than the LSP
--- fallback above) from its own spec in plugins/lsp.lua, via:
---   require("util.format").register({ name = "conform", priority = 100, resolve = ... })

--- ---------------------------------------------------------------------------
--- Enable / disable
--- ---------------------------------------------------------------------------

--- Whether autoformat is on for `buf`: buffer-local overrides global; if the
--- buffer-local value was never set (nil, not false), fall back to the
--- global `vim.g.autoformat`.
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

--- Toggle global (drives <leader>uf) or buffer-local (<leader>uF) autoformat.
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

--- ---------------------------------------------------------------------------
--- Formatting
--- ---------------------------------------------------------------------------

--- Run whichever formatter claims the buffer: conform if it has one
--- configured for this filetype, else the LSP fallback.
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

--- ---------------------------------------------------------------------------
--- formatexpr
--- ---------------------------------------------------------------------------
--- Wired up in setup() below as 'formatexpr'. Used by `gq` and `=`. Falling
--- through to the builtin (returning 1) matters: LSP-driven formatexpr is
--- meant for code ranges, and using it for prose/comments under `gq` gives
--- wrong results -- the builtin's textwidth-wrapping is what you actually want
--- there.
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
  return 1 -- fall through to the builtin formatexpr
end

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

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

--- ---------------------------------------------------------------------------
--- Info
--- ---------------------------------------------------------------------------

--- A :checkhealth-ish report: what M.format() would actually do right now.
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
