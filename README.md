# kickstart.nvim

This repo started as a fork of `kickstart.nvim`, but it has moved a long way from the original starter.

It is now a small, opinionated Neovim setup built around a simple workflow:

- find files fast
- grep text fast
- make small edits
- format on save

The config lives in a single [`init.lua`](./init.lua) and is tuned more for day-to-day editing with AI assistance than for building a large, highly abstracted Neovim distribution.

## How This Differs From Kickstart

This is no longer a generic starter config.

- no file explorer
- `nvim .` opens into a clean startup screen and sets the working directory
- fuzzy finding and grep are the primary navigation model
- theme switches automatically with system light/dark preference
- plugins are kept fairly small and lazy-loaded
- LSP is deferred until opening supported filetypes

If you want the original Kickstart experience, use upstream Kickstart instead. This repo is now a personal config with a narrower workflow and stronger defaults.

## Current Workflow

Open Neovim, then search for what you want.

- `<leader><space>` or `<leader>f` for project files
- `<leader>g` for project grep
- `<leader>/` for current buffer grep
- `<leader>r` for recent files in the current project
- `<leader>b` for open buffers

There is intentionally no directory browser in the default flow.

When you run `nvim .`, the config changes into that directory and shows a lightweight dashboard instead of opening `netrw` or another explorer. From there, the expectation is that you jump straight into fuzzy search.

## Features

- `fzf-lua` for file search, grep, buffers, recent files, help tags, and symbols
- lightweight custom dashboard instead of a start screen plugin
- `catppuccin` with automatic system light/dark switching
- deferred built-in LSP setup for Lua, Python, JavaScript, and TypeScript
- `blink.cmp` for completion
- `conform.nvim` for format-on-save
- Treesitter grammar management via `nvim-treesitter`
- `lualine`, `which-key`, `gitsigns`, and a small set of `mini.nvim` quality-of-life plugins

## Formatting

Formatting is automatic on save.

Configured formatters:

- JavaScript / TypeScript / JSX / TSX / JSON / CSS: `biome`, then `prettierd`, then `prettier`
- HTML: `prettierd`, then `prettier`
- Python: `ruff_format`
- Lua: `stylua`

## Notes

- this config assumes modern Neovim and leans on the built-in Lua LSP APIs
- external tools such as `git`, `rg`, and language formatters should be installed on the machine
- the repo is intentionally small and easy to read; most behavior is in one file on purpose
