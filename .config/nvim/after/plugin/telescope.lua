local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
    return
end


telescope.setup {
    extensions = {
        file_browser = {
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
        },
    },
}

telescope.load_extension "file_browser"
