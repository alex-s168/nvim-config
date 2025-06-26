local lspconfig = require("lspconfig")

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']', vim.diagnostic.goto_next)

local function lspAnyClientSupports(bufnr, method)
    for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if client:supports_method(method, bufnr) then
            return true
        end
    end
    return false
end

-- list: []{title, search, action}
local function code_actions_menu(items, second_title)
    local pickers = require("telescope.pickers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local finders = require("telescope.finders")
    local conf = require('telescope.config').values

    local title = "Code Actions"
    if second_title then
        title = title .. ": " .. second_title
    end

    local opts = {
        sorting_strategy = "ascending"
    }
    pickers.new(opts, {
        prompt_title = title,
        finder = finders.new_table {
            results = items,
            entry_maker = function(entry)
                return {
                    value = entry,
                    ordinal = entry.id .. entry.search,
                    display = "[" .. entry.id .. "] " .. entry.title,
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

local function lspActionsAsync(bufnr, withactions, finally)
    local params = { unpack(vim.lsp.util.make_range_params(nil, "utf-8")) }
    params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }

    vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', params, function(_, actions, _)
        if actions then
            withactions(actions)
        end
        finally()
    end)
end

local function lspWorkspaceSymbolsAsync(bufnr, withsymbols, finally)
    local params = { query = "" }

    vim.lsp.buf_request_all(bufnr, "workspace/symbol", params, function(err, list, _, _)
        if list then
            withsymbols(list)
        end
        finally()
    end)
end

local function escape_pattern(s)
    return s:gsub("([^%w])", "%%%1")
end

local comment_prefixes = {
    lua = "--",
    python = "#",
    sh = "#",
    bash = "#",
    uiua = "#",
    javascript = "//",
    typescript = "//",
    c = "//",
    cpp = "//",
    java = "//",
    rust = "//",
}

local function lsp_range_to_vim(range)
    return {
        start_line = range.start.line,
        start_col = range.start.character,
        end_line = range["end"].line,
        end_col = range["end"].character
    }
end

local function code_actions()
    local _nextid = 1
    local function allocid()
        local v = _nextid
        _nextid = _nextid + 1
        return v
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype
    local comment_prefix = comment_prefixes[filetype]

    local selection = {
        first = vim.fn.getpos("v"),
        last = vim.fn.getpos("."),
    }
    (function()
        local line1 = selection.first[2] - 1
        local line2 = selection.last[2] - 1

        selection.start_line = math.min(line1, line2)
        selection.end_line = math.max(line1, line2)

        selection.valid = selection.start_line >= 0 and selection.end_line >= 0
    end)()

    local function extend_selection_to_lsp_ranges(lines)
        if not selection.valid then
            return false
        end

        if not lspAnyClientSupports(bufnr, "textDocument/selectionRange") then
            return false
        end

        local last_line = lines[#lines]

        local timeout_ms = 300

        local positions_li = {
            { { line = selection.end_line, character = #last_line - 1 } },
            { { line = selection.start_line, character = 1 } },
        }

        vim.print(vim.inspect(selection.start_line))
        local orig_selec = {
            start_line = selection.start_line,
            end_line = selection.end_line
        }

        for _, positions_x in ipairs(positions_li) do
            local params = {
                textDocument = vim.lsp.util.make_text_document_params(),
                positions = positions_x,
            }

            local lsp_res = vim.lsp.buf_request_sync(bufnr, "textDocument/selectionRange", params, timeout_ms)
            if lsp_res then
                for _, out in ipairs(lsp_res) do
                    local err = out.error
                    local result = out.result

                    if err or not result or not result[1] then
                        goto continue
                    end

                    local curr = result[1]
                    while curr do
                        local range = lsp_range_to_vim(curr.range)
                        if range.end_col == 0 then
                            range.end_line = range.end_line - 1
                        end
                        if range.start_line >= orig_selec.start_line and range.start_line <= orig_selec.end_line then
                            selection.end_line = math.max(selection.end_line, range.end_line)
                        end
                        if range.start_line < orig_selec.start_line and range.end_line >= orig_selec.start_line and range.end_line <= orig_selec.end_line then
                            selection.start_line = math.min(selection.start_line, range.start_line)
                        end
                        curr = curr.parent
                    end

                    ::continue::
                end
            end
        end

        return true
    end

    local actions = {}

    if comment_prefix and selection.valid then
        local lines = vim.api.nvim_buf_get_lines(bufnr, selection.start_line, selection.end_line + 1, false)
        if extend_selection_to_lsp_ranges(lines) then
            lines = vim.api.nvim_buf_get_lines(bufnr, selection.start_line, selection.end_line + 1, false)
        end

        local first_block_none_space = math.huge
        for _, line in ipairs(lines) do
            if not line:match("^%s*$") then
                local _, count = string.find(line, "^%s*")
                first_block_none_space = math.min(first_block_none_space, count)
            end
        end

        if first_block_none_space == math.huge then
            first_block_none_space = 0
        end

        local pat = "^" .. string.rep(" ", first_block_none_space) .. escape_pattern(comment_prefix) .. " ?"

        local any_not_commented = false
        for _, line in ipairs(lines) do
            if not line:match(pat) then
                any_not_commented = true
            end
        end

        if any_not_commented then
            table.insert(actions, {
                id = allocid(),
                search = "comment out disable selection",
                title = "Comment out selection",
                action = function()
                    for i = 1, #lines do
                        local rem = string.sub(lines[i], first_block_none_space + 1)
                        lines[i] = string.rep(" ", first_block_none_space) .. comment_prefix .. " " .. rem
                    end

                    vim.api.nvim_buf_set_lines(bufnr, selection.start_line, selection.end_line + 1, false, lines)
                end
            })
        else
            table.insert(actions, {
                id = allocid(),
                search = "uncomment enable selection",
                title = "Uncomment selection",
                action = function()
                    for i = 1, #lines do
                        lines[i] = lines[i]:gsub(pat, string.rep(" ", first_block_none_space))
                    end

                    vim.api.nvim_buf_set_lines(bufnr, selection.start_line, selection.end_line + 1, false, lines)
                end
            })
        end
    end

    table.insert(actions, {
        id = allocid(),
        search = "rename",
        title = "Refactor: Rename",
        action = function()
            require("live-rename").rename({ text = "", insert = true })
        end
    })

    table.insert(actions, {
        id = allocid(),
        search = "LSP: References",
        title = "LSP: References",
        action = function()
            vim.cmd([[Telescope lsp_references]])
        end
    })

    local lsp_actions = {}
    lspActionsAsync(bufnr, function(lsp_actions_in)
        for _, action in ipairs(lsp_actions_in) do
            lsp_actions[action.title] = action
        end
    end, function()
        local lsp_disable_diagnostics = {}
        local have_lsp_disable_diagnostics = false

        for _, action in pairs(lsp_actions) do
            if string.match(action.title, "^Disable diagnostics ") then
                local d = action.title:gsub("^Disable diagnostics ", "")
                lsp_disable_diagnostics[d] = action
                have_lsp_disable_diagnostics = true
                goto continue
            end

            local title = "LSP: " .. action.title
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

            ::continue::
        end

        if have_lsp_disable_diagnostics then
            table.insert(actions, {
                id = allocid(),
                search = "LSP: Disable diagnostics",
                title = "LSP: Disable diagnostics (*)",
                action = function()
                    local dis_actions = {}
                    for key, value in pairs(lsp_disable_diagnostics) do
                        table.insert(dis_actions, {
                            id = allocid(),
                            search = key,
                            title = key,
                            action = function()
                                vim.lsp.buf.code_action({
                                    apply = true,
                                    filter = function(ac)
                                        return ac.title == value.title
                                    end
                                })
                            end
                        })
                    end
                    code_actions_menu(dis_actions, "Disable Diagnostics")
                end
            })
        end

        code_actions_menu(actions)
    end)
end
vim.keymap.set("n", '<space>ca', code_actions, {})
vim.keymap.set("v", '<space>ca', code_actions, {})

local function global_actions()
    local _nextid = 1
    local function allocid()
        local v = _nextid
        _nextid = _nextid + 1
        return v
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype

    local actions = {}

    if lspAnyClientSupports(bufnr, "workspace/symbol") then
        table.insert(actions, {
            id = allocid(),
            search = "LSP: Workspace Symbols",
            title = "LSP: Workspace Symbols",
            action = function()
                local sym_actions = {}
                lspWorkspaceSymbolsAsync(bufnr, function(symbols)
                    for _, sym in ipairs(symbols) do
                        table.insert(sym_actions, {
                            id = allocid(),
                            search = sym.name,
                            title = sym.name,
                            action = function() end
                        })
                    end
                end, function()
                    code_actions_menu(sym_actions, "Workspace Symbols")
                end)
            end
        })
    end

    code_actions_menu(actions)
end
vim.keymap.set("n", '<space>ga', global_actions, {})

vim.api.nvim_create_user_command("LspSections", function()
    require("select_parent_range").start()
end, {})

vim.keymap.set("n", '<Tab>', function()
    require("select_parent_range").next()
end, { noremap = true })

vim.keymap.set("n", '<S-Tab>', function()
    require("select_parent_range").prev()
end, { noremap = true })

vim.keymap.set("n", '<Esc>', function()
    require("select_parent_range").abort()
end, { noremap = true })

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
