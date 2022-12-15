-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }

    use("nvim-lua/plenary.nvim")
    use("nvim-telescope/telescope.nvim")

    use('nvim-telescope/telescope-fzf-native.nvim', {
        run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    })

    use "sainnhe/sonokai"
    use "folke/tokyonight.nvim"

    use "tpope/vim-surround"

    use "lukas-reineke/indent-blankline.nvim"

    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'kyazdani42/nvim-web-devicons',
            opt = true
        }
    }
end)
