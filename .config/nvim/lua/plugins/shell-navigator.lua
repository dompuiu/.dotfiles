return {
  {
    "mrjones2014/smart-splits.nvim",
    priority = 1000, -- High
    keys = {
      -- recommended mappings
      -- resizing splits
      -- these keymaps will also accept a range,
      -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize split left",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize split down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize split up",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize split right",
      },
      -- moving between splits
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to below split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to above split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },
      {
        "<C-\\>",
        function()
          require("smart-splits").move_cursor_previous()
        end,
        desc = "Move to previous split",
      },
      -- swapping buffers between windows
      {
        "<leader>zh",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "Swap with left buffer",
      },
      {
        "<leader>zj",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "Swap with below buffer",
      },
      {
        "<leader>zk",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "Swap with above buffer",
      },
      {
        "<leader>zl",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "Swap with right buffer",
      },
    },

    config = function()
      require("smart-splits").setup()
    end,
  },
}
