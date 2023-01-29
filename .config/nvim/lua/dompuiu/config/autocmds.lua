local autocmd = vim.api.nvim_create_autocmd

autocmd('TextYankPost', {
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40
        })
    end
})

autocmd({ "BufWritePre" }, {
    pattern = "*",
    callback = function()
        if vim.fn.exists(":LspZeroFormat") > 0 then
            vim.cmd("LspZeroFormat")
        end
    end,
})

autocmd({ "BufWritePre" }, {
    pattern = "*",
    command = "%s/\\s\\+$//e"
})
