
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  'StanAngeloff/php.vim',
  'easymotion/vim-easymotion',
  'ethanmuller/scratch.vim',
  'kien/rainbow_parentheses.vim',
  'majutsushi/tagbar',
  'mattn/emmet-vim',
  'morhetz/gruvbox',
  'pangloss/vim-javascript',
  'sheerun/vim-polyglot',
  'sjl/gundo.vim',
  'terryma/vim-multiple-cursors',
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
  { 'David-Kunz/gen.nvim',
    opts = {
        model = "codellama:13b",
        display_mode = "split",
        no_auto_close = true,
        show_prompt = true,
        show_model = true,
    }
  }
})

vim.g.coc_global_extensions = {
  'coc-json',
  'coc-tsserver',
  'coc-eslint',
  'coc-html',
  'coc-css',
  'coc-phpls',
}

vim.cmd('source ~/.config/nvim/legacy.vim')
vim.cmd('source ~/.local/share/nvim/plugged/coc.nvim/plugin/coc.vim')

vim.keymap.set({ 'n', 'v' }, '<leader>]', ':Gen<CR>')
vim.keymap.set('v', '<leader><leader>ss', ':Gen Enhance_Grammar_Spelling<CR>')

