local lspconfig = require("lspconfig")

lspconfig.clangd.setup {}
lspconfig.lua_ls.setup {}
lspconfig.rust_analyzer.setup {}
lspconfig.kotlin_language_server.setup {}
lspconfig.vls.setup {}
lspconfig.zls.setup {}
lspconfig.gleam.setup {}
lspconfig.jdtls.setup {}
lspconfig.texlab.setup {}
lspconfig.csharp_ls.setup {}

require('lspconfig.configs').roc = {
    default_config = {
        cmd = { "roc_language_server" },
        filetypes = { 'roc' },
        root_dir = lspconfig.util.root_pattern("*.roc"),
        single_file_support = true,
        settings = {},
    },
}
vim.cmd([[autocmd BufRead,BufNewFile *.roc setfiletype roc]])
lspconfig.roc.setup {}

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']', vim.diagnostic.goto_next)

-- list: []{title, search, action}
local function code_actions_menu(items)
    local pickers = require("telescope.pickers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local finders = require("telescope.finders")
    local conf = require('telescope.config').values

    local opts = {
        sorting_strategy = "ascending"
    }
    pickers.new(opts, {
        prompt_title = "Code Actions",
        finder = finders.new_table {
            results = items,
            entry_maker = function(entry)
                return {
                    value = entry,
                    ordinal = entry.id..entry.search,
                    display = "["..entry.id.."] "..entry.title,
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                vim.schedule(selection.value.action)
            end)
            return true
        end
    }):find()
end

local function lspActionsAsync(withactions, finally)
    local params = vim.lsp.util.make_range_params()
    params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }

    vim.lsp.buf_request(0, 'textDocument/codeAction', params, function(err, actions, ctx, _)
      if err then
          print("Error getting code actions: ", err)
      else
          if actions then
              withactions(actions)
          end
      end
      finally()
    end)
end

local function code_actions()
    local _nextid = 1
    local function allocid()
        local v = _nextid
        _nextid = _nextid + 1
        return v
    end

    local actions = {
        {
            id = allocid(),
            search = "rename",
            title = "Refactor: Rename",
            action = function()
                require("live-rename").rename({ text = "", insert = true })
            end
        },
        {
            id = allocid(),
            search = "LSP: References",
            title = "LSP: References",
            action = function()
                vim.cmd([[Telescope lsp_references]])
            end
        }
    }
    local lsp_actions = {}

    lspActionsAsync(function(lsp_actions_in)
        for _,action in ipairs(lsp_actions_in) do
            lsp_actions[action.title] = action
        end
    end, function()
        for _,action in pairs(lsp_actions) do
            local title = "LSP: "..action.title
            table.insert(actions, {
                id = allocid(),
                search = title,
                title = title,
                action = function()
                    vim.lsp.buf.code_action({
                        apply = true,
                        filter = function(ac)
                            return ac.title == action.title
                        end
                    })
                end
            })
        end
        code_actions_menu(actions)
    end)
end
vim.keymap.set({ 'n', 'v' }, '<space>ca', code_actions, {})

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
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    end,
})

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local mode = vim.api.nvim_get_mode().mode
        local filetype = vim.bo.filetype
        if vim.bo.modified == true and mode == 'n' and filetype ~= "oil" then
            vim.cmd('lua vim.lsp.buf.format()')
        else
        end
    end
})

vim.cmd([[autocmd BufRead,BufNewFile *.ua setfiletype uiua]])
lspconfig.uiua.setup {}
vim.cmd([[hi link @lsp.type.uiua_number @number]])
vim.cmd([[hi link @lsp.type.uiua_string @string]])
vim.cmd([[hi link @lsp.type.uiua_module @Type]])
vim.cmd([[hi link @lsp.type.uiua_constant Constant]])
vim.cmd([[hi @lsp.type.noadic_function guifg=#ed5e6a]])
vim.cmd([[hi @lsp.type.monadic_function guifg=#95d16a]])
vim.cmd([[hi @lsp.type.dyadic_function guifg=#54b0fc]])
vim.cmd([[hi @lsp.type.triadic_function guifg=#8078f1]])
vim.cmd([[hi @lsp.type.tetradic_function guifg=#f576d8]])
vim.cmd([[hi @lsp.type.monadic_modifier guifg=#f0c36f]])
vim.cmd([[hi @lsp.type.dyadic_modifier guifg=#cc6be9]])
vim.cmd([[hi @lsp.type.triadic_modifier guifg=#F5A9B8]])
