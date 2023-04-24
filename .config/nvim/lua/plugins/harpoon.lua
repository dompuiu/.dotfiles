return {
  {
    "nvim-lua/plenary.nvim",
  },
  -- add symbols-outline
  {
    "ThePrimeagen/harpoon",
    keys = {
      { "<leader>hh", ':lua require("harpoon.ui").toggle_quick_menu()<cr>', desc = "Open Harpoon Quick Menu" },
      { "<leader>ha", ':lua require("harpoon.mark").add_file()<cr>', desc = "Add Mark to Harpoon" },
      { "<leader>hj", ':lua require("harpoon.ui").nav_prev()<cr>', desc = "Go to next file" },
      { "<leader>hk", ':lua require("harpoon.ui").nav_next()<cr>', desc = "Go to previous file" },
      { "<leader>h1", ':lua require("harpoon.ui").nav_file(1)<cr>', desc = "Go to file 1" },
      { "<leader>h2", ':lua require("harpoon.ui").nav_file(2)<cr>', desc = "Go to file 2" },
      { "<leader>h3", ':lua require("harpoon.ui").nav_file(3)<cr>', desc = "Go to file 3" },
      { "<leader>h4", ':lua require("harpoon.ui").nav_file(4)<cr>', desc = "Go to file 4" },
    },
  },
}
