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
