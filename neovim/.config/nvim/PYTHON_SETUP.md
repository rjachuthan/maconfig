### Plugins

- **nvim-lspconfig**: LSP configuration (Pyright/BasedPyright + Ruff)
- **nvim-treesitter**: Syntax highlighting for Python, TOML, RST
- **venv-selector.nvim**: Virtual environment management
- **neotest-python**: Test runner integration (pytest/unittest)
- **nvim-dap-python**: Debugger support
- **conform.nvim**: Formatting with Ruff
- **nvim-lint**: Linting with Ruff and Mypy

## Configuration

### LSP Server Selection

In `lua/config/options.lua`, you can choose your LSP server:

```lua
vim.g.lazyvim_python_lsp = "pyright"      -- Default
-- vim.g.lazyvim_python_lsp = "basedpyright"  -- Alternative
```

### Type Checking Mode

Edit `lua/plugins/python.lua` to change type checking strictness:

```lua
typeCheckingMode = "basic"  -- Options: "off", "basic", "strict"
```

## Quick Start

### 1. Test the Setup

A test project has been created at `~/.local/share/python-test-project/`

Open it in Neovim:

```bash
cd ~/.local/share/python-test-project
nvim main.py
```

### 2. Select Virtual Environment

When you open a Python file, select the virtual environment:

- Press `<leader>cv` (usually `<Space>cv`)
- Or run `:VenvSelect`
- Select `.venv` from the list

You should see a notification: "Activated venv: .venv"

### 3. Verify LSP is Working

In `main.py`:

- Hover over a function (press `K`) to see documentation
- Go to definition (press `gd`) on a function call
- See type hints and autocomplete as you type

### 4. Run Tests

Open `test_main.py` and:

**Using Neotest:**

- `<leader>tr` - Run nearest test
- `<leader>tt` - Run current file tests
- `<leader>tT` - Run all test files
- `<leader>ts` - Toggle test summary
- `<leader>to` - Display test output
- `<leader>td` - Debug nearest test

**Using terminal:**

```bash
cd ~/.local/share/python-test-project
source .venv/bin/activate
pytest test_main.py -v
```

### 5. Format Code

- Save file to auto-format (if enabled)
- Or run `:Format`
- Uses Ruff for formatting and import organization

### 6. Organize Imports

Press `<leader>co` to organize imports using Ruff

## Keybindings

### Virtual Environment

| Key          | Action                     |
| ------------ | -------------------------- |
| `<leader>cv` | Select virtual environment |

### Testing (Neotest)

| Key          | Action                  |
| ------------ | ----------------------- |
| `<leader>ta` | Attach to running test  |
| `<leader>tt` | Run current file tests  |
| `<leader>tT` | Run all test files      |
| `<leader>tr` | Run nearest test        |
| `<leader>tl` | Run last test           |
| `<leader>ts` | Toggle test summary     |
| `<leader>to` | Display test output     |
| `<leader>tS` | Stop test execution     |
| `<leader>td` | Debug nearest test      |

### Debugging

| Key           | Action                  |
| ------------- | ----------------------- |
| `<leader>dPt` | Debug test method       |
| `<leader>dPc` | Debug test class        |
| `<leader>db`  | Toggle breakpoint       |
| `<leader>dB`  | Conditional breakpoint  |
| `<leader>dc`  | Continue/Run            |
| `<leader>dC`  | Run to cursor           |
| `<leader>di`  | Step into               |
| `<leader>dO`  | Step over               |
| `<leader>do`  | Step out                |
| `<leader>dr`  | Open REPL               |
| `<leader>du`  | Toggle debugger UI      |
| `<leader>de`  | Evaluate expression     |

### LSP

| Key          | Action               |
| ------------ | -------------------- |
| `gd`         | Go to definition     |
| `gr`         | Find references      |
| `gI`         | Go to implementation |
| `K`          | Hover documentation  |
| `<leader>ca` | Code actions         |
| `<leader>co` | Organize imports     |
| `<leader>cr` | Rename symbol        |
| `<leader>cf` | Format document      |

### Navigation (Treesitter)

| Key  | Action                  |
| ---- | ----------------------- |
| `]f` | Next function start     |
| `]c` | Next class start        |
| `[f` | Previous function start |
| `[c` | Previous class start    |

## Virtual Environment Management

### Auto-detection

venv-selector automatically searches for virtual environments in:

- `.venv/` in workspace
- `venv/` in home directory
- Poetry cache (`~/Library/Caches/pypoetry/virtualenvs/`)
- Anaconda installations

### Manual Selection

1. Run `:VenvSelect`
2. Choose from detected environments
3. Or enter custom path

### Creating a Virtual Environment

For a new project:

```bash
# Using venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Using poetry
poetry init
poetry install

# Using conda
conda create -n myproject python=3.11
conda activate myproject
```

Then in Neovim, select the environment with `<leader>cv`

## Testing

### Pytest Setup

Create `test_*.py` files with test functions:

```python
def test_something():
    assert True

class TestClass:
    def test_method(self):
        assert 1 + 1 == 2
```

### Run Tests

- **In Neovim**: Use neotest keybindings (`<leader>tt`, etc.)
- **In terminal**: `pytest` or `pytest -v`

### Test Configuration

Edit `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["."]
python_files = ["test_*.py"]
addopts = "-v --tb=short"
```

## Debugging

### Set Breakpoints

1. Place cursor on line
2. Press `<leader>db` to toggle breakpoint
3. Press `<leader>dPt` to debug test method
4. Use debug controls to step through code

### Debug Configuration

The debugger automatically uses:

- Virtual environment's debugpy if available
- Otherwise uses Mason's debugpy installation

## Code Quality

### Linting

Automatic linting with Ruff and Mypy:

- Errors show inline as you type
- View all diagnostics: `<leader>cd`

### Formatting

Auto-format on save with Ruff:

- Formats code
- Organizes imports
- Removes unused imports

Configure in `lua/plugins/python.lua`

### Type Checking

Pyright provides type checking:

- Shows type errors inline
- Hover to see inferred types
- Works best with type hints

## Project Structure Example

```
my-python-project/
├── .venv/                  # Virtual environment
├── src/
│   └── mypackage/
│       ├── __init__.py
│       └── module.py
├── tests/
│   └── test_module.py
├── pyproject.toml          # Project configuration
├── requirements.txt        # Dependencies
└── README.md
```

## Common Workflows

### New Project Setup

1. Create project directory
2. Create virtual environment: `python3 -m venv .venv`
3. Activate: `source .venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Open in Neovim: `nvim .`
6. Select venv: `<leader>cv`
7. Start coding!

### Working with Existing Project

1. Clone repository
2. Create/activate virtual environment
3. Install dependencies
4. Open in Neovim
5. Select virtual environment: `<leader>cv`
6. LSP will activate automatically

### Writing Tests

1. Create `test_*.py` file
2. Write test functions
3. Run with `<leader>tt`
4. Debug failing tests with `<leader>dPt`

## Troubleshooting

### LSP not working

1. Check Mason installations: `:Mason`
2. Verify Pyright and Ruff are installed
3. Select virtual environment: `:VenvSelect`
4. Restart LSP: `:LspRestart`

### Type errors not showing

1. Ensure LSP is running: `:LspInfo`
2. Check type checking mode in `lua/plugins/python.lua`
3. Add type hints to your code

### Tests not discovered

1. Ensure pytest is installed in virtual environment
2. Check test file naming: `test_*.py` or `*_test.py`
3. Verify neotest is loaded: `:Lazy`

### Virtual environment not detected

1. Run `:VenvSelect` manually
2. Check that `.venv/` or `venv/` exists
3. Ensure it contains `bin/python` (not just `python.exe`)

### Import errors

1. Ensure dependencies are installed in active venv
2. Check that LSP is using correct Python: `:LspInfo`
3. Verify PYTHONPATH if using custom structure

## Resources

- [LazyVim Python Extras](https://www.lazyvim.org/extras/lang/python)
- [Pyright Documentation](https://github.com/microsoft/pyright)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [Neotest Documentation](https://github.com/nvim-neotest/neotest)
- [nvim-dap Documentation](https://github.com/mfussenegger/nvim-dap)

## Test Project

A complete test project is available at:

```
~/.local/share/python-test-project/
```

Files:

- `main.py` - Example Python code with type hints
- `test_main.py` - Example pytest tests
- `pyproject.toml` - Project configuration
- `.venv/` - Virtual environment with pytest and requests

Open it to test all features:

```bash
cd ~/.local/share/python-test-project
nvim main.py
```
