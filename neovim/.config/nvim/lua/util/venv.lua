local M = {}

--- Directory names that say nothing about which project the venv belongs to,
--- so the parent directory is shown instead.
local generic = {
  [".venv"] = true,
  ["venv"] = true,
  ["env"] = true,
  [".env"] = true,
}

---@param path string
---@return string
local function pretty(path)
  path = path:gsub("[/\\]+$", "")
  local name = vim.fs.basename(path)
  if generic[name] then
    local parent = vim.fs.basename(vim.fs.dirname(path))
    if parent and parent ~= "" then
      return parent
    end
  end
  return name
end

--- Root of the active virtualenv, preferring venv-selector's choice over the
--- environment it inherited at startup.
---@return string|nil
local function active()
  local ok, venv_selector = pcall(require, "venv-selector")
  if ok then
    local selected_ok, selected = pcall(venv_selector.venv)
    if selected_ok and selected and selected ~= "" then
      return selected
    end
  end
  local env = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if env and env ~= "" then
    return env
  end
  return nil
end

--- Name of the active virtualenv, empty when none is selected.
---@return string
function M.name()
  local path = active()
  return path and pretty(path) or ""
end

--- `true` when the current buffer is Python and a virtualenv is active.
---@return boolean
function M.enabled()
  return vim.bo.filetype == "python" and M.name() ~= ""
end

return M
