" legacy.vim -- the original vimscript config, kept whole.
"
" Not loaded by neovim directly. lua/init.lua is the entry point and sources
" this file near the end, after lazy.setup() has run. Two consequences worth
" remembering: anything here runs *after* the lua plugin specs, and an error
" raised here aborts the rest of init.lua too (see the 2026 statusline bug in
" the README).
"
" See README.md for keybindings and the plugin-manager split.

" vim-plug's three holdouts: vim-misc, vim-session, coc.nvim
source ~/.config/nvim/gitnvim/bundles.vim

" netrw configured as a file-tree sidebar, predates nvim-tree
source ~/.config/nvim/gitnvim/netrw-tree.vim

syntax on

set tabstop=4 shiftwidth=4 expandtab autoindent smartindent
set ruler number wrap
set ignorecase
set selection=inclusive
set encoding=utf-8

" No explicit g:clipboard here on purpose. A win32yank.exe provider lived at
" this spot briefly in 2026 and is not coming back -- it didn't reliably work
" and it's a third-party binary sitting in the path of everything you copy,
" which is more trust than a clipboard bridge has earned.
"
" Without a g:clipboard block neovim picks a provider itself; under WSL it
" will use clip.exe and powershell if it finds nothing better. `:checkhealth
" provider` shows what it settled on. If the clipboard isn't crossing into
" Windows, fix it there rather than reinstating a helper binary.
set clipboard+=unnamedplus

colorscheme gruvbox " molokai
set background=dark
set guifont=Fira\ Code\ Pro:h13

" Swap and backup go inside the repo clone, and the trailing // makes vim
" encode the full path into the filename. Both directories are gitignored by
" name -- if either path moves, .gitignore has to move with it. It didn't,
" once, and swap files sat in this repo for seven years.
set directory=$HOME/.config/nvim/gitnvim/swapfiles//
set backupdir=$HOME/.config/nvim/gitnvim/backupfiles//

" Cursor row/column crosshair. Off -- it was noisy and the colors below were
" picked for molokai; CursorColumn in particular reads badly against gruvbox.
"au WinLeave * set nocursorline nocursorcolumn
"au InsertEnter * set nocursorline nocursorcolumn
"au WinEnter * set cursorline cursorcolumn
"au InsertLeave * set cursorline cursorcolumn
"set cursorline cursorcolumn
" hi CursorLine ctermbg=053 guibg=#5f005f " Good for Molokai
" hi CursorColumn ctermbg=053 guibg=#5f005f " Bad for Gruvbox
" hi CursorLineNr ctermbg=053 ctermfg=219 guibg=#5f005f guibg=#ffafff

" Load RainbowParentheses automagically
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

" Sets <Leader> to space bar, who needs it anyway?
" No-op in practice: lua/init.lua sets this before lazy.setup() so plugin
" keymaps bind correctly. Kept so this file still makes sense read alone.
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
nnoremap <silent> <Leader>rtw :%s/\s\+$//e<CR>:noh<CR>

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
" <Leader>ff, <Leader>fg, <Leader>rr are set in lua/init.lua (telescope.nvim)
nnoremap <silent><Leader>uu :GundoToggle<CR>
nnoremap <silent><Leader>tt :TagbarOpenAutoClose<CR>
nnoremap <silent><Leader>sc :Vscratch<CR>
nnoremap <silent><Leader>nt :NvimTreeToggle<CR>

" Show trailing whitepace and spaces before a tab:
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/ containedin=ALL

let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_start_key='<F12>'
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'

" xolox/vim-session. Autoload/autosave off -- :SaveSession and :OpenSession
" still work by hand. session_directory is left unset, so sessions land in
" the plugin default rather than that ancient Windows _vimfiles path.
"let g:session_directory = $VIM.'\_vimfiles\sessions'
let g:session_autoload = 'no'
let g:session_autosave = 'no'
"let g:session_persist_colors = 0
"let g:session_command_aliases = 1
"let g:session_autosave_periodic = 1

" Parse *.md as markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" Markdown Tab and Shift-Tab for lists.
" Replaced a pair of hand-rolled ListIndentForward/Backward functions that
" did the same thing with more regex; see git history if they're ever wanted.
au FileType markdown nnoremap <Tab> >>_
au FileType markdown nnoremap <S-Tab> <<_

" Parse *.ejs as html, it's just easier
autocmd BufNewFile,BufRead *.ejs set filetype=html

autocmd BufNewFile,BufRead *.styl set filetype=sass

" Because nvim needs special
set mouse=a

" Here's Python. python_host_prog points at python2, which no current distro
" ships -- neovim dropped the py2 provider anyway, so it's inert. Harmless
" until `:checkhealth` complains at you about it.
let g:python_host_prog = '/usr/bin/python2'
let g:python3_host_prog = '/usr/bin/python3'

" ---------------------------------------------------------------------------
" coc.nvim
"
" Mostly verbatim from coc's own example config, accumulated across several
" versions of it. Two known snags are flagged inline below.
" ---------------------------------------------------------------------------

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

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()

inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" A second <cr> mapping used to live here -- the older complete_info()/
" pumvisible() recipe from an earlier version of coc's example config. It was
" defined after the coc#pum#confirm() mapping above and silently overrode it,
" so coc#on_enter() never fired and confirm-time formatting and snippet
" expansion were both dead. Removed; the mapping above is now the only one.
" `:verbose imap <CR>` to confirm.

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
" Example: `<leader>aap` for current paragraph.
" This takes a motion, so it needs <leader>a to itself -- the CocList group
" below was moved off <space>a to stop shadowing it.
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

" coc status is surfaced via lualine (see lua/init.lua) instead of a manual
" statusline string; lualine owns &statusline/&laststatus now.

" Mappings using CocList, under a <leader>c prefix.
"
" These came from coc's example config as <space>a, <space>e, <space>c and so
" on. Because mapleader is <space>, every one of them was really a <leader>
" mapping in disguise: <space>a shadowed <leader>a (code action) outright, and
" <space>s made <leader>sp and <leader>sc wait on timeout. Moving the whole
" group under <leader>c gives it a namespace of its own -- c for CocList.
" Show all diagnostics.
nnoremap <silent> <leader>ca  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent> <leader>ce  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent> <leader>cc  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent> <leader>co  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent> <leader>cs  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <leader>cj  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <leader>ck  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent> <leader>cp  :<C-u>CocListResume<CR>
