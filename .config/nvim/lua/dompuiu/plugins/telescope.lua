return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        {
            "nvim-lua/plenary.nvim"
        },
        {
            "nvim-telescope/telescope-file-browser.nvim"
        },
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build"
        },
    },
    config = function()
        local telescope = require("telescope")

        telescope.setup {
            extensions = {
                file_browser = {
                    -- disables netrw and use telescope-file-browser in its place
                    hijack_netrw = true,
                },
            },
        }

        telescope.load_extension "file_browser"
    end
}
