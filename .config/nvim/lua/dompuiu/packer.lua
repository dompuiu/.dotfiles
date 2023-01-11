-- This file can be loaded by calling `lua require("plugins")` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require("packer").startup(function(use)
    -- Packer can manage itself
    use "wbthomason/packer.nvim"

    use {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate"
    }

    use "nvim-treesitter/nvim-treesitter-textobjects"

    use {
        "nvim-telescope/telescope.nvim",
        requires = { { "nvim-lua/plenary.nvim" } }
    }

    use("nvim-telescope/telescope-fzf-native.nvim", {
        run = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build"
    })

    use "sainnhe/sonokai" -- Color Theme
    use "folke/tokyonight.nvim" -- Color Theme

    use "folke/which-key.nvim"

    use "lukas-reineke/indent-blankline.nvim"

    use {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require("nvim-web-devicons").setup()
        end
    }

    use {
        "nvim-lualine/lualine.nvim",
        requires = { "nvim-tree/nvim-web-devicons" }
    }

    use {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end
    }

    use {
        "akinsho/toggleterm.nvim",
        tag = "*",
        config = function()
            require("toggleterm").setup()
        end
    }

    use {
        "VonHeikemen/lsp-zero.nvim",
        requires = { -- LSP Support
            { "neovim/nvim-lspconfig" }, { "williamboman/mason.nvim" }, { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" }, { "hrsh7th/cmp-buffer" }, { "hrsh7th/cmp-path" }, { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lsp" }, { "hrsh7th/cmp-nvim-lua" }, -- Snippets
            { "L3MON4D3/LuaSnip" }, { "rafamadriz/friendly-snippets" } }
    }
    use "jose-elias-alvarez/null-ls.nvim"

    use "tpope/vim-commentary"

    use({
        "kylechui/nvim-surround",
        tag = "*", -- Use for stability; omit to use `main` branch for the latest features
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    })

    use "gpanders/editorconfig.nvim"

    use {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup()
        end
    } -- Standalone UI for nvim-lsp progress. Eye candy for the impatient.

    use "simrat39/rust-tools.nvim"
    use "mfussenegger/nvim-dap" -- Debug Adapter Protocol client implementation for NeoVim.
    use "wellle/targets.vim" -- Adds various text objects to give you more targets to operate on.
    use "moll/vim-bbye" -- Bbye allows you to do delete buffers (close files) without closing your windows or messing up your layout.

    use {
        'phaazon/hop.nvim',
        branch = 'v2', -- optional but strongly recommended
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require 'hop'.setup {
                keys = 'etovxqpdygfblzhckisuran'
            }
        end
    }
end)
