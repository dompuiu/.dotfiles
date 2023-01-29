return {

    -- tokyonight
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "moon" },
    },

    {
        "sainnhe/sonokai",
        lazy = true,
        config = function()
            vim.g.sonokai_style = "shusia"
            vim.g.sonokai_better_performance = 1
        end
    }

}
