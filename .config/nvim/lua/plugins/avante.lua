return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "copilot",
      providers = {
        copilot = {
          model = "claude-sonnet-4.5",
        },
      },
      selector = {
        provider = "fzf_lua",
      },
      selection = {
        hint_display = "none",
      },
      behaviour = {
        auto_set_keymaps = false,
      },
      web_search_engine = {
        provider = "brave",
      },
    },
  },
}
