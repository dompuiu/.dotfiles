return {
  -- Replaced by live-preview.nvim (pure Lua, no node build step).
  { "iamcco/markdown-preview.nvim", enabled = false },
  {
    "brianhuster/live-preview.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = "LivePreview",
    keys = {
      {
        "<leader>cp",
        function()
          if vim.g.live_preview_running then
            vim.cmd("LivePreview close")
            vim.g.live_preview_running = false
          else
            vim.cmd("LivePreview start")
            vim.g.live_preview_running = true
          end
        end,
        ft = "markdown",
        desc = "Markdown Preview",
      },
    },
  },
}
