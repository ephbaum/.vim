
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
set encoding=utf-8

colorscheme gruvbox " molokai
set background=dark
set guifont=Source\ Code\ Pro:h13

set directory=$HOME/.vim/swapfiles//
set backupdir=$HOME/.vim/backupfiles//

" Automatically show row and column higlighting
au WinLeave * set nocursorline nocursorcolumn
au InsertEnter * set nocursorline nocursorcolumn
au WinEnter * set cursorline cursorcolumn
au InsertLeave * set cursorline cursorcolumn
set cursorline cursorcolumn

" Sets color for row / column highlighting
" hi CursorLine ctermbg=053 guibg=#5f005f " Good for Molokai
" hi CursorColumn ctermbg=053 guibg=#5f005f " Bad for Gruvbox
" hi CursorLineNr ctermbg=053 ctermfg=219 guibg=#5f005f guibg=#ffafff

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

" Quickly switch from wrap to nowrap and back
nnoremap <silent> <Leader>wr :set invwrap<CR>

" Burn trailing whitespaces with fire
nnoremap <silent> <Leader>rtw :%s/\s\+$//e<CR>

" Kill whitespace to cursor position and then drop a line - REFACTOR FTW!
nnoremap <silent> <Leader>l d^j

" Space + increases window size by 33% | Space - decreases window size by 33%
nnoremap <silent> <Leader>= :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "vertical resize " . (winwidth(0) * 2/3)<CR>
" Do the same but the other direction
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>_ :exe "resize " . (winheight(0) * 2/3)<CR>

" Maps plugin functionality to use Leader
nnoremap <Leader>ff :Ag
nnoremap <silent><Leader>uu :GundoToggle<CR>
nnoremap <silent><Leader>rr :CtrlPBufTag<CR>
nnoremap <silent><Leader>tt :TagbarOpenAutoClose<CR>
nnoremap <silent><Leader>sc :Vscratch<CR>

" Show trailing whitepace and spaces before a tab:
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/ containedin=ALL

" Adjust some plugin settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_html_tidy_exec = 'tidy5'

let g:easytags_async = 1
let g:easytags_file = '~/.vim/.vimtags'

let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_start_key='<F12>'
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

"let g:session_directory = $VIM.'\_vimfiles\sessions'
"let g:session_autoload = 'no'
"let g:session_autosave = 'yes'
"let g:session_persist_colors = 0
"let g:session_command_aliases = 1
"let g:session_autosave_periodic = 1

" Parse *.md as markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" Parse *.ejs as html, it's just easier
autocmd BufNewFile,BufRead *.ejs set filetype=html

autocmd BufNewFile,BufRead *.styl set filetype=sass
