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
keymap("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Press enter to create a new row.
keymap({ "n" }, "<CR>", "m`i<CR><Esc>")

-- greatest remap ever
keymap("x", "<leader>p", [["_dP]])
