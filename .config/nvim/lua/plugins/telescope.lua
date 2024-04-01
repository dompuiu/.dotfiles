return {
  -- add telescope-fzf-native
  {
    "telescope.nvim",
    keys = {
      {
        "<leader>fa",
        "<cmd>Telescope find_files find_command=fd,-I<cr>",
        desc = "Find in all files (ignore .gitignore)",
      },
    },
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
    },
  },
}
