" The last three plugins still on vim-plug. Everything else moved to
" lazy.nvim in lua/init.lua during the 2024 lua migration; these were left
" behind and never followed.
"
" Running both managers is why :checkhealth reports "paths on the rtp from
" another plugin manager" -- expected, not broken. It also means coc's plugin
" file has to be sourced by hand at the end of init.lua.
"
" Requires vim-plug installed separately; see README.md.
call plug#begin()

Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'
Plug 'neoclide/coc.nvim', {'branch': 'release'} " https://github.com/neoclide/coc.nvim

call plug#end()
