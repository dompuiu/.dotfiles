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

-- Start Netrw when editor is launched
local initNetrwGroup = augroup("InitNetrw", {
    clear = true
})
autocmd("VimEnter", {
    pattern = "*",
    command = [[if expand("%") == "" | silent! Explore | endif]],
    group = initNetrwGroup
})

local fmtGroup = augroup('FormatOnSave', {})
autocmd({ "BufWritePre" }, {
    pattern = "*",
    command = "LspZeroFormat",
    group = fmtGroup
})
