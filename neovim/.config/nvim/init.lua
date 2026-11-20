require("core.options")

local platform = require("core.platform")
platform.setup_shell()

require("core.keymaps")
require("core.autocmds")
require("core.herdr").setup()
require("util.format").setup()
require("core.lazy")

platform.check_health()
