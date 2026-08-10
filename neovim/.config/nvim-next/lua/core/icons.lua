--- ===========================================================================
--- ICONS
--- ===========================================================================
--- Shared glyph table. lualine, trouble, dap and the diagnostic config all
--- pull from here, so the same concept looks the same everywhere.
---
--- Requires a Nerd Font (this setup assumes JetBrains Mono Nerd Font, chosen
--- in the terminal emulator, not here). If you see boxes: wrong font.
---
--- WHY \u{...} ESCAPES INSTEAD OF PASTED GLYPHS
--- Nerd Font icons live in the Unicode Private Use Area. Pasted directly, they
--- are fragile -- editors, terminals and copy-paste round-trips silently
--- mangle or drop them, and the failure mode is a cryptic runtime error rather
--- than a visible mistake. Escapes keep this file pure ASCII: it cannot be
--- corrupted, and it diffs cleanly. Each one is commented with its name.
---
--- Look codepoints up at nerdfonts.com/cheat-sheet.
---
--- NOTE: LSP completion-item kind icons are deliberately NOT here. mini.icons
--- already ships a complete, maintained set and blink.cmp reads it directly --
--- duplicating ~30 glyphs here would just be a second thing to keep in sync.
--- ===========================================================================

return {
  --- Diagnostic severity. Keys match vim.diagnostic.severity names so they can
  --- be looked up by severity directly.
  diagnostics = {
    Error = "\u{ea87} ", -- nf-cod-error
    Warn = "\u{ea6c} ", -- nf-cod-warning
    Hint = "\u{ea61} ", -- nf-cod-lightbulb
    Info = "\u{ea74} ", -- nf-cod-info
  },

  --- Git status. Used by lualine's diff section and gitsigns.
  git = {
    added = "\u{f457} ", -- nf-oct-diff_added
    modified = "\u{f459} ", -- nf-oct-diff_modified
    removed = "\u{f458} ", -- nf-oct-diff_removed
    branch = "\u{e0a0} ", -- nf-pl-branch
  },

  --- Debugger signs (nvim-dap). The Stopped entry is a 3-tuple because
  --- dap's sign_define wants { text, texthl, linehl }.
  dap = {
    Stopped = { "\u{f0055} ", "DiagnosticWarn", "DapStoppedLine" }, -- nf-md-arrow_right_drop_circle
    Breakpoint = "\u{f111} ", -- nf-fa-circle
    BreakpointCondition = "\u{f04b} ", -- nf-fa-play
    BreakpointRejected = { "\u{f00d} ", "DiagnosticError" }, -- nf-fa-times
    LogPoint = "\u{f02b} ", -- nf-fa-tag
  },

  --- Buffer / file state, used by lualine and bufferline.
  file = {
    modified = "\u{25cf} ", -- BLACK CIRCLE (plain Unicode, not Nerd Font)
    readonly = "\u{f023} ", -- nf-fa-lock
    unnamed = "[No Name]",
  },
}
