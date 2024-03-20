
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

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  'StanAngeloff/php.vim',
  'bling/vim-airline',
  'ctrlpvim/ctrlp.vim',
  'easymotion/vim-easymotion',
  'ethanmuller/scratch.vim',
  'johngrib/vim-game-snake',
  'jonathanfilip/vim-lucius',
  'kien/rainbow_parentheses.vim',
  'majutsushi/tagbar',
  'marijnh/tern_for_vim',
  'mattn/emmet-vim',
  'morhetz/gruvbox',
  'pangloss/vim-javascript',
  'rking/ag.vim',
  'scrooloose/nerdcommenter',
  'scrooloose/nerdtree',
  'scrooloose/syntastic',
  'sheerun/vim-polyglot',
  'sjl/badwolf',
  'sjl/gundo.vim',
  'terryma/vim-multiple-cursors',
  'tomasr/molokai',
  'tpope/vim-sensible',
  'tpope/vim-surround',
  'tpope/vim-vividchalk',
  'tribela/vim-transparent',
  'vsushkov/vim-phpcs',
  'walm/jshint.vim',
  'wuelnerdotexe/vim-astro',
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


vim.cmd('source ~/.config/nvim/legacy.vim')
vim.cmd('source ~/.local/share/nvim/plugged/coc.nvim/plugin/coc.vim')

vim.keymap.set({ 'n', 'v' }, '<leader>]', ':Gen<CR>')
vim.keymap.set('v', '<leader><leader>ss', ':Gen Enhance_Grammar_Spelling<CR>')

