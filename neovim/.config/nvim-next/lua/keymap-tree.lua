--- ===========================================================================
--- THE <leader> MAP
--- ===========================================================================
--- Individual bindings live in their plugin's `keys = { ... }` spec, because
--- that is what makes lazy loading work: pressing <leader>gd is what causes
--- diffview to load. Move those bindings here and every plugin would load at
--- startup just to register its keys -- defeating the entire point.
---
--- So this file owns the part that ISN'T tied to a plugin: the GROUPS. The
--- prefixes, their names, their icons, and the rule about who owns what.
--- which-key renders these, so pressing <leader> and waiting always shows an
--- accurate, complete menu.
---
--- ---------------------------------------------------------------------------
--- COLLISIONS THAT WERE FIXED (don't reintroduce these)
--- ---------------------------------------------------------------------------
---   <leader>t   used to be claimed by BOTH toggleterm (13 maps) and neotest
---               (10 maps). Test won it; terminal moved to <leader>T.
---   <leader>c   csvview had taken ct/ci/ce/cd inside the LSP "code" group,
---               and cd collided with line-diagnostics. CSV moved to <leader>C.
--- ===========================================================================

local M = {}

--- ---------------------------------------------------------------------------
--- Groups
--- ---------------------------------------------------------------------------
--- Each entry becomes a which-key group header. Icons are \u{...} escapes for
--- the reason explained in core/icons.lua (pasted Nerd Font glyphs get
--- silently mangled). Names from nerdfonts.com/cheat-sheet.
M.groups = {
  --- Top-level prefixes
  { "<leader>a", group = "ai", icon = "\u{f544} " }, -- nf-fa-robot
  { "<leader>b", group = "buffer", icon = "\u{f0c5} " }, -- nf-fa-files_o
  { "<leader>c", group = "code", icon = "\u{f121} " }, -- nf-fa-code
  { "<leader>C", group = "csv", icon = "\u{f0ce} " }, -- nf-fa-table
  { "<leader>d", group = "debug", icon = "\u{f188} " }, -- nf-fa-bug
  { "<leader>f", group = "file/find", icon = "\u{f002} " }, -- nf-fa-search
  { "<leader>g", group = "git", icon = "\u{f1d3} " }, -- nf-fa-git
  { "<leader>gh", group = "hunk", icon = "\u{f440} " }, -- nf-oct-diff
  { "<leader>j", group = "jq", icon = "\u{f0b0} " }, -- nf-fa-filter
  { "<leader>n", group = "notebook", icon = "\u{f0e7} " }, -- nf-fa-bolt
  { "<leader>o", group = "obsidian", icon = "\u{f02d} " }, -- nf-fa-book
  { "<leader>q", group = "quit/session", icon = "\u{f011} " }, -- nf-fa-power_off
  { "<leader>s", group = "search", icon = "\u{f002} " }, -- nf-fa-search
  { "<leader>t", group = "test", icon = "\u{f0c3} " }, -- nf-fa-flask
  { "<leader>T", group = "terminal", icon = "\u{f120} " }, -- nf-fa-terminal
  { "<leader>u", group = "ui/toggle", icon = "\u{f013} " }, -- nf-fa-cog
  { "<leader>w", group = "window", icon = "\u{f2d2} " }, -- nf-fa-window_restore
  { "<leader>x", group = "diagnostics", icon = "\u{f071} " }, -- nf-fa-warning

  --- Non-leader prefixes worth labelling
  { "[", group = "prev" },
  { "]", group = "next" },
  { "g", group = "goto" },
  { "z", group = "fold" },
}

--- ---------------------------------------------------------------------------
--- Ownership map -- documentation, not configuration
--- ---------------------------------------------------------------------------
--- Which file to open when you want to change a given prefix. Nothing reads
--- this at runtime; it exists so the answer to "where is <leader>g defined?"
--- takes five seconds instead of a grep.
---
---   <leader>a   plugins/tools.lua        claudecode.nvim
---   <leader>b   plugins/ui.lua           bufferline
---   <leader>c   util/lsp.lua             LSP actions (on LspAttach)
---   <leader>C   plugins/lang/sql.lua     csvview
---   <leader>d   plugins/debug.lua        nvim-dap
---   <leader>f   plugins/ui.lua           snacks.picker + snacks.explorer
---   <leader>g   plugins/git.lua          gitsigns / diffview / lazygit
---   <leader>j   plugins/lang/json.lua    jq.nvim (jq/yq over the buffer)
---   <leader>n   plugins/lang/notebook.lua ipynb.nvim
---   <leader>o   plugins/lang/markdown.lua obsidian.nvim
---   <leader>q   plugins/editor.lua       persistence.nvim
---   <leader>s   plugins/ui.lua           snacks.picker
---   <leader>t   plugins/test.lua         neotest
---   <leader>T   plugins/tools.lua        toggleterm
---   <leader>u   plugins/ui.lua           snacks.toggle
---   <leader>x   plugins/lsp.lua          trouble.nvim
---
--- Standalone keys, no group:
---   <leader><space>  find files          <leader>/  grep
---   <leader>,        buffers             <leader>:  command history
---   <leader>e        file explorer       <leader>l  Lazy (core/lazy.lua)
---   <leader>D        database UI         <leader>m  multicursor

--- ---------------------------------------------------------------------------
--- VS Code compatibility layer
--- ---------------------------------------------------------------------------
--- Bindings that exist purely so VS Code muscle memory keeps working. These
--- are duplicates -- the Vim-native way always still works too.
---
--- Set here (rather than in each plugin spec) only when they need no plugin;
--- the plugin-backed ones are declared in the relevant spec and listed here
--- for reference:
---
---   <C-p>       find files              plugins/ui.lua    (snacks.picker)
---   <C-S-p>     command palette         plugins/ui.lua    (snacks.picker)
---   <C-S-f>     find in project         plugins/ui.lua    (snacks.picker)
---   <C-b>       toggle sidebar          plugins/ui.lua    (snacks.explorer)
---   <C-`>       toggle terminal         plugins/tools.lua (toggleterm)
---   <C-/>       toggle comment          built-in gcc, remapped in editor.lua
---   <C-s>       save                    core/keymaps.lua
---   <C-a>       select all              core/keymaps.lua
---   F2          rename symbol           util/lsp.lua
---   F5 / S-F5   debug continue / stop   plugins/debug.lua
---   F9          toggle breakpoint       plugins/debug.lua
---   F10 / F11   step over / step into   plugins/debug.lua

--- ---------------------------------------------------------------------------
--- Registration
--- ---------------------------------------------------------------------------
--- Called by which-key's config in plugins/ui.lua.
function M.setup()
  require("which-key").add(M.groups)
end

return M
