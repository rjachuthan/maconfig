--- ===========================================================================
--- ROOT
--- ===========================================================================
--- Project-root detection. Replaces `LazyVim.root`, which every picker's
--- "Root Dir" variant, grep, the terminal cwd and lazygit relied on.
---
--- Resolution order:
---   1. An attached LSP client's workspace folders / root_dir -- the server
---      already worked this out (often from a lockfile or manifest we don't
---      know to look for), so trust it first.
---   2. Upward search from the buffer for a marker file/directory.
---   3. Whatever `getcwd()` is, so callers always get SOMETHING back.
---
--- Uses `vim.fs.root()` / `vim.fs.find()` (0.10+) rather than hand-rolled
--- `fnamemodify` loops -- both already handle symlinks and stop at "/".
--- ===========================================================================

local M = {}

--- Clients whose root_dir is not a useful project root (formatters-as-LSP,
--- linters, etc. that either have no real root concept or report something
--- too broad/narrow to be useful for a picker or terminal cwd).
M.ignore_lsp = {
  "copilot",
  "null-ls",
  "none-ls",
}

--- Marker files/dirs to search for, upward from the buffer, when no LSP
--- client has an opinion. Ordered by nothing in particular -- `vim.fs.root`
--- treats the list as "any of these", not "first one wins".
M.markers = { ".git", "pyproject.toml", "setup.py", "package.json", "Makefile", ".venv", "lua" }

--- ---------------------------------------------------------------------------
--- Detection
--- ---------------------------------------------------------------------------

--- Root dir(s) reported by attached LSP clients for `buf`, minus anything in
--- `M.ignore_lsp`. A client may report several workspace folders; all are
--- returned so the caller can pick (root detection prefers the first).
---@param buf integer
---@return string[]
local function lsp_roots(buf)
  local roots = {}
  for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
    if not vim.tbl_contains(M.ignore_lsp, client.name) then
      for _, folder in ipairs(client.workspace_folders or {}) do
        table.insert(roots, vim.uri_to_fname(folder.uri))
      end
      if #client.workspace_folders == 0 and client.root_dir then
        table.insert(roots, client.root_dir)
      end
    end
  end
  return roots
end

--- Detect the project root for a buffer.
---@param opts { buf?: integer }|nil
---@return string
function M.detect(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  local bufnr = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local path = vim.api.nvim_buf_get_name(bufnr)

  -- Unnamed/scratch buffers have no path to search from -- cwd is the only
  -- sane answer.
  if path == "" then
    return vim.fn.getcwd()
  end

  -- 1. LSP-reported root, if any client is attached and willing to say.
  local roots = lsp_roots(bufnr)
  if roots[1] then
    return roots[1]
  end

  -- 2. Upward marker search from the buffer's directory.
  local found = vim.fs.root(path, M.markers)
  if found then
    return found
  end

  -- 3. cwd fallback -- always returns something.
  return vim.fn.getcwd()
end

--- ---------------------------------------------------------------------------
--- Cache
--- ---------------------------------------------------------------------------
--- Root detection walks the filesystem and (potentially) iterates LSP
--- clients; memoizing per-buffer keeps pickers/grep/lualine cheap on repeat
--- calls within the same buffer session. Invalidated below whenever the
--- answer could plausibly change.

---@param buf integer
---@return string
function M.get(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local cached = vim.b[buf].root_dir
  if cached then
    return cached
  end
  local root = M.detect({ buf = buf })
  vim.b[buf].root_dir = root
  return root
end

local augroup = vim.api.nvim_create_augroup("nvim_util_root", { clear = true })

--- New LSP attachment can change what `lsp_roots()` would return (a server
--- just told us where the project lives), and a save can create/remove a
--- marker file (e.g. `git init`, a fresh `package.json`) -- both invalidate
--- the memoized value for that buffer.
vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost" }, {
  group = augroup,
  callback = function(ev)
    vim.b[ev.buf].root_dir = nil
  end,
  desc = "Invalidate cached project root",
})

--- ---------------------------------------------------------------------------
--- Display
--- ---------------------------------------------------------------------------

--- Short root string for lualine/statusline: just the trailing directory
--- name, not the full path (which is often long and mostly noise there).
---@return string
function M.pretty()
  local root = M.get()
  return vim.fs.basename(root) or root
end

return M
