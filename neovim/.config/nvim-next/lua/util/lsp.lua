--- ===========================================================================
--- LSP
--- ===========================================================================
--- Diagnostic display config, plus everything bound on LspAttach: keymaps,
--- inlay hints, document highlight.
---
--- DELIBERATE DEPARTURE FROM LAZYVIM: LazyVim gated each keymap on server
--- capability (`has = "definition"`, etc.) before binding it. Here they are
--- bound unconditionally on every attach. Simpler code, and the failure mode
--- of pressing e.g. `gy` against a server with no type-definition support is
--- a harmless "no location found" echo -- not worth the capability-checking
--- machinery to avoid.
--- ===========================================================================

local icons = require("core.icons").diagnostics

local M = {}

--- ---------------------------------------------------------------------------
--- Diagnostics
--- ---------------------------------------------------------------------------

function M.setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "\u{25cf} ", -- BLACK CIRCLE (plain Unicode, matches core/icons.lua's file.modified)
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

--- ---------------------------------------------------------------------------
--- Inlay hints
--- ---------------------------------------------------------------------------

---@param buf integer
---@param client vim.lsp.Client
local function setup_inlay_hints(buf, client)
  if not client:supports_method("textDocument/inlayHint") then
    return
  end
  vim.lsp.inlay_hint.enable(true, { bufnr = buf })
end

--- The <leader>uh TOGGLE ITSELF is bound in plugins/ui.lua via
--- `Snacks.toggle.inlay_hints()` (that file owns the whole <leader>u group,
--- per keymap-tree.lua's ownership table). Snacks calls straight into
--- `vim.lsp.inlay_hint.enable`, so nothing here needs to duplicate it --
--- `setup_inlay_hints` above just has to make sure hints are ON by default
--- whenever a capable server attaches, so there's something to toggle off.

--- ---------------------------------------------------------------------------
--- Document highlight
--- ---------------------------------------------------------------------------
--- Highlights other references to the symbol under the cursor while it's
--- idle (CursorHold), clears them the moment the cursor moves.

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
  -- Cleaned up on detach so a re-attach (server restart) doesn't accumulate
  -- duplicate augroups for the same buffer.
  vim.api.nvim_create_autocmd("LspDetach", {
    buffer = buf,
    once = true,
    callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end,
  })
end

--- ---------------------------------------------------------------------------
--- Keymaps
--- ---------------------------------------------------------------------------
--- All bound unconditionally -- see the module-level comment on why.

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

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

--- Called once from plugins/lsp.lua's nvim-lspconfig `config`.
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
