require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = {"javascript", "lua", "vim"},

    highlight = {
        enable = true,
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false
    }
}

require("indent_blankline").setup {
    space_char_blankline = " ",
    show_current_context = true,
    show_current_context_start = true,
    use_treesitter = true,
    use_treesitter_context = true,
    context_highlight_list = {'rainbowcol1', 'rainbowcol2', 'rainbowcol3', 'rainbowcol4', 'rainbowcol5', 'rainbowcol6',
                              'rainbowcol7'}
}
