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
    version = "v3.9.0",
    lazy = false,
    config = function()
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
		end
  },

  -- important --
  {
    "neovim/nvim-lspconfig",
    lazy = false
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'master',
    lazy = false,
    build = ":TSUpdate",
    config = {
      ensure_installed = { "c", "lua", "vimdoc", "query", "markdown", "markdown_inline" },
      auto_install = true,
--      ignore_install = { "org" },

      indent = {
        enable = true,
      },

      sync_install = false,

      highlight = {
        enable = true,
        disable = { "rust" },
        additional_vim_regex_highlighting = false,
      },
    }
  },
  {
    "saghen/blink.cmp",
    -- don't push del in this line!

    opts = {
      keymap = {
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<Tab>'] = { 'accept', 'fallback' },
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

      -- don't push!
      fuzzy = { implementation = "lua" },
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
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
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
    end
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

require("lsp")

vim.cmd([[colorscheme carbonfox]])

vim.o.expandtab = true
vim.o.smartindent = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2

vim.keymap.set("n", "<C-l>", function()
  vim.cmd([[:Oil]])
end)

vim.lsp.config("typos_lsp", {
  init_options = {
    diagnosticSeverity = "Warning",
  }
})
vim.lsp.enable("typos_lsp")

-- TODO: comment = "// \1"

local function is_inside_nvim_config(path)
  local uv = vim.loop
  local nvim_config = vim.fn.stdpath("config")  -- usually ~/.config/nvim

  -- Normalize both paths (resolve symlinks, remove '..', etc.)
  local real_path = uv.fs_realpath(path)
  local real_config = uv.fs_realpath(nvim_config)

  if not real_path or not real_config then
    return false
  end

  return real_path:sub(1, #real_config) == real_config
end

languages = {
  ["java"] = {
    files = { ".*[.]java" },
    comment_prefix = "//",
    tree_sitter = {},
  },

  ["forth"] = {
    files = { ".*[.]4th", ".*[.]forth" },
    comment_prefix = "(",
    tree_sitter = {}
  },

  ["javascript"] = {
    files = { ".*[.]js" },
    comment_prefix = "//",
    tree_sitter = {},
  },

  ["html"] = {
    files = { ".*[.]html" },
    comment_prefix = "//",
    tree_sitter = {},
  },

  ["css"] = {
    files = { ".*[.]css" },
    -- TODO: comments
    tree_sitter = {},
  },

  ["hare"] = {
    files = { ".*[.]ha" },
    comment_prefix = "//",
    tree_sitter = {},

    doc_provider = function(key)
      local v = vim.fn.system("haredoc "..key)
      return v and { text = v, lang = "hare" }
    end
  },

  ["c"] = {
    files = { ".*[.]c" },
    pats = {
      [".clang-format"] = "yaml",
    },
    comment_prefix = "//",
    tree_sitter = {},
    lsp = {
      clangd = {}
    }
  },

  ["prolog"] = {
    files = { ".*[.]p" },
    comment_prefix = "%",
    tree_sitter = {}
  },

  ["markdown"] = {
    files = { ".*[.]md" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["yaml"] = {
    files = { ".*[.]yaml", ".*[.]yml" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["zig"] = {
    files = { ".*[.]zig", ".*[.]zig[.]zon" },
    comment_prefix = "//",
    lsp = {
      zls = {},
    },
    tree_sitter = {},
  },

  ["lua"] = {
    files = { ".*[.]lua" },
    comment_prefix = "--",
    tree_sitter = {},
    lsp = {
      lua_ls = {
        on_init = function(client)
          local path = client.workspace_folders[1].name
          if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
            return
          end

          if is_inside_nvim_config(path) then
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true)
              }
            })
          end
        end,
        settings = {
          Lua = {}
        }
      },
    },
  },

  ["rust"] = {
    files = { ".*[.]rs" },
    comment_prefix = "//",
    tree_sitter = {},
    lsp = {
      rust_analyzer = {}
    },
  },

  ["capnp"] = {
    files = { ".*[.]capnp" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["kotlin"] = {
    files = { ".*[.]kt", ".*[.]kts" },
    comment_prefix = "//",
    tree_sitter = {},
    lsp = {
      kotlin_language_server = {},
    },
  },

  ["csharp"] = {
    files = { ".*[.]cs" },
    comment_prefix = "//",
    tree_sitter = {},
    lsp = {
      csharp_ls = {},
    },
  },

  ["uiua"] = {
    files = { ".*[.]ua" },
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
    files = { ".*[.]mlir" },
    comment_prefix = "#",

    lsp = {
      mlir = {
        cmd = "~/llvm-project/build/bin/mlir-lsp-server"
      }
    }
  },

  ["crepuscular"] = {
    files = { ".*[.]crr" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["vxj"] = {
    files = { ".*[.]vxj" },
    comment_prefix = "//",
    tree_sitter = {},
  },

  ["asciidoc"] = {
    files = { ".*[.]adoc", ".*[.]txt" },
    comment_prefix = "//",
    tree_sitter = {}
  },

  ["python"] = {
    files = { ".*[.]py" },
    comment_prefix = "#",
    tree_sitter = {},
    lsp = {
      ty = {
        cmd = {"uvx", "ty", "server"},
      },
    },
  },

  ["ocamlinterface"] = {
    files = { ".*[.]mli" },
    tree_sitter = { name = "ocaml_interface" },
    lsp = {
      ocamllsp = {}
    },
  },

  ["why"] = {
    files = { ".*[.]why", ".*[.]mlw" },
    tree_sitter = {
      name = "ocaml"
    },
  },

  ["ocaml"] = {
    files = { ".*[.]ml" },
    tree_sitter = {},
    lsp = {
      ocamllsp = {}
    },
  },

  ["haskell"] = {
    files = { ".*[.]hs" },
    comment_prefix = "#",
    tree_sitter = {},
    lsp = {
      haskell_language_server = {}
    }
  },

  ["meson"] = {
    files = { ".*[.]meson" },
    comment_prefix = "#",
    tree_sitter = {},
  },

  ["typst"] = {
    files = { ".*[.]typ" },
    comment_prefix = "//",
    tree_sitter = {}
  },
}


local function get_treesitter_word_range()
  local node = vim.treesitter.get_node()
  if not node then return nil end

  local s_row, s_col, e_row, e_col = node:range()
  return {
    start_row = s_row,
    start_col = s_col,
    end_row = e_row,
    end_col = e_col
  }
end

local function get_vim_word_range()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-indexed column

  -- This finds the start and end of the word under the cursor
  local word = vim.fn.expand('<cword>')
  if word == "" then return nil end

  -- Find the start of the word relative to the cursor
  -- We search backwards from the cursor for the word start
  local start_col = vim.fn.matchstrpos(line:sub(1, col + #word), [[\k*\%]] .. (col + 1) .. [[c\k*]])[2]
  local end_col = vim.fn.matchstrpos(line:sub(1, col + #word), [[\k*\%]] .. (col + 1) .. [[c\k*]])[3]

  return {
    start_row = vim.api.nvim_win_get_cursor(0)[1] - 1,
    start_col = start_col,
    end_row =  vim.api.nvim_win_get_cursor(0)[1] - 1,
    end_col = end_col
  }
end

local function get_tagged_node_range(query, capture_name)
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Treesitter uses 0-indexed rows

  -- 1. Get the parser and the tree
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  -- 3. Iterate over matches
  for id, node, _ in query:iter_captures(root, bufnr, row, row + 1) do
    local name = query.captures[id] -- name of the capture (e.g., "my_tag")

    if name == capture_name then
      -- Check if the cursor is actually inside this specific node
      if vim.treesitter.is_in_node_range(node, row, col) then
        local s_row, s_col, e_row, e_col = node:range()
        return {
          start_row = s_row,
          start_col = s_col,
          end_row = e_row,
          end_col = e_col
        }
      end
    end
  end
  return nil
end



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
  vim.api.nvim_create_autocmd("FileType", {
    pattern = lang,
    callback = function(ev)
      if spec.on_buf then
        spec.on_buf({ buf = ev.buf, file = ev.file })
      end

      ---- treesitter ----
      local q_whole_ident = nil
      if spec.tree_sitter then
        local ts_lang = spec.tree_sitter.name or lang
        vim.treesitter.start(ev.buf, ts_lang)
        vim.cmd([[TSEnable highlight indent incremental_selection]])

        q_whole_ident = vim.treesitter.query.get(ts_lang, "whole-identifier")
      end

      vim.keymap.set('n', 'K', function()
        local range = q_whole_ident and get_tagged_node_range(q_whole_ident, "whole-identifier")
        range = range or get_treesitter_word_range()
        range = range or get_vim_word_range()
        
        if range and (range.start_row ~= range.end_row or range.start_col ~= range.end_col) then
          local lines = vim.api.nvim_buf_get_text(0, range.start_row, range.start_col, range.end_row, range.end_col, {})
          local text = vim.trim(table.concat(lines, "\n"))

          if #text then
            local doc = spec.doc_provider and spec.doc_provider(text)
            if doc then
              local bufnr, winnr = vim.lsp.util.open_floating_preview(vim.split(doc.text, "\n"), doc.lang, {
                border = "rounded",
                focusable = true,
                close_events = { "CursorMoved", "InsertEnter" },
              })
              vim.bo[bufnr].filetype = doc.lang
            else
              vim.cmd("Man " .. text)
            end
          end
        end
      end, { buffer = ev.buf })
    end
  })
  -------------------


  if spec.init then
    spec.init()
  end
end

-- require("ts_diagnostic")
