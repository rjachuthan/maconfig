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
require("core.lazy")

--- Warn about missing external tools (compiler, ripgrep, git). Deferred, so
--- it never delays startup. See lua/core/platform.lua for install commands.
platform.check_health()
