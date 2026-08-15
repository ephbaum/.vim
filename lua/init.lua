-- Entry point. Symlinked to ~/.config/nvim/init.lua.
--
-- Order matters here and has bitten before:
--   1. bootstrap lazy.nvim
--   2. set mapleader              -- before any plugin config() runs
--   3. set coc_global_extensions  -- before coc's plugin file loads
--   4. lazy.setup()               -- plugin config() functions execute here
--   5. source legacy.vim          -- the old .vimrc, options and coc keymaps
--   6. the gen.nvim keymaps
--
-- Step 5 is late because legacy.vim is the larger, older half of the config.
-- An error raised in it aborts everything after it in this file too. It also
-- has to come after lazy.setup(), because its coc mappings reference
-- <Plug>(coc-*), which only exists once coc's plugin file has run.
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

-- coc installs anything missing from this list on startup, so adding a
-- language is a one-line change and never a manual :CocInstall.
-- PHP is 'coc-phpls' -- it wraps intelephense, but that isn't the package name.
--
-- Must be set before lazy.setup(), because that is where coc's plugin file now
-- loads. It sat after lazy.setup() while coc was on vim-plug and sourced by
-- hand at the end of this file.
vim.g.coc_global_extensions = {
  'coc-json',
  'coc-tsserver',
  'coc-eslint',
  'coc-html',
  'coc-css',
  'coc-phpls',
}

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
  'sjl/gundo.vim',
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
          lualine_c = { 'filename', function() return vim.fn['coc#status']() end },
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
  -- coc.nvim ships built JS on its 'release' branch; there is nothing to
  -- compile. No lazy-loading handler on purpose -- it has to load during
  -- lazy.setup() so <Plug>(coc-*) exists by the time legacy.vim maps to it.
  { 'neoclide/coc.nvim', branch = 'release' },
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
vim.cmd('source ~/.config/nvim/legacy.vim')

vim.keymap.set({ 'n', 'v' }, '<leader>]', ':Gen<CR>')
vim.keymap.set('v', '<leader><leader>ss', ':Gen Enhance_Grammar_Spelling<CR>')

