local keymap = vim.keymap.set
local default_opts = {
    noremap = true,
    silent = true
}

-- Cancel search highlighting with ESC
keymap("n", "<ESC>", ":nohlsearch<Bar>:echo<CR>", default_opts)

-- Move selected lines
keymap("v", "<S-Down>", ":m '>+1<cr>gv=gv", default_opts)
keymap("v", "<S-Up>", ":m '<-2<cr>gv=gv", default_opts)

-- Move current lines
keymap("n", "<S-Down>", ":m .+1<cr>==", default_opts)
keymap("n", "<S-Up>", ":m .-2<cr>==", default_opts)

-- Append the bottom line to the current line
keymap("n", "J", "mzJ`z", default_opts)

-- Center search results
keymap("n", "n", "nzzzv", default_opts)
keymap("n", "N", "Nzzzv", default_opts)

-- Center the half page scroll
keymap("n", "<C-d>", "<C-d>zz", default_opts)
keymap("n", "<C-u>", "<C-u>zz", default_opts)

-- Replace the word under cursor
keymap("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- greatest remap ever
keymap("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

keymap({ "n", "v" }, "<leader>d", [["_d]])
