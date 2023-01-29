return {
    "lukas-reineke/indent-blankline.nvim",

    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require("nvim-web-devicons").setup()
        end
    },

    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" }
    },

    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end
    },

    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup()
        end
    },

    {
        "VonHeikemen/lsp-zero.nvim",
        dependencies = { -- LSP Support
            { "neovim/nvim-lspconfig" }, { "williamboman/mason.nvim" }, { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" }, { "hrsh7th/cmp-buffer" }, { "hrsh7th/cmp-path" }, { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lsp" }, { "hrsh7th/cmp-nvim-lua" }, -- Snippets
            { "L3MON4D3/LuaSnip" }, { "rafamadriz/friendly-snippets" } }
    },
    "jose-elias-alvarez/null-ls.nvim",

    "tpope/vim-commentary",

    {
        "kylechui/nvim-surround",
        version = "*", -- for stability; omit to use `main` branch for the latest features,
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to defaults,
            })
        end
    },

    "gpanders/editorconfig.nvim",

    {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup()
        end
    }, -- Standalone UI for nvim-lsp progress. Eye candy for the impatient.

    "simrat39/rust-tools.nvim",
    "mfussenegger/nvim-dap", -- Debug Adapter Protocol client implementation for NeoVim.,
    "wellle/targets.vim", -- Adds various text objects to give you more targets to operate on.,
    "moll/vim-bbye", -- Bbye allows you to do delete buffers (close files) without closing your windows or messing up your layout.,

    {
        'phaazon/hop.nvim',
        branch = 'v2', -- optional but strongly recommended
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require 'hop'.setup {
                keys = 'etovxqpdygfblzhckisuran'
            }
        end
    }
}
