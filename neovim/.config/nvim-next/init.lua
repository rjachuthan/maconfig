--- ===========================================================================
--- Neovim configuration
--- ===========================================================================
--- Hand-built, no distro. Every plugin is here because it was chosen; nothing
--- is inherited from a framework.
---
--- WHERE THINGS LIVE
---   lua/core/platform.lua   OS detection; read this first if you're on Windows
---   lua/core/options.lua    every vim option, with a reason for each
---   lua/core/keymaps.lua    plugin-free keymaps
---   lua/core/autocmds.lua   automatic behaviours
---   lua/keymap-tree.lua     THE <leader> MAP -- the file to read to learn
---                           what this config can do
---   lua/plugins/            plugin specs, grouped by role
---   lua/util/               small helpers replacing what the distro provided
---
--- Press <leader> and wait: which-key lists everything available, always
--- accurate, because it is generated from lua/keymap-tree.lua.
---
--- Order below matters: options set the leader key, which plugin specs need
--- at load time; platform configures the shell before any terminal exists.
--- ===========================================================================

require("core.options")

local platform = require("core.platform")
platform.setup_shell()

require("core.keymaps")
require("core.autocmds")

--- Format-on-save and 'formatexpr'. Set up here, NOT from a plugin spec.
---
--- This is deliberately at startup rather than inside conform's config: it is
--- pure Lua with no plugin dependencies (it only installs a BufWritePre
--- autocmd and points 'formatexpr' at itself), and the actual formatter is
--- resolved lazily at format time. Hanging it off a plugin's config means
--- format-on-save silently does nothing until that plugin happens to load --
--- which is exactly the bug this replaced: LazyVim owned format-on-save via
--- its own hook, not conform's `format_on_save`, so dropping the distro
--- removed the feature with no error to explain it.
require("util.format").setup()

require("core.lazy")

--- Warn about missing external tools (compiler, ripgrep, git). Deferred, so
--- it never delays startup. See lua/core/platform.lua for install commands.
platform.check_health()
