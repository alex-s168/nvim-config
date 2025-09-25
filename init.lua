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
    version = "v3.9.0"
  },

  -- important --
  { "neovim/nvim-lspconfig" },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'master',
    lazy = false,
    build = ":TSUpdate"
  },
  {
    "saghen/blink.cmp",
    build = "cargo build --release",

    opts = {
      keymap = {
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<Tab>'] = { 'accept' },
        ['<C-k>'] = { 'show_signature', 'hide_signature' },
      },

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


  -- utils --
  {
    "stevearc/oil.nvim",
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    lazy = false,
    opts = {
      default_file_explorer = true,
    }
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { 'davvid/telescope-git-grep.nvim' },
  {
    "willothy/nvim-cokeline",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for v0.4.0+
    },
    config = true
  },
})

vim.cmd([[colorscheme carbonfox]])

require("lsp")

require("nvim-treesitter.configs").setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },

  sync_install = false,

  auto_install = true,

  highlight = {
    enable = true,
    disable = { "rust" },
    additional_vim_regex_highlighting = false,
  },
}

vim.o.expandtab = true
vim.o.smartindent = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2

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

local oilSetup = false
local function setupOil()
  if not oilSetup then
    require("oil").setup()
    oilSetup = true
  end
end

vim.keymap.set("n", "<C-l>", function()
  setupOil()
  vim.cmd([[:Oil]])
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

vim.lsp.config("typos_lsp", {
  init_options = {
    diagnosticSeverity = "Warning",
  }
})
vim.lsp.enable("typos_lsp")

vim.lsp.config("lsp_ai", {
  root_dir = vim.fn.getcwd(),
  init_options = require("lsp/lsp_ai")
})
vim.lsp.enable("lsp_ai")

-- TODO: comment = "// \1"

local languages = {
  ["java"] = {
    files = { "*.java" },
    comment_prefix = "//",
    tree_sitter = {},
  },

  ["c"] = {
    files = { "*.c" },
    pats = {
      [".clang-format"] = "yaml",
    },
    comment_prefix = "//",
    tree_sitter = {},

    lsp = {
      clangd = {}
    }
  },

  ["markdown"] = {
    files = { "*.md" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["lua"] = {
    files = { "*.lua" },
    comment_prefix = "--",
    tree_sitter = {},

    lsp = {
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
    },
  },

  ["rust"] = {
    files = { "*.rs" },
    comment_prefix = "//",

    lsp = {
      rust_analyzer = {}
    },
  },

  ["kotlin"] = {
    files = { "*.kt", "*.kts" },
    comment_prefix = "//",

    lsp = {
      kotlin_language_server = {},
    },
  },

  ["csharp"] = {
    files = { "*.cs" },
    comment_prefix = "//",

    lsp = {
      csharp_ls = {},
    },
  },

  ["uiua"] = {
    files = { "*.ua" },
    comment_prefix = "#",

    lsp = {
      uiua = {}
    },

    on_init = function()
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
    end,
  },

  ["mlir"] = {
    files = { "*.mlir" },
    comment_prefix = "#",

    lsp = {
      mlir = {
        cmd = "~/llvm-project/build/bin/mlir-lsp-server"
      }
    }
  },

  ["crepuscular"] = {
    files = { "*.crr" },
    comment_prefix = "#",
    tree_sitter = {}
  },

  ["asciidoc"] = {
    files = { "*.adoc", "*.txt" },
    comment_prefix = "//",
    tree_sitter = {}
  },
}


----- init languages -----
local blink = require("blink.cmp")
local langMappedLsps = {}
for lang, spec in pairs(languages) do
  ---- treesitter ----
  if spec.tree_sitter then
    vim.treesitter.language.add(lang, {
      path = spec.tree_sitter.bin
    })
  end
  --------------------


  ---- filetypes ----
  local pats = {}
  if spec.pats then
    for k, v in pairs(spec.pats) do
      pats[k] = v
    end
  end
  if spec.files then
    for _, pat in ipairs(spec.files) do
      pats[pat] = lang
    end
  end
  vim.filetype.add({
    pattern = pats
  })
  -------------------


  ---- LSPs ----
  for lsp, config in pairs(spec.lsp or {}) do
    local fileTypes = {}
    if vim.lsp.config[lsp] then
      fileTypes = vim.lsp.config[lsp].filetypes or {}
    end
    local configCpy = {}
    for k, v in pairs(config) do
      configCpy[k] = v
    end
    if config.filetypes then
      for _, ft in ipairs(config.filetypes) do
        table.insert(fileTypes, ft)
      end
    end
    configCpy.filetypes = fileTypes
    configCpy.capabilities = blink.get_lsp_capabilities(configCpy.capabilities)
    vim.lsp.config(lsp, configCpy)

    if not langMappedLsps[lsp] then
      vim.lsp.enable(lsp)
    end
    langMappedLsps[lsp] = true
  end
  --------------


  ---- on open ----
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = spec.files,
    callback = function(ev)
      if spec.on_buf then
        spec.on_buf({ buf = ev.buf, file = ev.file })
      end

      ---- treesitter ----
      if spec.tree_sitter then
        vim.treesitter.start(ev.buf, lang)
      end
    end
  })
  -------------------


  if spec.init then
    spec.init()
  end
end
