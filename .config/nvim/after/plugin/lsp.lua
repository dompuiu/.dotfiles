local status_ok, lsp = pcall(require, "lsp-zero")
if not status_ok then
    return
end

lsp.preset("recommended")
lsp.ensure_installed({"tsserver", "eslint", "sumneko_lua", "rust_analyzer"})

lsp.configure('tsserver', {
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end
})

lsp.setup()

require("null-ls").setup({
    sources = {require("null-ls").builtins.formatting.prettier -- javascript formatting
    }
})
