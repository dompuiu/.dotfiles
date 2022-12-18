local keymap = vim.keymap.set
local default_opts = {
    noremap = true,
    silent = true
}
local expr_opts = {
    noremap = true,
    expr = true,
    silent = true
}

-- Cancel search highlighting with ESC
keymap("n", "<ESC>", ":nohlsearch<Bar>:echo<CR>", default_opts)

-- Center search results
keymap("n", "n", "nzzzv", default_opts)
keymap("n", "N", "Nzzzv", default_opts)
keymap("n", "<C-d>", "<C-d>zz", default_opts)
keymap("n", "<C-u>", "<C-u>zz", default_opts)
