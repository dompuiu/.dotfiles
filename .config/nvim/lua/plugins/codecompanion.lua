return {
  {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      adapters = {
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                default = "claude-3.7-sonnet",
              },
            },
          })
        end,
      },
      strategies = {
        -- Change the default chat adapter
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
      opts = {
        -- Set debug logging
        log_level = "DEBUG",
      },
    },
    keys = {
      {
        "<leader>az",
        "<cmd>CodeCompanionActions<cr>",
        desc = "Open Code Companion Actions Menu",
      },
      {
        "<leader>az",
        "<cmd>CodeCompanionActions<cr>",
        mode = "v",
        desc = "Open Code Companion Actions Menu",
      },
    },
  },
}
