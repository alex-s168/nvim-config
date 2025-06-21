vim.opt.termguicolors = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- visuals --
    { "EdenEast/nightfox.nvim" },
    { "nvim-tree/nvim-web-devicons" },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
        version = "v3.5.4"
    },

    -- important --
    { "neovim/nvim-lspconfig" },
    { 'hrsh7th/nvim-cmp' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-buffer' },
    {
        "L3MON4D3/LuaSnip",
        version = "v2.3.0",
        -- install jsregexp (optional!).
        build = "make install_jsregexp"
    },
    { "saecki/live-rename.nvim" },

    -- utils --
    { "stevearc/oil.nvim" },
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    { 'davvid/telescope-git-grep.nvim' },
    {
        'nvimdev/dashboard-nvim',
        event = 'VimEnter',
        config = function()
            require('dashboard').setup {}
        end
    },
    {
        "willothy/nvim-cokeline",
        dependencies = {
            "nvim-lua/plenary.nvim",  -- Required for v0.4.0+
            "stevearc/resession.nvim" -- Optional, for persistent history
        },
        config = true
    },
    {
        "scalameta/nvim-metals",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        ft = { "scala", "sbt", "java" },
        opts = function()
            local metals_config = require("metals").bare_config()
            metals_config.on_attach = function(client, bufnr)
                -- your on_attach function
            end

            return metals_config
        end,
        config = function(self, metals_config)
            local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = self.ft,
                callback = function()
                    require("metals").initialize_or_attach(metals_config)
                end,
                group = nvim_metals_group,
            })
        end
    },
})

vim.cmd("colorscheme carbonfox")

require("lsp")

vim.o.expandtab = true
vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

require("ibl").setup({
    indent = {
        char = "|"
    },
    whitespace = { highlight = { "Whitespace", "NonText" } },
    scope = {
        show_start = false,
        show_end = false
    }
})

-- stolen from https://github.com/lukas-reineke/indent-blankline.nvim/discussions/664
require("ibl.hooks").register(require("ibl.hooks").type.VIRTUAL_TEXT, function(_, bufnr, row, virt_text)
    local config = require("ibl.config").get_config(bufnr)
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if line == "" then
        for _, v in ipairs(virt_text) do
            if v[1] == config.indent.char then
                v[1] = "┊"
            end
        end
    end
    return virt_text
end)

require("oil").setup({})
vim.keymap.set("n", "<C-l>", function()
    require("oil").open()
end)

require("telescope").load_extension('git_grep')
-- one esc => exit instead of double esc
require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<esc>"] = require("telescope.actions").close,
            },
        },
    },
})

local cmp = require 'cmp'
cmp.setup {
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
    }),
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'buffer' },
        { name = 'luasnip' },
    },
}
