local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local yankGroup = augroup('HighlightYank', {})

autocmd('TextYankPost', {
    group = yankGroup,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40
        })
    end
})

local ThePrimeagenGroup = augroup('ThePrimeagen', {})
autocmd({"BufWritePre"}, {
    group = ThePrimeagenGroup,
    pattern = "*",
    command = "%s/\\s\\+$//e"
})

-- Start Netrw when editor is launched
local initNetrwGroup = augroup("InitNetrw", {
    clear = true
})
autocmd("VimEnter", {
    pattern = "*",
    command = [[if expand("%") == "" | silent! Explore | endif]],
    group = initNetrwGroup
})
