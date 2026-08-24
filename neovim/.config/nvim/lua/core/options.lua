local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = "\\"

g.autoformat = true
g.python_lsp = "basedpyright"
g.python_ruff = "ruff"
g.deprecation_warnings = false
g.markdown_recommended_style = 0

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.laststatus = 3
opt.showmode = false
opt.ruler = false
opt.termguicolors = true
opt.pumheight = 10
opt.pumblend = 10
opt.winminwidth = 5
opt.cmdheight = 1
opt.title = true

opt.fillchars = {
  foldopen = "\u{f078}",
  foldclose = "\u{f054}",
  fold = " ",
  foldsep = " ",
  diff = "\u{2571}",
  eob = " ",
}

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.shiftround = true
opt.smartindent = true
opt.wrap = false
opt.linebreak = true
opt.virtualedit = "block"
opt.formatoptions = "jcroqlnt"
opt.undofile = true
opt.undolevels = 10000
opt.autowrite = true
opt.confirm = true

opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "nosplit"
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.smoothscroll = true
opt.jumpoptions = "view"
opt.mouse = "a"

opt.foldlevel = 99
opt.foldtext = ""
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

opt.completeopt = "menu,menuone,noselect"
opt.wildmode = "longest:full,full"

opt.updatetime = 200
opt.timeoutlen = 300

opt.colorcolumn = "80,120"
opt.conceallevel = 2
opt.list = true
opt.spelllang = { "en" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })

opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

vim.schedule(function()
  if vim.env.SSH_TTY then
    opt.clipboard = ""
  else
    opt.clipboard = "unnamedplus"
  end
end)

vim.opt.winborder = "rounded"
