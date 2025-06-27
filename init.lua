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

local lsp_ai_init_options = {
    models = {
        model1 = {
            type = "open_ai",
            completions_endpoint = "http://127.0.0.1:8070/v1/completions",
            chat_endpoint = "http://127.0.0.1:8070/v1/chat/completions",
            model = "qwen1_5-0_5b-chat-q4_k_m",
            auth_token = "",
        }
    },
    completion = {
        model = "model1",
        parameters = vim.empty_dict()
    },
    actions = {
        {
            trigger = "!C",
            action_display_name = "Chat",
            model = "model1",
            parameters = {
                max_context = 4096,
                max_tokens = 4096,
                system = [[
You are an AI coding assistant. Your task is to complete code snippets. The user's cursor position is marked by \"<CURSOR>\". Follow these steps:

1. Analyze the code context and the cursor position.
2. Provide your chain of thought reasoning, wrapped in <reasoning> tags. Include thoughts about the cursor position, what needs to be completed, and any necessary formatting.
3. Determine the appropriate code to complete the current thought, including finishing partial words or lines.
4. Replace \"<CURSOR>\" with the necessary code, ensuring proper formatting and line breaks.
5. Wrap your code solution in <answer> tags.

Your response should always include both the reasoning and the answer. Pay special attention to completing partial words or lines before adding new lines of code.

<examples>
<example>
User input:
--main.py--
# A function that reads in user inpu<CURSOR>

Response:
<reasoning>
1. The cursor is positioned after \"inpu\" in a comment describing a function that reads user input.
2. We need to complete the word \"input\" in the comment first.
3. After completing the comment, we should add a new line before defining the function.
4. The function should use Python's built-in `input()` function to read user input.
5. We'll name the function descriptively and include a return statement.
</reasoning>

<answer>t
def read_user_input():
 user_input = input(\"Enter your input: \")
 return user_input
</answer>
</example>

<example>
User input:
--main.py--
def fibonacci(n):
 if n <= 1:
 return n
 else:
 re<CURSOR>


Response:
<reasoning>
1. The cursor is positioned after \"re\" in the 'else' clause of a recursive Fibonacci function.
2. We need to complete the return statement for the recursive case.
3. The \"re\" already present likely stands for \"return\", so we'll continue from there.
4. The Fibonacci sequence is the sum of the two preceding numbers.
5. We should return the sum of fibonacci(n-1) and fibonacci(n-2).
</reasoning>

<answer>turn fibonacci(n-1) + fibonacci(n-2)</answer>
</example>
</examples>
]],
                messages = {
                    {
                        role = "user",
                        content = "{CODE}"
                    }
                }
            },
            post_process = {
                extractor = "(?s)<answer>(.*?)</answer>"
            }
        }
    }
}

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
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clangd = {},
                rust_analyzer = {},
                kotlin_language_server = {},
                csharp_ls = {},
                typos_lsp = {
                    init_options = {
                        diagnosticSeverity = "Warning",
                    }
                },
                uiua = {},
                lua_ls = {
                    on_init = function(client)
                        local path = client.workspace_folders[1].name
                        if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
                            return
                        end

                        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                            runtime = { version = "LuaJIT" },
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true)
                            }
                        })
                    end,
                    settings = {
                        Lua = {}
                    }
                },
                lsp_ai = {
                    root_dir = vim.fn.getcwd(),
                    init_options = lsp_ai_init_options
                }
            }
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local blink = require("blink.cmp")

            for server, config in pairs(opts.servers) do
                config.capabilities = blink.get_lsp_capabilities(config.capabilities)
                lspconfig[server].setup(config)
            end
        end
    },
    {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets' },
        build = 'cargo build --release',

        opts = {
            keymap = { preset = "enter" },

            appearance = {
                nerd_font_variant = "mono"
            },

            completion = { documentation = { auto_show = true } },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },

            signature = {
                enabled = false,
            },

            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" }
    },
    { "saecki/live-rename.nvim" },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup {
                ensure_installed = { "c", "lua", "query", "markdown", "markdown_inline", "rust", "html" },
                sync_install = false,
                highlight = { enable = false },
                indent = { enable = false },
            }
        end
    },

    -- utils --
    {
        "stevearc/oil.nvim",
        opts = {}
    },
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
    },
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
