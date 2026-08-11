local M = {}

M.ignore_lsp = {
  "copilot",
  "null-ls",
  "none-ls",
}

M.markers = { ".git", "pyproject.toml", "setup.py", "package.json", "Makefile", ".venv", "lua" }

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

---@param opts { buf?: integer }|nil
---@return string
function M.detect(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  local bufnr = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == "" then
    return vim.fn.getcwd()
  end

  local roots = lsp_roots(bufnr)
  if roots[1] then
    return roots[1]
  end

  local found = vim.fs.root(path, M.markers)
  if found then
    return found
  end

  return vim.fn.getcwd()
end

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

vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost" }, {
  group = augroup,
  callback = function(ev)
    vim.b[ev.buf].root_dir = nil
  end,
  desc = "Invalidate cached project root",
})

---@return string
function M.pretty()
  local root = M.get()
  return vim.fs.basename(root) or root
end

return M
