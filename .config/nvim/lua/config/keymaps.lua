-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set
local default_opts = {
  noremap = true,
  silent = true,
}

-- Append the bottom line to the current line.
keymap("n", "J", "mzJ`z", default_opts)

-- Center search results.
keymap("n", "n", "nzzzv", default_opts)
keymap("n", "N", "Nzzzv", default_opts)

-- Center the half page scroll.
keymap("n", "<C-d>", "<C-d>zz", default_opts)
keymap("n", "<C-u>", "<C-u>zz", default_opts)

-- Replace the word under cursor.
keymap("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Press enter to create a new row.
keymap({ "n" }, "<CR>", "m`i<CR><Esc>")

-- greatest remap ever
keymap("x", "<leader>p", [["_dP]])

-- Copy buffer paths
keymap("n", "<leader>fy", function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  vim.fn.setreg('"', path)
  print("Copied to clipboard: " .. path)
end, { desc = "Copy relative buffer path" })

keymap("n", "<leader>fY", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.fn.setreg('"', path)
  print("Copied to clipboard: " .. path)
end, { desc = "Copy buffer path" })

-- ctrl+h/j/k/l: nvim splits, then the next tuios pane (tuios-navigator.lua).
-- Set here because LazyVim maps these keys after the plugin loads.
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  keymap("n", "<C-" .. key .. ">", function()
    require("tuios-nvim-navigator").navigate(direction)
  end, { silent = true, desc = "Navigate " .. direction .. " through TUIOS" })
end

-- Send the selection to Herdr Annotate (herdr-annotate plugin). It cannot read
-- a Neovim selection, so hand it over in a file: the plugin looks in
-- $XDG_RUNTIME_DIR (else the system temp dir), under herdr-annotate-<uid>, and
-- ignores a file older than 15 seconds.
keymap("x", "<leader>a", function()
  vim.cmd('normal! "zy')
  local base = vim.env.XDG_RUNTIME_DIR
  if not base or base == "" then
    base = vim.env.TMPDIR or vim.env.TMP or vim.env.TEMP
    if not base or base == "" then
      base = vim.fn.has("win32") == 1 and vim.env.USERPROFILE or "/tmp"
    end
  end
  local uid = "user"
  if vim.fn.has("unix") == 1 then
    uid = tostring((vim.uv or vim.loop).os_get_passwd().uid)
  end
  local dir = base .. "/herdr-annotate-" .. uid
  vim.fn.mkdir(dir, "p", "0700")
  vim.fn.writefile(vim.split(vim.fn.getreg("z"), "\n"), dir .. "/selection")
  vim.fn.jobstart({ "herdr", "plugin", "action", "invoke", "annotate.capture" })
end, { desc = "Annotate selection in Herdr" })
