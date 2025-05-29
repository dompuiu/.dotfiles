return {
  {
    "gitsigns.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      {
        "<leader>gb",
        "<cmd>Gitsigns toggle_current_line_blame<cr>",
        desc = "Git Toggle Current Line Blame",
      },
    },
  },
}
