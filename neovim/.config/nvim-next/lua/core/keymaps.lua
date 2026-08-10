--- ===========================================================================
--- KEYMAPS (core)
--- ===========================================================================
--- ONLY mappings that need no plugin live here. Anything belonging to a plugin
--- is declared in that plugin's `keys` spec, and the <leader> tree as a whole
--- is described in lua/keymap-tree.lua -- that's the file to read if you want
--- to know "what does <leader>anything do".
---
--- Split that way because plugin keymaps must lazy-load the plugin; if they
--- were set here, every plugin would load at startup just to bind its keys.
--- ===========================================================================

local map = vim.keymap.set

--- ---------------------------------------------------------------------------
--- Movement
--- ---------------------------------------------------------------------------

--- Move by display line when wrapped, but keep counts working: 5j still jumps
--- 5 real lines (so relativenumber stays truthful), bare j walks visual lines.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

--- Keep the cursor centred when jumping around. Much easier to keep your place.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Prev search result" })

--- ---------------------------------------------------------------------------
--- Windows
--- ---------------------------------------------------------------------------
--- On macOS these are intercepted by vim-tmux-navigator (see plugins/tools.lua)
--- so the same keys cross the tmux/nvim boundary. On Windows tmux doesn't
--- exist, the plugin is skipped, and these plain versions do the work.

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

--- Resize with Ctrl+arrows. (Shift+arrows are left free for text selection,
--- which is what a VS Code refugee's fingers expect.)
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Grow window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Shrink window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Shrink window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Grow window width" })

--- ---------------------------------------------------------------------------
--- Buffers
--- ---------------------------------------------------------------------------
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })

--- ---------------------------------------------------------------------------
--- Editing
--- ---------------------------------------------------------------------------

--- Keep the selection after indenting, so you can press < or > repeatedly.
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

--- Move the current line / selection up and down, re-indenting as it goes.
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
map("x", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("x", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

--- Undo break-points: typing one of these then pressing u undoes back to here
--- rather than nuking the whole insert session.
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

--- Escape also clears search highlighting.
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Clear search highlight" })

--- ---------------------------------------------------------------------------
--- VS Code muscle memory
--- ---------------------------------------------------------------------------
--- Deliberately duplicated with the Vim-native equivalents. Use whichever your
--- hands reach for; both keep working. The rest of the VS Code set (<C-p>,
--- <C-S-p>, <C-b>, <C-`>) needs plugins, so it lives in keymap-tree.lua.

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map({ "n", "x" }, "<C-a>", "ggVG", { desc = "Select all" })

--- ---------------------------------------------------------------------------
--- Quickfix / location list
--- ---------------------------------------------------------------------------
map("n", "[q", vim.cmd.cprev, { desc = "Prev quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

--- ---------------------------------------------------------------------------
--- Diagnostics
--- ---------------------------------------------------------------------------
--- ]d / [d walk everything; ]e / [e only errors; ]w / [w only warnings.

---@param count number 1 = forward, -1 = backward
---@param severity string|nil "ERROR" / "WARN" / nil for any
local function diagnostic_goto(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end

map("n", "]d", diagnostic_goto(1), { desc = "Next diagnostic" })
map("n", "[d", diagnostic_goto(-1), { desc = "Prev diagnostic" })
map("n", "]e", diagnostic_goto(1, "ERROR"), { desc = "Next error" })
map("n", "[e", diagnostic_goto(-1, "ERROR"), { desc = "Prev error" })
map("n", "]w", diagnostic_goto(1, "WARN"), { desc = "Next warning" })
map("n", "[w", diagnostic_goto(-1, "WARN"), { desc = "Prev warning" })

--- ---------------------------------------------------------------------------
--- Terminal mode
--- ---------------------------------------------------------------------------
--- Without these you're trapped in a terminal buffer and have to remember
--- <C-\><C-n>, which nobody does.
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Exit terminal mode" })
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Window left" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Window down" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Window up" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Window right" })
