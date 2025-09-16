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

-- Move Lines
keymap("n", "<C-A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap("n", "<C-A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap("i", "<C-A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
keymap("i", "<C-A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
keymap("v", "<C-A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap("v", "<C-A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
