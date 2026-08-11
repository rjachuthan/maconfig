local M = {}

M.is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
M.is_mac = vim.fn.has("mac") == 1
M.is_wsl = vim.fn.has("wsl") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_mac and not M.is_wsl

M.sep = M.is_win and "\\" or "/"

---@param bin string
---@return boolean
function M.has(bin)
  return vim.fn.executable(bin) == 1
end

---@param name string
---@return string|nil
function M.exe(name)
  local candidates = M.is_win and { name, name .. ".cmd", name .. ".exe", name .. ".bat" } or { name }
  for _, c in ipairs(candidates) do
    local path = vim.fn.exepath(c)
    if path ~= "" then
      return path
    end
  end
  return nil
end

---@param venv string Root of the virtualenv
---@return string
function M.python_bin(venv)
  if M.is_win then
    return venv .. "\\Scripts\\python.exe"
  end
  return venv .. "/bin/python"
end

---@param root string|nil Project root to look for .venv in
---@return string
function M.python(root)
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if venv and venv ~= "" then
    return M.python_bin(venv)
  end
  if root then
    local local_venv = root .. "/.venv"
    if vim.fn.isdirectory(local_venv) == 1 then
      return M.python_bin(local_venv)
    end
  end
  return M.exe("python3") or M.exe("python") or "python"
end

function M.setup_shell()
  if not M.is_win then
    return
  end

  local pwsh = M.has("pwsh") and "pwsh" or (M.has("powershell") and "powershell" or nil)
  if not pwsh then
    return
  end

  vim.o.shell = pwsh
  vim.o.shellcmdflag = table.concat({
    "-NoLogo",
    "-NoProfile",
    "-ExecutionPolicy RemoteSigned",
    "-Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
  }, " ")
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

---@param target string
function M.open_url(target)
  if vim.ui.open then
    vim.ui.open(target)
    return
  end
  local cmd = M.is_win and { "cmd.exe", "/c", "start", "", target }
    or M.is_mac and { "open", target }
    or { "xdg-open", target }
  vim.fn.jobstart(cmd, { detach = true })
end

---@return string|nil path, nil when no vault exists on this machine
function M.obsidian_vault()
  local candidates = {}
  if vim.env.OBSIDIAN_VAULT and vim.env.OBSIDIAN_VAULT ~= "" then
    table.insert(candidates, vim.env.OBSIDIAN_VAULT)
  end
  local home = vim.fn.expand("~")
  if M.is_win then
    table.insert(candidates, home .. "/Documents/Obsidian")
    table.insert(candidates, (vim.env.USERPROFILE or home) .. "/OneDrive/Documents/Obsidian")
  else
    table.insert(candidates, home .. "/Documents/Obsidian")
    table.insert(candidates, home .. "/Obsidian")
  end
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(vim.fn.expand(path)) == 1 then
      return vim.fn.expand(path)
    end
  end
  return nil
end

---@param tools string[]
---@return string[]
function M.mason_tools(tools)
  if not M.is_win then
    return tools
  end
  local unavailable = { shfmt = true, shellcheck = true }
  return vim.tbl_filter(function(t)
    return not unavailable[t]
  end, tools)
end

function M.check_health()
  vim.schedule(function()
    local missing = {}

    local compilers = { "zig", "cc", "gcc", "clang", "cl" }
    local have_compiler = false
    for _, c in ipairs(compilers) do
      if M.has(c) then
        have_compiler = true
        break
      end
    end
    if not have_compiler then
      table.insert(
        missing,
        M.is_win and "C compiler (treesitter): winget install zig.zig"
          or "C compiler (treesitter): xcode-select --install"
      )
    end

    for bin, hint in pairs({
      rg = M.is_win and "winget install BurntSushi.ripgrep.MSVC" or "brew install ripgrep",
      fd = M.is_win and "winget install sharkdp.fd" or "brew install fd",
      git = M.is_win and "winget install Git.Git" or "brew install git",
    }) do
      if not M.has(bin) then
        table.insert(missing, bin .. ": " .. hint)
      end
    end

    if #missing > 0 then
      vim.notify("Missing tools:\n  " .. table.concat(missing, "\n  "), vim.log.levels.WARN, { title = "platform" })
    end
  end)
end

return M
