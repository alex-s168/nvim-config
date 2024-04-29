vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
  { "williamboman/mason.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "nvim-tree/nvim-web-devicons" },
  { "nvim-tree/nvim-tree.lua" },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { 'hrsh7th/nvim-cmp' },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'hrsh7th/cmp-nvim-lsp' },
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {}
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'}}
  },
  {
    "willothy/nvim-cokeline",
    dependencies = {
      "nvim-lua/plenary.nvim",        -- Required for v0.4.0+
      "nvim-tree/nvim-web-devicons", -- If you want devicons
      "stevearc/resession.nvim"       -- Optional, for persistent history
    },
    config = true
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.3.0",
    -- install jsregexp (optional!).
    build = "make install_jsregexp"
  },
  {
    'nvimakinsho/toggleterm.nvim',
    version = "*",
    config = true
  },
  { 'nvim-treesitter/nvim-treesitter' },
})

vim.cmd(":TSUpdate")
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

require("toggleterm").setup{}

require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

require("mason-lspconfig").setup()

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

require("nvim-tree").setup {
    actions = {
        open_file = {
            quit_on_open = true,
        },
    },
    on_attach = function(bufnr)
        local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        local ok, api = pcall(require, "nvim-tree.api")
        assert(ok, "api module is not found")
        vim.keymap.set("n", "<CR>", api.node.open.tab_drop, opts("Tab drop"))
    end
}

local keymap = vim.api.nvim_set_keymap
keymap("n", "<C-l>", ":NvimTreeToggle<CR>", {})

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window" })

vim.keymap.set("n", "<C-w>", ":Telescope find_files<CR>", {})

local cmp = require 'cmp'
cmp.setup {
    mapping = cmp.mapping.preset.insert({
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
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
        { name = 'luasnip' }
    },
}
