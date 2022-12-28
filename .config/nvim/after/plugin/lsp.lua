local status_ok, lsp = pcall(require, "lsp-zero")
if not status_ok then
    return
end

lsp.preset("recommended")
lsp.ensure_installed({"tsserver", "eslint", "sumneko_lua", "rust_analyzer"})

lsp.configure("tsserver", {
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end
})

-- Fix Undefined global "vim"
lsp.configure("sumneko_lua", {
    settings = {
        Lua = {
            diagnostics = {
                globals = {"vim"}
            }
        }
    }
})

local rt = require('rust-tools')
local rust_lsp = lsp.build_options('rust_analyzer', {
    on_attach = function(_, bufnr)
        -- Hover actions
        vim.keymap.set("n", "<Leader>a", rt.hover_actions.hover_actions, {
            buffer = bufnr
        })

        -- Code action groups
        vim.keymap.set("n", "<Leader>A", rt.code_action_group.code_action_group, {
            buffer = bufnr
        })

        -- Move Item Up/Down
        vim.keymap.set("n", "<S-Up>", "<cmd>lua require'rust-tools'.move_item.move_item(true)<cr>")
        vim.keymap.set("n", "<S-Down>", "<cmd>lua require'rust-tools'.move_item.move_item(false)<cr>")
    end
})

lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = true
})

require("null-ls").setup({
    sources = {require("null-ls").builtins.formatting.prettier -- javascript formatting
    }
})

rt.setup({
    server = rust_lsp
})
