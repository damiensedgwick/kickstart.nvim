-- init.lua - minimal, fast neovim config

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.termguicolors = true
o.mouse = 'a'
o.clipboard = 'unnamedplus'
o.undofile = true
o.swapfile = false
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.updatetime = 250
o.timeoutlen = 300
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.wrap = false
o.showmode = false

-- Keymaps
local map = vim.keymap.set

map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')
map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('v', '<', '<gv')
map('v', '>', '>gv')
map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")

map('n', '<leader>?', function() require('which-key').show() end, { desc = 'Show keymaps' })

local user_group = vim.api.nvim_create_augroup('user_config', { clear = true })

local function apply_colorscheme(background)
  vim.o.background = background
  vim.cmd.colorscheme 'catppuccin'
end

local function setup_lsp()
  vim.lsp.config('ts_ls', {})
  vim.lsp.config('pyright', {})
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        diagnostics = { globals = { 'vim' } },
        workspace = { checkThirdParty = false },
      },
    },
  })
  vim.lsp.enable { 'ts_ls', 'pyright', 'lua_ls' }
end

-- Defer LSP setup until opening a filetype that actually benefits from it.
vim.api.nvim_create_autocmd('FileType', {
  group = user_group,
  once = true,
  pattern = { 'javascript', 'javascriptreact', 'lua', 'python', 'typescript', 'typescriptreact' },
  callback = setup_lsp,
})

-- LSP keymaps on attach
vim.api.nvim_create_autocmd('LspAttach', {
  group = user_group,
  callback = function(ev)
    local b = ev.buf
    map('n', 'gd', vim.lsp.buf.definition, { buffer = b, desc = 'Go to definition' })
    map('n', 'gr', vim.lsp.buf.references, { buffer = b, desc = 'References' })
    map('n', 'K', vim.lsp.buf.hover, { buffer = b, desc = 'Hover' })
    map('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = b, desc = 'Code action' })
    map('n', '<leader>rn', vim.lsp.buf.rename, { buffer = b, desc = 'Rename' })
    map('n', '[d', vim.diagnostic.goto_prev, { buffer = b, desc = 'Prev diagnostic' })
    map('n', ']d', vim.diagnostic.goto_next, { buffer = b, desc = 'Next diagnostic' })
  end,
})

-- Plugins
require('lazy').setup({
  defaults = { lazy = true },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },

  -- Colorscheme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'auto',
      background = { light = 'latte', dark = 'mocha' },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      apply_colorscheme(vim.o.background == 'light' and 'light' or 'dark')
    end,
  },
  {
    'f-person/auto-dark-mode.nvim',
    lazy = false,
    priority = 900,
    opts = {
      fallback = 'dark',
      update_interval = 5000,
      set_dark_mode = function() apply_colorscheme 'dark' end,
      set_light_mode = function() apply_colorscheme 'light' end,
    },
  },

  -- Fuzzy finder
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    keys = {
      { '<leader>f', '<cmd>FzfLua files<CR>', desc = 'Find files' },
      { '<leader>g', '<cmd>FzfLua live_grep<CR>', desc = 'Live grep' },
      { '<leader>b', '<cmd>FzfLua buffers<CR>', desc = 'Buffers' },
      { '<leader>h', '<cmd>FzfLua help_tags<CR>', desc = 'Help tags' },
      { '<leader>r', '<cmd>FzfLua oldfiles<CR>', desc = 'Recent files' },
      { '<leader>s', '<cmd>FzfLua lsp_document_symbols<CR>', desc = 'Symbols' },
    },
    opts = {
      'default-title',
      winopts = { preview = { layout = 'vertical' } },
    },
  },

  -- Treesitter (grammar installs, highlighting is built-in on nvim 0.12)
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter',
    opts = {
      ensure_install = {
        'javascript',
        'typescript',
        'tsx',
        'json',
        'html',
        'css',
        'python',
        'lua',
        'bash',
        'markdown',
        'yaml',
        'toml',
      },
    },
  },

  -- Mason (LSP server installer)
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    opts = {},
  },
  {
    'williamboman/mason-lspconfig.nvim',
    event = 'VeryLazy',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = { 'ts_ls', 'pyright', 'lua_ls' },
    },
  },

  -- Autocompletion
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '*',
    opts = {
      keymap = { preset = 'default' },
      sources = { default = { 'lsp', 'path', 'buffer' } },
      appearance = { nerd_font_variant = 'mono' },
    },
  },

  -- Format on save
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    keys = {
      {
        '<leader>cf',
        function() require('conform').format { async = true } end,
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        javascript = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        typescript = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        javascriptreact = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        typescriptreact = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        json = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        css = {
          'biome',
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        html = {
          'prettierd',
          'prettier',
          stop_after_first = true,
        },
        python = { 'ruff_format' },
        lua = { 'stylua' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    },
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = {
      options = {
        theme = 'auto',
        component_separators = '',
        section_separators = '',
      },
    },
  },

  -- Directory explorer
  {
    'stevearc/oil.nvim',
    lazy = false,
    keys = {
      { '-', '<cmd>Oil<CR>', desc = 'Browse parent directory' },
      { '<leader>e', '<cmd>Oil<CR>', desc = 'Browse current file' },
      {
        '<leader>E',
        function() require('oil').open(vim.fn.getcwd()) end,
        desc = 'Browse cwd',
      },
    },
    opts = {
      default_file_explorer = true,
      columns = {},
      view_options = {
        show_hidden = true,
        natural_order = 'fast',
      },
    },
  },

  -- Keymap hints popup
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- Quality of life
  { 'echasnovski/mini.pairs', event = 'InsertEnter', opts = {} },
  { 'echasnovski/mini.surround', event = 'BufReadPost', opts = {} },
  {
    'echasnovski/mini.comment',
    keys = { 'gc', { 'gc', mode = 'v' } },
    opts = {},
  },
  { 'lewis6991/gitsigns.nvim', event = 'BufReadPost', opts = {} },
}, {
  checker = { enabled = false },
  install = { colorscheme = { 'catppuccin' } },
})
