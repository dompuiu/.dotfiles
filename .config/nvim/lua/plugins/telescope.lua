return {
  {
    "molecule-man/telescope-menufacture",
    keys = {
      {
        "<leader>fm",
        desc = "Menufacture",
      },
      {
        "<leader>fmg",
        function()
          require("telescope").extensions.menufacture.live_grep()
        end,
        desc = "Live Grep",
      },
      {
        "<leader>fma",
        function()
          require("telescope").extensions.menufacture.find_files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fmw",
        function()
          require("telescope").extensions.menufacture.grep_string()
        end,
        desc = "Grep String",
      },
      {
        "<leader>fmf",
        function()
          require("telescope").extensions.menufacture.git_files()
        end,
        desc = "Git Files",
      },
    },
  },
}
