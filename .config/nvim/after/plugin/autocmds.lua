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

local fmtGroup = augroup('FormatOnSave', {})
autocmd({ "BufWritePre" }, {
    pattern = "*",
    callback = function()
        if vim.fn.exists(":LspZeroFormat") > 0 then
            vim.cmd("LspZeroFormat")
        end
    end,
    group = fmtGroup
})

local ThePrimeagenGroup = augroup('ThePrimeagen', {})
autocmd({ "BufWritePre" }, {
    group = ThePrimeagenGroup,
    pattern = "*",
    command = "%s/\\s\\+$//e"
})
