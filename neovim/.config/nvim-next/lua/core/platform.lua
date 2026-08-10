--- ===========================================================================
--- PLATFORM
--- ===========================================================================
--- Single place where "which OS am I on?" is answered. Every other file in
--- this config calls into here instead of writing its own `if has("win32")`.
---
--- Why this exists: the old config had platform branching scattered across
--- three files, with two hardcoded absolute paths (a macOS one and a Windows
--- one) baked into a plugin spec, and Obsidian support disabled entirely on
--- Windows. All of that is fixed by routing through this module.
---
--- ---------------------------------------------------------------------------
--- WINDOWS SETUP
--- ---------------------------------------------------------------------------
--- This repo is deployed on macOS with GNU Stow. Stow does not exist on
--- Windows, so link the config manually instead. In an ELEVATED PowerShell
--- (or any PowerShell with Developer Mode enabled in Settings):
---
---   New-Item -ItemType SymbolicLink `
---     -Path  "$env:LOCALAPPDATA\nvim" `
---     -Target "$HOME\Codes\mycodes\maconfig\neovim\.config\nvim"
---
--- Required tools. `brew install x` on macOS; on Windows use winget:
---
---   ripgrep      winget install BurntSushi.ripgrep.MSVC    (grep / picker)
---   fd           winget install sharkdp.fd                 (file finding)
---   lazygit      winget install JesseDuffield.lazygit      (<leader>gg)
---   git          winget install Git.Git                    (prefer this over
---                                                           the MSYS git shim
---                                                           -- diffview and
---                                                           lazygit both need
---                                                           a well-behaved git
---                                                           on PATH)
---   node         winget install OpenJS.NodeJS              (ts/js LSP, mdpreview)
---   python       winget install Python.Python.3.12
---
--- A C compiler is REQUIRED for nvim-treesitter (main branch compiles parsers
--- locally). Easiest to hardest:
---
---   1. Zig     winget install zig.zig        <- recommended, zero config
---   2. MSVC    Visual Studio Build Tools with "Desktop development with C++"
---   3. MinGW   winget install BrechtSanders.WinLibs.POSIX.UCRT
---
--- `M.check_health()` below warns at startup if none is found, so you get a
--- clear message instead of a wall of parser compile errors.
---
--- KNOWN GAPS ON WINDOWS (deliberate, not bugs):
---   * No inline images. image.nvim needs the Kitty graphics protocol, which
---     Windows Terminal does not implement. Markdown/notebooks still work,
---     images just don't render. See lua/plugins/lang/notebook.lua.
---   * No tmux navigation. vim-tmux-navigator is skipped; the plain <C-hjkl>
---     window maps in core/keymaps.lua still work everywhere.
--- ===========================================================================

local M = {}

--- ---------------------------------------------------------------------------
--- Detection
--- ---------------------------------------------------------------------------

M.is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
M.is_mac = vim.fn.has("mac") == 1
M.is_wsl = vim.fn.has("wsl") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_mac and not M.is_wsl

--- Path separator. Neovim accepts "/" on Windows almost everywhere, but a few
--- external tools (mason shims, debugpy) want the native one.
M.sep = M.is_win and "\\" or "/"

--- ---------------------------------------------------------------------------
--- Executables
--- ---------------------------------------------------------------------------

--- Is `bin` on PATH?
---@param bin string
---@return boolean
function M.has(bin)
  return vim.fn.executable(bin) == 1
end

--- Resolve an executable to its absolute path, trying the Windows wrapper
--- extensions too. Returns nil when not found -- callers should degrade
--- gracefully rather than crash.
---
--- This replaces the old claudecode.lua approach of hardcoding
--- "/Users/rituraj/.local/bin/claude" AND "C:/Users/achutrit/..." in one spec.
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

--- Path to the python interpreter inside a virtualenv.
--- Unix: <venv>/bin/python   Windows: <venv>\Scripts\python.exe
--- The old config inlined the Unix form in two separate places, so venv
--- detection silently failed on Windows for both neotest and dap.
---@param venv string Root of the virtualenv
---@return string
function M.python_bin(venv)
  if M.is_win then
    return venv .. "\\Scripts\\python.exe"
  end
  return venv .. "/bin/python"
end

--- Best-guess python interpreter for the current buffer: active venv first,
--- then a .venv/ in the project root, then whatever is on PATH.
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

--- ---------------------------------------------------------------------------
--- Shell
--- ---------------------------------------------------------------------------

--- Configure 'shell' and friends. Without the Windows branch, toggleterm and
--- plain `:!cmd` are both broken -- Neovim defaults to cmd.exe, which mangles
--- quoting for anything non-trivial.
function M.setup_shell()
  if not M.is_win then
    return -- the Unix default ($SHELL) is already correct
  end

  local pwsh = M.has("pwsh") and "pwsh" or (M.has("powershell") and "powershell" or nil)
  if not pwsh then
    return -- fall back to cmd.exe; better than pointing at a missing binary
  end

  vim.o.shell = pwsh
  vim.o.shellcmdflag = table.concat({
    "-NoLogo",
    "-NoProfile",
    "-ExecutionPolicy RemoteSigned",
    -- Force UTF-8 in and out, otherwise LSP/lint output arrives mojibaked.
    "-Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
  }, " ")
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

--- ---------------------------------------------------------------------------
--- Misc OS operations
--- ---------------------------------------------------------------------------

--- Open a URL or file in the OS default handler.
--- Neovim 0.10+ ships vim.ui.open which already does the right thing on every
--- platform, so prefer it and keep the manual branch only as a fallback for
--- the odd embedded environment.
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

--- Obsidian vault location. Set $OBSIDIAN_VAULT to override; otherwise guess
--- the conventional spot per OS. The old config gave up and disabled Obsidian
--- entirely on Windows -- this gets it working on both machines.
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

--- Filter a list of mason tool names down to the ones installable here.
--- A few tools have no Windows build, and asking mason for them produces a
--- noisy error on every startup.
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

--- ---------------------------------------------------------------------------
--- Startup diagnostics
--- ---------------------------------------------------------------------------

--- Warn once about missing prerequisites, with actionable install commands.
--- Deferred so it lands after the UI is up rather than during startup.
function M.check_health()
  vim.schedule(function()
    local missing = {}

    -- A C compiler is non-optional: treesitter compiles parsers on install.
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
