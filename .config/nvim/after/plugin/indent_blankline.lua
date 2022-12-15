local status_ok, indent_blankline = pcall(require, "indent_blankline")
if not status_ok then
    return
end

indent_blankline.setup {
    space_char_blankline = " ",
    show_current_context = true,
    show_current_context_start = true,
    use_treesitter = true,
    use_treesitter_context = true,
    context_highlight_list = {'rainbowcol1', 'rainbowcol2', 'rainbowcol3', 'rainbowcol4', 'rainbowcol5', 'rainbowcol6',
                              'rainbowcol7'}
}
