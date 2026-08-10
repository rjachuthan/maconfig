--- ===========================================================================
--- OPTIONS
--- ===========================================================================
--- Everything here used to be set invisibly by LazyVim. It is transcribed
--- explicitly so that when the editor behaves a certain way, you can find out
--- why by reading one file.
---
--- Anything you want to change, change here. Nothing else reads these.
---
--- Two options LazyVim set are DELIBERATELY different:
---   'formatexpr'   pointed at v:lua.LazyVim.format.formatexpr() -- now ours
---   'statuscolumn' pointed at v:lua.LazyVim.statuscolumn()      -- now snacks
--- Copying those verbatim would throw an error on every `gq` and every redraw.
--- ===========================================================================

local opt = vim.opt
local g = vim.g

--- ---------------------------------------------------------------------------
--- Leader keys
--- Must be set BEFORE lazy.nvim loads, or plugin `keys` specs bind to the
--- wrong prefix. This is why options.lua is required first in init.lua.
--- ---------------------------------------------------------------------------
g.mapleader = " " --  Space. Every <leader>x mapping hangs off this.
g.maplocalleader = "\\" --  Buffer-local / filetype-specific maps.

--- ---------------------------------------------------------------------------
--- Config-wide feature flags
--- Read by our own modules (util/format.lua, plugins/lang/python.lua, ...).
--- These are the knobs worth flipping.
--- ---------------------------------------------------------------------------
g.autoformat = true --  Format on save. Toggle live: <leader>uf / <leader>uF
g.python_lsp = "basedpyright" --  "basedpyright" (stricter) or "pyright"
g.python_ruff = "ruff" --  Ruff handles both linting and formatting
g.deprecation_warnings = false --  Silence plugin API deprecation noise
g.markdown_recommended_style = 0 --  Don't let the ftplugin force tabstop=4

--- ---------------------------------------------------------------------------
--- Interface
--- ---------------------------------------------------------------------------
opt.number = true --  Absolute line number on the cursor line
opt.relativenumber = true --  Relative elsewhere, so 5j / 12k are countable
opt.cursorline = true --  Highlight the current line
opt.signcolumn = "yes" --  Always reserve the gutter; prevents text jitter
                       --  when diagnostics/git signs appear and disappear
opt.laststatus = 3 --  ONE global statusline, not one per split
opt.showmode = false --  lualine already shows the mode
opt.ruler = false --  Same, lualine owns this
opt.termguicolors = true --  24-bit colour. Required by every modern theme.
opt.pumheight = 10 --  Cap completion popup at 10 rows
opt.pumblend = 10 --  Slight transparency on the popup menu
opt.winminwidth = 5 --  Never squash a split below 5 columns
opt.cmdheight = 1 --  noice moves most messages out of here anyway
opt.title = true --  Let the terminal/tab show the filename

--- Fold column glyphs, and -- importantly -- a blank `eob` so the tildes after
--- the last line disappear. Small thing, big visual difference.
--- Escapes rather than pasted glyphs: see the note in core/icons.lua. Each
--- field here must be EXACTLY one character or Neovim raises E1511.
opt.fillchars = {
  foldopen = "\u{f078}", -- nf-fa-chevron_down
  foldclose = "\u{f054}", -- nf-fa-chevron_right
  fold = " ",
  foldsep = " ",
  diff = "\u{2571}", -- BOX DRAWINGS LIGHT DIAGONAL
  eob = " ", -- blank: hides the ~ after end-of-buffer
}

--- ---------------------------------------------------------------------------
--- Editing behaviour
--- ---------------------------------------------------------------------------
opt.expandtab = true --  Tab key inserts spaces
opt.shiftwidth = 2 --  2 spaces per indent level (Python overrides to 4
                   --  via its ftplugin -- see plugins/lang/python.lua)
opt.tabstop = 2 --  A literal tab renders as 2 columns
opt.shiftround = true --  Round indents to a multiple of shiftwidth
opt.smartindent = true --  Language-aware autoindent on new lines
opt.wrap = false --  No soft wrap by default (toggle: <leader>uw)
opt.linebreak = true --  ...but when wrap IS on, break at word boundaries
opt.virtualedit = "block" --  Let visual-block select past end of line
opt.formatoptions = "jcroqlnt" --  j=join comments cleanly, r/o=continue
                               --  comment leader, q=allow gq, n=numbered lists
opt.undofile = true --  Persist undo history across restarts
opt.undolevels = 10000 --  ...and keep a lot of it
opt.autowrite = true --  Save automatically on :make, :next, etc.
opt.confirm = true --  Prompt to save instead of refusing to quit

--- Swap and backup are off. With undofile, autosave and git, they only ever
--- produced E325 "swap file already exists" prompts after a crash.
opt.swapfile = false
opt.backup = false
opt.writebackup = false

--- ---------------------------------------------------------------------------
--- Search
--- ---------------------------------------------------------------------------
opt.ignorecase = true --  Case-insensitive by default...
opt.smartcase = true --  ...unless the pattern contains a capital
opt.inccommand = "nosplit" --  Live preview of :s///  as you type it
opt.grepprg = "rg --vimgrep" --  ripgrep instead of grep (much faster)
opt.grepformat = "%f:%l:%c:%m"

--- ---------------------------------------------------------------------------
--- Splits and navigation
--- ---------------------------------------------------------------------------
opt.splitbelow = true --  :split opens below, not above
opt.splitright = true --  :vsplit opens right, not left
opt.splitkeep = "screen" --  Don't scroll the old window when splitting
opt.scrolloff = 4 --  Keep 4 lines of context above/below the cursor
opt.sidescrolloff = 8 --  Same horizontally
opt.smoothscroll = true --  Smooth scroll over wrapped lines
opt.jumpoptions = "view" --  Restore the view, not just the cursor, on <C-o>
opt.mouse = "a" --  Mouse works in all modes (resizing splits is genuinely
                 --  nicer with it, VS Code muscle memory dies hard)

--- ---------------------------------------------------------------------------
--- Folding
--- Treesitter-based, but everything starts unfolded. `foldlevel = 99` means
--- "open everything"; use zc/zo/za to fold deliberately.
--- ---------------------------------------------------------------------------
opt.foldlevel = 99
opt.foldtext = "" --  Neovim 0.10+ renders the folded line with syntax
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

--- ---------------------------------------------------------------------------
--- Completion
--- ---------------------------------------------------------------------------
opt.completeopt = "menu,menuone,noselect" --  Show menu even for one match,
                                          --  never auto-select the first item
opt.wildmode = "longest:full,full" --  Command-line completion behaviour

--- ---------------------------------------------------------------------------
--- Timing
--- ---------------------------------------------------------------------------
opt.updatetime = 200 --  Faster CursorHold -> quicker LSP hover/highlight
opt.timeoutlen = 300 --  How long which-key waits before popping up.
                     --  Lower = snappier menu, but harder to type multi-key
                     --  maps deliberately. 300ms is the sweet spot.

--- ---------------------------------------------------------------------------
--- Misc
--- ---------------------------------------------------------------------------
opt.conceallevel = 2 --  Render markdown/obsidian concealed syntax
opt.list = true --  Show whitespace glyphs (listchars defaults are fine)
opt.spelllang = { "en" } --  Spellcheck only enabled for prose filetypes,
                         --  see core/autocmds.lua
opt.shortmess:append({ W = true, I = true, c = true, C = true })
--  W: no "written" message   I: no intro screen
--  c: no completion messages C: no scanning-tags messages

--- Session contents -- what persistence.nvim restores.
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

--- System clipboard. Deliberately deferred: querying the clipboard provider
--- at startup costs ~20ms, and under SSH we want OSC 52 instead of a provider.
--- Scheduling it means startup doesn't pay for it.
vim.schedule(function()
  if vim.env.SSH_TTY then
    opt.clipboard = "" --  Let the OSC 52 provider handle it over SSH
  else
    opt.clipboard = "unnamedplus" --  y/p use the system clipboard directly
  end
end)
