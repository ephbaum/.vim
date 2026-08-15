-- Entry point. Symlinked to <nvim config dir>/init.lua -- that is
-- $XDG_CONFIG_HOME/nvim, or ~/.config/nvim when the variable is unset. Paths
-- below go through stdpath('config') so they follow it either way.
--
-- Order matters here and has bitten before:
--   1. bootstrap lazy.nvim
--   2. set mapleader     -- before any plugin config() runs
--   3. lazy.setup()      -- plugin config() functions execute here
--   4. source legacy.vim -- the old .vimrc: options and the remaining keymaps
--   5. the gen.nvim keymaps
--
-- Step 4 is late because legacy.vim is the older half of the config, and an
-- error raised in it aborts everything after it in this file too.
--
-- See README.md for keybindings.

-- lazy.nvim bootstraps itself on first launch; nothing to install by hand.
-- vim.uv is the current name; vim.loop is the deprecated alias kept for older
-- versions. Worth caring about because CI fails the build on anything written
-- to stderr during startup, and deprecation warnings go to stderr.
local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
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

-- Must be set before lazy.setup() so plugin config functions that call
-- vim.keymap.set('<leader>...') (telescope, etc.) bind to the right key
-- instead of the default '\' leader. legacy.vim also sets this later, which
-- is now a harmless no-op.
vim.g.mapleader = ' '

-- Disable netrw. nvim-tree owns the file sidebar (<leader>nt) and its docs ask
-- for this explicitly -- with both live, whichever hooks BufEnter first wins
-- when you open a directory. Must be set before lazy.setup(), because netrw's
-- plugin file loads during startup and only checks these at that point.
--
-- What this gives up: :Explore/:Lexplore, and netrw's remote-file handling
-- (`nvim scp://host/path`). `gx` is unaffected -- neovim has had its own since
-- 0.10 and no longer routes it through netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  'StanAngeloff/php.vim',
  'easymotion/vim-easymotion',
  'ethanmuller/scratch.vim',
  'majutsushi/tagbar',
  'mattn/emmet-vim',
  'morhetz/gruvbox',
  'pangloss/vim-javascript',
  'sheerun/vim-polyglot',
  'tpope/vim-sensible',
  'tpope/vim-surround',
  'tribela/vim-transparent',
  'wuelnerdotexe/vim-astro',
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = { theme = 'gruvbox' },
        sections = {
          -- 'diagnostics' reads vim.diagnostic, so it follows neovim's own LSP
          -- client. This slot called coc#status() until 2026-08; leaving that
          -- in after coc was removed would have thrown E117 on every redraw,
          -- which is how the 2026 statusline bug started the first time.
          lualine_c = { 'filename', 'diagnostics' },
        },
      })
    end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function() require('nvim-tree').setup({}) end,
  },
  {
    'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>rr', builtin.current_buffer_tags, {})
    end,
  },
  -- Replaced coc.nvim in 2026-08. lspconfig supplies only the per-server
  -- cmd/filetypes/root-marker data; neovim's own client does the rest, and
  -- wires K, C-] (tagfunc), grr/gri/grn/gra/grt, gO and omnifunc itself when
  -- a client attaches. See `:h lsp-defaults` -- there is nothing to map here.
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Servers are third-party binaries; neovim ships none. This config gets
      -- carried to machines that have none of them installed, so enable only
      -- what is actually present rather than letting nvim try to spawn a
      -- missing command on every matching buffer. Absent server, quiet editor.
      --
      -- Values are the executable to look for -- also the thing to install if
      -- you want that language working on this machine. The npm ones are
      -- `npm i -g typescript-language-server typescript`,
      -- `npm i -g vscode-langservers-extracted` (eslint/json/html/css) and
      -- `npm i -g intelephense`; lua-language-server comes from brew or apt.
      local servers = {
        ts_ls        = 'typescript-language-server',
        eslint       = 'vscode-eslint-language-server',
        jsonls       = 'vscode-json-language-server',
        html         = 'vscode-html-language-server',
        cssls        = 'vscode-css-language-server',
        intelephense = 'intelephense',
        lua_ls       = 'lua-language-server',
      }
      for server, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
          vim.lsp.enable(server)
        end
      end
    end,
  },
  { 'David-Kunz/gen.nvim',
    opts = {
        -- model = "codellama:13b",
        model = "phi3:medium",
        display_mode = "split",
        no_auto_close = true,
        show_prompt = true,
        show_model = true,
    }
  }
})

-- The old .vimrc. Everything above is available to it; nothing below runs if
-- it throws.
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/legacy.vim')

vim.keymap.set({ 'n', 'v' }, '<leader>]', ':Gen<CR>')
vim.keymap.set('v', '<leader><leader>ss', ':Gen Enhance_Grammar_Spelling<CR>')

