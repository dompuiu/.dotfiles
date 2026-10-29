-- ctrl+h/j/k/l move through nvim splits, then into the next tuios pane.
-- Needs [appearance] nvim_navigation = true in .config/tuios/config.toml, and
-- the same keys in tuios terminal_focus_left/down/up/right.
--
-- The plugin writes its OSC 7777 messages with io.stdout:write(), which does
-- not reach the host terminal from nvim 0.12's TUI. Send them with
-- nvim_ui_send() instead.
local function send(command, value)
  local seq = "\27]7777;tuios-nvim-navigator;" .. command .. ";" .. value .. "\7"
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(seq)
  else
    io.stdout:write(seq)
    io.stdout:flush()
  end
end

return {
  {
    "Tim4c/tuios-nvim-navigator",
    config = function()
      require("tuios-nvim-navigator").setup({
        -- ctrl+h/j/k/l are mapped in config/keymaps.lua, after LazyVim's own.
        keymaps = { left = "", down = "", up = "", right = "" },
        on_boundary = function(direction)
          send("focus", direction)
        end,
      })

      local group = vim.api.nvim_create_augroup("TuiosNvimNavigatorUi", { clear = true })
      vim.api.nvim_create_autocmd({ "UIEnter", "VimResume", "FocusGained" }, {
        group = group,
        callback = function()
          send("state", "active")
        end,
      })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
          send("state", "inactive")
        end,
      })
      send("state", "active")
    end,
  },
}
