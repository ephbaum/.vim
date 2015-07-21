
" [Vundle Bundles] "
source ~/.vim/bundles.vim

" [netrw-tree] "
source ~/.vim/netrw-tree.vim

syntax on

set tabstop=2 shiftwidth=2 expandtab autoindent smartindent
set ruler number wrap
set ignorecase
set clipboard=unnamed
set selection=inclusive

colorscheme molokai

set directory=$HOME/.vim/swapfiles//
set backupdir=$HOME/.vim/backupfiles//

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

" Load RainbowParentheses automagically
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

" Sets <Leader> to space bar, who needs it anyway?
let mapleader=" "

" Shift + Enter enters Insert Mode
nnoremap <S-CR> i
" Shift + Enter exits All other modes
inoremap <S-CR> <Esc>
vnoremap <S-CR> <Esc>
cmap <S-CR> <Esc>

" Space + increases window size by 33% | Space - decreases window size by 33% 
nnoremap <silent> <Leader>= :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "vertical resize " . (winwidth(0) * 2/3)<CR>

" Maps plugin functionality to use Leader
nnoremap <Leader>ff :Ag 
nnoremap <silent><Leader>uu :GundoToggle<CR>
nnoremap <silent><Leader>rr :CtrlPBufTag<CR>
nnoremap <silent><Leader>tt :TagbarOpenAutoClose<CR>
nnoremap <silent><Leader>sc :Vscratch<CR>

" Adjust some plugin settings

let g:easytags_async = 1
let g:easytags_file = '~/.vim/.vimtags'

let g:multi_cursor_use_default_mapping=0

let g:multi_cursor_next_key='<C-m>'
let g:multi_cursor_prev_key='<C-n>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'

" Parse *.md as markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
