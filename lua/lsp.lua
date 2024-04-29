require("mason-lspconfig").setup {
    ensure_installed = {
        "clangd",
        "lua_ls",
        --"tsserver",
        "asm_lsp",
        --"pylsp",
        "rust_analyzer",
        "typos_lsp",
        --"bashls",
        --"cmake",
        "kotlin_language_server",
        "vls",
        "zls",
        "gopls",
    },
}

local lspconfig = require('lspconfig')


require('lspconfig.configs').sq = {
  default_config = {
    cmd = {"C:/Users/Alexander.Nutz/sequencia-real/sqlsp/sqlsp.exe"},
    filetypes = {"sq"},
    settings = {},
    single_file_support = true,
  };
}
lspconfig.sq.setup {}
vim.cmd([[autocmd BufRead,BufNewFile *.sq setfiletype sq]])

lspconfig.clangd.setup {}
lspconfig.lua_ls.setup {}
lspconfig.tsserver.setup {}
lspconfig.asm_lsp.setup {}
--lspconfig.pylsp.setup {}
lspconfig.rust_analyzer.setup {}
lspconfig.typos_lsp.setup {}
--lspconfig.bashls.setup {}
--lspconfig.cmake.setup {}
lspconfig.kotlin_language_server.setup {}
lspconfig.vls.setup {}
lspconfig.zls.setup {}
lspconfig.gopls.setup {}
lspconfig.gleam.setup {}

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
