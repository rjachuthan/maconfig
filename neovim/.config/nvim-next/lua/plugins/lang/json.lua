local platform = require("core.platform")

return {
  {
    "cenk1cenk2/jq.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "grapp-dev/nui-components.nvim",
    },
    cond = function()
      return platform.has("jq") or platform.has("yq")
    end,
    keys = {
      {
        "<leader>jj",
        function()
          require("jq").run()
        end,
        desc = "Run on buffer",
      },
      {
        "<leader>jj",
        ":<C-u>lua require('jq').run_visual()<cr>",
        desc = "Run on selection",
        mode = "x",
        silent = true,
      },
      {
        "<leader>jc",
        function()
          require("jq").run({ clipboard = true })
        end,
        desc = "Run on clipboard",
      },
    },
    opts = function()
      local commands = {
        { command = "jq", filetype = "json" },
        { command = "yq", filetype = "yaml" },
      }
      if platform.has("gojq") then
        table.insert(commands, { command = "gojq", filetype = "json" })
      end

      return {
        commands = commands,
        ui = {
          border = "rounded",
          autoclose = true,
        },
      }
    end,
    config = function(_, opts)
      require("jq").setup(opts)
    end,
  },
}
