-- init.lua - minimal, fast neovim config

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
o.shortmess:append 'I'
o.fillchars:append { eob = ' ' }

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

local function is_directory(path)
  local stat = path ~= '' and vim.uv.fs_stat(path) or nil
  return stat and stat.type == 'directory'
end

local function project_root()
  local current = vim.api.nvim_buf_get_name(0)
  local start = current ~= '' and vim.fs.dirname(current) or vim.fn.getcwd()
  local git_dir = vim.fs.find('.git', { path = start, upward = true })[1]
  return git_dir and vim.fs.dirname(git_dir) or vim.fn.getcwd()
end

local function open_project_files()
  require('fzf-lua').files { cwd = project_root() }
end

local function open_project_grep()
  require('fzf-lua').live_grep { cwd = project_root() }
end

local function open_project_recent()
  require('fzf-lua').oldfiles {
    cwd = project_root(),
    cwd_only = true,
  }
end

local function open_buffer_grep()
  require('fzf-lua').grep_curbuf()
end

local function is_blank_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if vim.api.nvim_buf_get_name(buf) ~= '' or vim.bo[buf].buftype ~= '' or vim.bo[buf].modified then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return #lines == 1 and lines[1] == ''
end

local function center_line(text, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', padding) .. text, padding
end

local function left_align_block_line(text, width, block_width)
  local padding = math.max(0, math.floor((width - block_width) / 2))
  return string.rep(' ', padding) .. text, padding
end

local function render_dashboard(buf)
  if not is_blank_buffer(buf) then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local root = project_root()
  local project_name = vim.fn.fnamemodify(root, ':t')
  local project_path = vim.fn.fnamemodify(root, ':~')
  local entries = {
    { text = project_name ~= '' and project_name or 'neovim', hl = 'Title' },
    { text = '' },
    { text = project_path, hl = 'Comment' },
    { text = 'search first, edit fast', hl = 'Comment' },
    { text = '' },
    { text = 'f  project files', align = 'left', key = 'f' },
    { text = 'g  project grep', align = 'left', key = 'g' },
    { text = '/  buffer grep', align = 'left', key = '/' },
    { text = 'r  recent files', align = 'left', key = 'r' },
    { text = 'b  open buffers', align = 'left', key = 'b' },
    { text = 'n  scratch buffer', align = 'left', key = 'n' },
    { text = '?  keymaps', align = 'left', key = '?' },
    { text = 'q  quit', align = 'left', key = 'q' },
    { text = '' },
    { text = '<leader><space> files  <leader>g grep  <leader>/ buffer grep', hl = 'Comment' },
  }

  local saved_window_options = {
    cursorline = vim.wo[win].cursorline,
    list = vim.wo[win].list,
    number = vim.wo[win].number,
    relativenumber = vim.wo[win].relativenumber,
    signcolumn = vim.wo[win].signcolumn,
  }

  local lines = {}
  local highlights = {}
  local command_block_width = 0
  for _, entry in ipairs(entries) do
    if entry.align == 'left' then
      command_block_width = math.max(command_block_width, vim.fn.strdisplaywidth(entry.text))
    end
  end

  local top_padding = math.max(0, math.floor((height - #entries) / 2) - 1)
  for _ = 1, top_padding do
    table.insert(lines, '')
  end

  for index, entry in ipairs(entries) do
    local line, padding
    if entry.align == 'left' then
      line, padding = left_align_block_line(entry.text, width, command_block_width)
    else
      line, padding = center_line(entry.text, width)
    end

    local line_number = #lines
    lines[line_number + 1] = line

    if entry.hl and entry.text ~= '' then
      table.insert(highlights, {
        group = entry.hl,
        line = line_number,
        start_col = padding,
        end_col = padding + #entry.text,
      })
    end

    if entry.key then
      table.insert(highlights, {
        group = 'Keyword',
        line = line_number,
        start_col = padding,
        end_col = padding + #entry.key,
      })
    end
  end

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'starter'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      buf,
      -1,
      highlight.group,
      highlight.line,
      highlight.start_col,
      highlight.end_col
    )
  end

  vim.wo[win].cursorline = false
  vim.wo[win].list = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = user_group,
    buffer = buf,
    once = true,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end

      for option, value in pairs(saved_window_options) do
        vim.wo[win][option] = value
      end
    end,
  })

  local dashboard_opts = { buffer = buf, nowait = true, silent = true }
  map('n', 'f', open_project_files, dashboard_opts)
  map('n', 'g', open_project_grep, dashboard_opts)
  map('n', '/', open_buffer_grep, dashboard_opts)
  map('n', 'r', open_project_recent, dashboard_opts)
  map('n', 'b', function() require('fzf-lua').buffers() end, dashboard_opts)
  map('n', '?', function() require('which-key').show() end, dashboard_opts)
  map('n', 'n', '<cmd>enew<CR>', dashboard_opts)
  map('n', 'q', '<cmd>quit<CR>', dashboard_opts)
end

-- Treat directory edits as "start in this cwd" rather than opening an explorer.
vim.api.nvim_create_autocmd('BufEnter', {
  group = user_group,
  nested = true,
  callback = function(data)
    local directory = vim.api.nvim_buf_get_name(data.buf)
    if not is_directory(directory) then
      return
    end

    vim.cmd.cd(vim.fn.fnamemodify(directory, ':p'))
    vim.cmd.enew()
    local dashboard_buf = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_delete, data.buf, { force = true })
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(dashboard_buf) then
        render_dashboard(dashboard_buf)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  group = user_group,
  nested = true,
  callback = function()
    render_dashboard(vim.api.nvim_get_current_buf())
  end,
})

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
      { '<leader><space>', open_project_files, desc = 'Project files' },
      { '<leader>f', open_project_files, desc = 'Project files' },
      { '<leader>g', open_project_grep, desc = 'Project grep' },
      { '<leader>/', open_buffer_grep, desc = 'Buffer grep' },
      { '<leader>b', function() require('fzf-lua').buffers() end, desc = 'Buffers' },
      { '<leader>h', function() require('fzf-lua').help_tags() end, desc = 'Help tags' },
      { '<leader>r', open_project_recent, desc = 'Recent files' },
      { '<leader>s', function() require('fzf-lua').lsp_document_symbols() end, desc = 'Symbols' },
    },
    opts = {
      'default-title',
      winopts = {
        height = 0.85,
        width = 0.80,
      },
      files = {
        cwd_prompt = false,
        previewer = false,
        prompt = 'Files> ',
        rg_opts = [[--color=never --files -g "!.git" -g "!.jj" -g "!node_modules" -g "!dist" -g "!.next" -g "!coverage"]],
      },
      grep = {
        hidden = true,
        prompt = 'Grep> ',
        input_prompt = 'Pattern> ',
        rg_opts = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g "!.git" -g "!node_modules" -g "!dist" -g "!.next" -g "!coverage" -e]],
        winopts = { preview = { layout = 'vertical' } },
      },
      oldfiles = {
        cwd_only = true,
        include_current_session = true,
        previewer = false,
        prompt = 'Recent> ',
      },
      buffers = {
        previewer = false,
        prompt = 'Buffers> ',
      },
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
