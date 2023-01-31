return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources, {
        nls.builtins.formatting.prettier,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "simrat39/rust-tools.nvim" },
    ---@class PluginLspOpts
    opts = {
      setup = {
        tsserver = function(_, opts)
          opts["on_attach"] = function(client, _)
            -- JS formatting will be done by Prettier via null-ls.
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      },
    },
  },
}
