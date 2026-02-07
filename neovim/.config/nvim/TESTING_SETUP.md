# Testing & Debugging Setup

## Overview

Testing and debugging support has been added to your Neovim configuration through LazyVim extras.

## What Was Added

### LazyVim Extras (in `lua/config/lazy.lua`)

1. **test.core** - Neotest framework for running tests
2. **dap.core** - Debug Adapter Protocol for debugging

### Plugins Installed

**Testing:**
- nvim-neotest/neotest - Test runner framework
- nvim-neotest/neotest-python - Python adapter
- nvim-neotest/nvim-nio - Async operations

**Debugging:**
- mfussenegger/nvim-dap - Debug Adapter Protocol
- mfussenegger/nvim-dap-python - Python debugger
- rcarriga/nvim-dap-ui - Debugger UI
- theHamsta/nvim-dap-virtual-text - Inline debug info
- jay-babu/mason-nvim-dap.nvim - Debugger management

## Quick Verification

### 1. Restart Neovim

Close and reopen Neovim to load the new configuration:
```bash
nvim
```

### 2. Check Plugin Status

Run `:Lazy` to see all plugins. Look for:
- ✅ neotest
- ✅ neotest-python
- ✅ nvim-dap
- ✅ nvim-dap-python
- ✅ nvim-dap-ui

### 3. Check Mason Installations

Run `:Mason` and verify these are installed:
- ✅ debugpy (Python debugger)
- ✅ pyright (Python LSP)
- ✅ ruff (Python linter/formatter)

### 4. Test with the Python Project

```bash
cd ~/.local/share/python-test-project
nvim test_main.py
```

In Neovim:
1. Select virtual environment: `<leader>cv` → choose `.venv`
2. Run nearest test: `<leader>tr` (cursor on a test function)
3. View test summary: `<leader>ts`
4. Run all tests in file: `<leader>tt`

## Testing Keybindings

All test commands use the `<leader>t` prefix (usually `<Space>t`):

| Key | Action | Example |
|-----|--------|---------|
| `<leader>ta` | Attach to running test | Attach debugger to running test |
| `<leader>tt` | Run current file tests | Run all tests in `test_main.py` |
| `<leader>tT` | Run all test files | Run entire test suite |
| `<leader>tr` | Run nearest test | Run the test under cursor |
| `<leader>tl` | Run last test | Re-run the last test |
| `<leader>ts` | Toggle test summary | Show/hide test results panel |
| `<leader>to` | Display test output | Show test output window |
| `<leader>tS` | Stop test execution | Cancel running tests |
| `<leader>td` | Debug nearest test | Debug test under cursor |
| `<leader>tF` | Run folder tests | Run all tests in current folder |

## Debugging Keybindings

All debug commands use the `<leader>d` prefix:

### Breakpoints
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint |

### Execution Control
| Key | Action |
|-----|--------|
| `<leader>dc` | Continue/Start debugging |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into function |
| `<leader>dO` | Step over line |
| `<leader>do` | Step out of function |

### Python-Specific
| Key | Action |
|-----|--------|
| `<leader>dPt` | Debug test method |
| `<leader>dPc` | Debug test class |

### UI & Inspection
| Key | Action |
|-----|--------|
| `<leader>du` | Toggle debugger UI |
| `<leader>de` | Evaluate expression |
| `<leader>dr` | Open REPL |

## Test Discovery

Neotest automatically discovers tests based on:
- File patterns: `test_*.py` or `*_test.py`
- Function patterns: `test_*` functions
- Class patterns: `Test*` classes with `test_*` methods

## Test Output

When you run tests:
1. **Inline signs** appear next to test functions (✓ pass, ✗ fail)
2. **Virtual text** shows test status in the editor
3. **Output panel** opens automatically (toggle with `<leader>to`)
4. **Summary panel** shows all test results (toggle with `<leader>ts`)

## Debugging Workflow

### 1. Set Breakpoints

Place cursor on desired line and press `<leader>db`

### 2. Start Debugging

**Option A: Debug a test**
- Place cursor on test function
- Press `<leader>dPt` (debug method) or `<leader>dPc` (debug class)

**Option B: Debug entire file**
- Open the Python file
- Press `<leader>dc` to start debugging

### 3. Step Through Code

- `<leader>di` - Step into function calls
- `<leader>dO` - Step over current line
- `<leader>do` - Step out of current function
- `<leader>dc` - Continue to next breakpoint
- `<leader>dC` - Run to cursor position

### 4. Inspect Variables

- **Hover**: Move cursor over variable and press `K`
- **Evaluate**: Press `<leader>de` to evaluate expression
- **REPL**: Press `<leader>dr` to open debug REPL
- **UI**: Press `<leader>du` to toggle DAP UI with scopes, watches, etc.

### 5. Stop Debugging

- Press `<leader>dc` to continue until program ends
- Or use `:DapTerminate` to stop immediately

## Example: Debug a Failing Test

```bash
cd ~/.local/share/python-test-project
nvim test_main.py
```

1. Select venv: `<leader>cv`
2. Navigate to `test_add_numbers` function
3. Set breakpoint on assertion line: `<leader>db`
4. Debug the test: `<leader>dPt`
5. When paused at breakpoint:
   - Hover over variables to inspect
   - Press `<leader>de` to evaluate expressions
   - Press `<leader>du` to see all variables in scope
6. Step through: `<leader>dO` (step over)
7. Continue: `<leader>dc`

## Troubleshooting

### Tests not discovered

**Check:**
1. File is named `test_*.py` or `*_test.py`
2. Functions are named `test_*`
3. Virtual environment is selected: `:VenvSelect`
4. Pytest is installed: `pip list | grep pytest`

**Fix:**
```bash
source .venv/bin/activate
pip install pytest
```

### Neotest not loading

**Check:**
```vim
:Lazy
```
Look for neotest plugins. If missing:
```vim
:Lazy sync
```

### Debugger not starting

**Check:**
1. DAP is loaded: `:Lazy` → search for "dap"
2. Debugpy is installed: `:Mason` → search for "debugpy"
3. Virtual environment is selected

**Fix:**
```bash
source .venv/bin/activate
pip install debugpy
```

Then restart Neovim LSP: `:LspRestart`

### No test output shown

Press `<leader>to` to toggle output panel.

Configure in `lua/plugins/testing.lua`:
```lua
opts = {
  output = {
    open_on_run = true,  -- Auto-open output
  },
}
```

### Breakpoints not working

1. Ensure DAP is running: `:lua print(require('dap').status())`
2. Check debugpy path: `:lua print(vim.fn.stdpath('data')..'/mason/packages/debugpy')`
3. Verify virtual environment: `:lua print(vim.env.VIRTUAL_ENV)`

## Advanced Configuration

### Custom Test Arguments

Edit `lua/plugins/python.lua`:
```lua
require("neotest-python")({
  args = { "-vv", "--log-cli-level=INFO" },
})
```

### Test Patterns

Edit `pyproject.toml` in your project:
```toml
[tool.pytest.ini_options]
python_files = ["test_*.py", "*_test.py", "check_*.py"]
python_functions = ["test_*", "check_*"]
```

### Debug Configuration

Edit `lua/plugins/python.lua` to customize DAP:
```lua
local dap = require("dap")
dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    console = "integratedTerminal",
  },
}
```

## Resources

- [Neotest Documentation](https://github.com/nvim-neotest/neotest)
- [nvim-dap Documentation](https://github.com/mfussenegger/nvim-dap)
- [LazyVim Test Extras](https://www.lazyvim.org/extras/test/core)
- [LazyVim DAP Extras](https://www.lazyvim.org/extras/dap/core)
- [Python Testing Guide](PYTHON_SETUP.md)

## Quick Test

Run this command to verify everything works:

```bash
cd ~/.local/share/python-test-project
nvim -c "lua vim.defer_fn(function() require('neotest').run.run(vim.fn.expand('%')) end, 1000)" test_main.py
```

This should:
1. Open Neovim
2. Wait 1 second for plugins to load
3. Automatically run all tests in the file
4. Show test results

Press `<leader>ts` to see the test summary!
