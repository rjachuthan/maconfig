local icons = require("core.icons").diagnostics

local M = {}

function M.setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "\u{25cf} ",
      source = "if_many",
    },
    severity_sort = true,
    underline = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = icons.Error,
        [vim.diagnostic.severity.WARN] = icons.Warn,
        [vim.diagnostic.severity.HINT] = icons.Hint,
        [vim.diagnostic.severity.INFO] = icons.Info,
      },
    },
    float = { border = "rounded" },
  })
end

---@param buf integer
---@param client vim.lsp.Client
local function setup_inlay_hints(buf, client)
  if not client:supports_method("textDocument/inlayHint") then
    return
  end
  vim.lsp.inlay_hint.enable(true, { bufnr = buf })
end

---@param buf integer
---@param client vim.lsp.Client
local function setup_document_highlight(buf, client)
  if not client:supports_method("textDocument/documentHighlight") then
    return
  end
  local group = vim.api.nvim_create_augroup("nvim_lsp_highlight_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    buffer = buf,
    callback = function() vim.lsp.buf.document_highlight() end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
    group = group,
    buffer = buf,
    callback = function() vim.lsp.buf.clear_references() end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    buffer = buf,
    once = true,
    callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end,
  })
end

---@param buf integer
local function setup_keymaps(buf)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end

  map("n", "gd", vim.lsp.buf.definition, "Goto definition")
  map("n", "gr", vim.lsp.buf.references, "Goto references")
  map("n", "gI", vim.lsp.buf.implementation, "Goto implementation")
  map("n", "gy", vim.lsp.buf.type_definition, "Goto type definition")
  map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
  map("n", "K", vim.lsp.buf.hover, "Hover")
  map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
  map("i", "<c-k>", vim.lsp.buf.signature_help, "Signature help")

  map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>cA", function()
    vim.lsp.buf.code_action({ context = { only = { "source" } } })
  end, "Source action")
  map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
  map("n", "<F2>", vim.lsp.buf.rename, "Rename (VS Code)")
  map("n", "<leader>cl", "<cmd>LspInfo<cr>", "LSP info")
  map({ "n", "x" }, "<leader>cf", function() require("util.format").format({ force = true }) end, "Format")
  map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
end

function M.setup()
  M.setup_diagnostics()

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("nvim_lsp_attach", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client then
        return
      end
      setup_keymaps(ev.buf)
      setup_inlay_hints(ev.buf, client)
      setup_document_highlight(ev.buf, client)
    end,
    desc = "Configure buffer-local LSP keymaps/features on attach",
  })
end

return M
