" @SEE https://github.com/junegunn/vim-plug "

" [Vim-Plug Bundles] "
source ./bundles.vim

" [netrw-tree] "
source ./netrw-tree.vim

syntax on

set tabstop=4 shiftwidth=4 expandtab autoindent smartindent
set ruler number wrap
set ignorecase
set clipboard=unnamedplus
set selection=inclusive
set encoding=utf-8

colorscheme gruvbox " molokai
set background=dark
set guifont=Source\ Code\ Pro:h13

set directory=$HOME/.vim/swapfiles//
set backupdir=$HOME/.vim/backupfiles//

" Automatically show row and column higlighting
"au WinLeave * set nocursorline nocursorcolumn
"au InsertEnter * set nocursorline nocursorcolumn
"au WinEnter * set cursorline cursorcolumn
"au InsertLeave * set cursorline cursorcolumn
"set cursorline cursorcolumn

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

" Insert Date/Time
nmap <silent><Leader>dt i<C-R>=strftime("%F %T")<CR><Esc>

" Activate Spell Check for Buffer
nnoremap <silent> <Leader>sp :setlocal spell spelllang=en_us<CR>
" Shut off Spell Check
nnoremap <silent> <Leader>nsp :set nospell<CR>

" Maps plugin functionality to use Leader
nnoremap <Leader>ff :Ag
nnoremap <silent><Leader>uu :GundoToggle<CR>
nnoremap <silent><Leader>rr :CtrlPBufTag<CR>
nnoremap <silent><Leader>tt :TagbarOpenAutoClose<CR>
nnoremap <silent><Leader>sc :Vscratch<CR>
nnoremap <silent><Leader>nt :NERDTreeToggle<CR>

" Show trailing whitepace and spaces before a tab:
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/ containedin=ALL

" Adjust some plugin settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_html_tidy_exec = 'tidy5'
let g:syntastic_php_phpcs_args = "--standard=psr2"

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
let g:session_autoload = 'no'
let g:session_autosave = 'no'
"let g:session_persist_colors = 0
"let g:session_command_aliases = 1
"let g:session_autosave_periodic = 1

" Parse *.md as markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" Parse *.ejs as html, it's just easier
autocmd BufNewFile,BufRead *.ejs set filetype=html

autocmd BufNewFile,BufRead *.styl set filetype=sass

" Because nvim needs special
set mouse=a

" Here's Python
let g:python_host_prog = '/usr/local/bin/python'
let g:python3_host_prog = '/usr/local/bin/python3'


" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings using CoCList:
" Show all diagnostics.
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
