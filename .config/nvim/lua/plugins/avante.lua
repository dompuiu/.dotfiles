return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = true,
    version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
    opts = {
      provider = "copilot",
      web_search_engine = {
        provider = "brave",
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",

    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("avante").setup({
        provider = "copilot",
        providers = {
          copilot = {
            model = "claude-sonnet-4",
          },
        },
        web_search_engine = {
          provider = "brave",
        },

        -- other config
        -- The system_prompt type supports both a string and a function that returns a string. Using a function here allows dynamically updating the prompt with mcphub
        system_prompt = function()
          local hub = require("mcphub").get_hub_instance()

          if hub == nil then
            return nil, "Hub cannot be nil"
          end

          return hub:get_active_servers_prompt()
        end,

        -- The custom_tools type supports both a list and a function that returns a list. Using a function here prevents requiring mcphub before it's loaded
        custom_tools = function()
          return {
            require("mcphub.extensions.avante").mcp_tool(),
          }
        end,
      })
    end,
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-mini/mini.icons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
      {
        "nvim-neo-tree/neo-tree.nvim",
        opts = {
          filesystem = {
            commands = {
              avante_add_files = function(state)
                local node = state.tree:get_node()
                local filepath = node:get_id()
                local relative_path = require("avante.utils").relative_path(filepath)

                local sidebar = require("avante").get()

                local open = sidebar:is_open()
                -- ensure avante sidebar is open
                if not open then
                  require("avante.api").ask()
                  sidebar = require("avante").get()
                end

                sidebar.file_selector:add_selected_file(relative_path)

                -- remove neo tree buffer
                if not open then
                  sidebar.file_selector:remove_selected_file("neo-tree filesystem [1]")
                end
              end,
            },
          },
          window = {
            mappings = {
              ["oa"] = "avante_add_files",
            },
          },
        },
      },
    },
  },
}
