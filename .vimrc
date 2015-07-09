syntax on
filetype plugin indent on

set tabstop=2 shiftwidth=2 expandtab autoindent smartindent
set ruler number wrap
set ignorecase
set clipboard=unnamed

" Automatically show row and column higlighting
au WinLeave * set nocursorline nocursorcolumn
au InsertEnter * set nocursorline nocursorcolumn
au WinEnter * set cursorline cursorcolumn
au InsertLeave * set cursorline cursorcolumn
set cursorline cursorcolumn

" Sets color for row / column highlighting
hi CursorLine ctermbg=053 guibg=#5f005f
hi CursorColumn ctermbg=053 guibg=#5f005f
hi CursorLineNr ctermbg=053 ctermfg=219 guibg=#5f005f guibg=#ffafff

" Sets <Leader> to space bar, who needs it anyway?
let mapleader=" "

" Parse *.md as markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
