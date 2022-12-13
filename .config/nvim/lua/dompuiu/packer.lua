-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use("nvim-lua/plenary.nvim")
    use("nvim-lua/popup.nvim")
    use("nvim-telescope/telescope.nvim")
    use("nvim-treesitter/nvim-treesitter", {
        run = ":TSUpdate"
    })
    use('nvim-telescope/telescope-fzf-native.nvim', {
        run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    })

    use "sainnhe/sonokai"

    use "lukas-reineke/indent-blankline.nvim"

    use "maxmellon/vim-jsx-pretty" -- To highlight JSX
    use "yuezk/vim-js" -- To highlight JS
    use "HerringtonDarkholme/yats.vim" -- To highlight TypeScript
end)
