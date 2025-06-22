local M = {}
local ns = vim.api.nvim_create_namespace("MySelector")
M.ranges = {}
M.index = 1

-- Highlight setup
vim.api.nvim_set_hl(0, "MyHighlight", { bg = "#444444" })

-- Helper to convert LSP range to Neovim format
local function lsp_range_to_vim(range)
    return {
        start_line = range.start.line,
        start_col = range.start.character,
        end_line = range["end"].line,
        end_col = range["end"].character
    }
end

function M.abort()
    -- Clear highlight
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    -- Clear state
    M.ranges = {}
    M.index = 0
end

function M.select_range(idx)
    local range = M.ranges[idx]
    if not range then return end

    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    -- Highlight (Neovim API expects 0-based lines)
    for l = range.start_line, range.end_line do
        local s_col = (l == range.start_line) and range.start_col or 0
        local e_col = (l == range.end_line) and range.end_col or -1
        vim.api.nvim_buf_add_highlight(bufnr, ns, "MyHighlight", l, s_col, e_col)
    end

    -- Set cursor to start (win_set_cursor is 1-based)
    vim.api.nvim_win_set_cursor(0, { range.start_line + 1, range.start_col })

    -- Schedule visual mode after cursor move
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, { range.end_line + 1, range.end_col })
    end)
end

function M.next()
    if #M.ranges == 0 then return end
    M.index = math.min(M.index + 1, #M.ranges)
    M.select_range(M.index)
end

function M.prev()
    if #M.ranges == 0 then return end
    M.index = math.max(M.index - 1, 1)
    M.select_range(M.index)
end

function M.start()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        positions = { { line = row - 1, character = col } },
    }

    vim.lsp.buf_request(0, "textDocument/selectionRange", params, function(err, result)
        if err or not result or not result[1] then
            vim.notify("No selectionRange from LSP", vim.log.levels.WARN)
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local last_line_index = vim.api.nvim_buf_line_count(bufnr) - 1
        local last_line_text = vim.api.nvim_buf_get_lines(bufnr, last_line_index, last_line_index + 1, false)[1] or ""
        local last_line_col = #last_line_text

        local function is_invalid_range(r)
            local out_of_bounds = (
                r.end_line > last_line_index or
                (r.end_line == last_line_index and r.end_col > last_line_col)
            )

            local is_full_doc = (
                r.start_line == 0 and r.start_col == 0 and out_of_bounds
            )

            local is_empty = (
                r.start_line == r.end_line and r.start_col == r.end_col
            )

            local is_single_char = (
                r.start_line == r.end_line and (r.end_col - r.start_col) <= 1
            )

            return is_full_doc or out_of_bounds or is_empty or is_single_char
        end

        -- Flatten and filter ranges
        local ranges = {}
        local current = result[1]
        while current do
            local r = lsp_range_to_vim(current.range)
            if not is_invalid_range(r) then
                table.insert(ranges, r)
            end
            current = current.parent
        end

        if #ranges == 0 then
            vim.notify("No usable selection ranges", vim.log.levels.WARN)
            return
        end

        M.ranges = ranges
        M.index = 1
        M.select_range(M.index)
    end)
end

return M
