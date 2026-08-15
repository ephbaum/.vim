" legacy.vim -- the original vimscript config, kept whole.
"
" Not loaded by neovim directly. lua/init.lua is the entry point and sources
" this file near the end, after lazy.setup() has run. Two consequences worth
" remembering: anything here runs *after* the lua plugin specs, and an error
" raised here aborts the rest of init.lua too (see the 2026 statusline bug in
" the README).
"
" See README.md for keybindings and the plugin-manager split.

" bundles.vim used to be sourced here -- a vim-plug block holding the three
" plugins the 2024 lua migration left behind. coc.nvim moved to lazy.nvim in
" 2026-08 and the other two were dropped, so vim-plug is gone entirely and
" lazy.nvim in lua/init.lua manages everything.

" netrw-tree.vim used to be sourced here -- netrw dressed up as a file-tree
" sidebar on <Leader>lex, from before nvim-tree. Removed in 2026-08: nvim-tree
" does the job on <Leader>nt, and netrw itself is now disabled outright in
" lua/init.lua. See README for what that costs.

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

" Swap files go inside the repo clone, and the trailing // makes vim encode
" the full path into the filename. The directory is gitignored by name -- if
" this path moves, .gitignore has to move with it. It didn't, once, and swap
" files sat in this repo for seven years.
"
" There is no backupdir counterpart: nobackup and nowritebackup are set in the
" coc section below, so vim never writes a backup to begin with. One used to
" be configured here anyway, along with a backupfiles/ directory that setup.sh
" created and .gitignore guarded, for a path nothing ever wrote to.
" stdpath('config') rather than a literal ~/.config/nvim: setup.sh has always
" honoured XDG_CONFIG_HOME while this line did not, so setting that variable
" made the script install to one place and the config look in another -- while
" reporting all checks passed. `let &directory` rather than `set directory=`
" because the assignment form needs no escaping if the path contains spaces.
let &directory = stdpath('config') . '/gitnvim/swapfiles//'

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

" terryma/vim-multiple-cursors was configured here on <F12>/<C-n>/<C-p>/<C-x>.
" Removed in 2026-08 along with the plugin -- it was deprecated by its own
" author, who points at mg979/vim-visual-multi instead. Nothing replaced it
" yet, so <C-n> and <C-p> are free again.

" xolox/vim-session was configured here, with autoload and autosave both off
" -- so it was two vim-plug plugins (it needs vim-misc) providing a manual
" :SaveSession. Dropped in 2026-08 with vim-plug itself. Vim's own :mksession
" and `nvim -S Session.vim` cover the same ground; Session.vim stays
" gitignored.

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

" Here's Python. g:python_host_prog (python2) was set here until 2026-08 --
" neovim removed the py2 provider entirely, so it did nothing but give
" :checkhealth something to complain about.
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

" `set cmdheight=2` lived here, from the era when coc needed the extra row to
" print messages without triggering a hit-enter prompt. It doesn't any more,
" and the row is better spent on the buffer.

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
"
" <leader>fm, not the <leader>f from coc's example config. Leader-f is
" telescope's prefix here (<leader>ff, <leader>fg in lua/init.lua), so a
" complete mapping on <leader>f alone made both of those wait out 'timeoutlen'
" on every press. No file contained both sides of that, which is why
" check-keymaps.py could not see it until it learned to read the lua half.
" Now nothing maps <leader>f by itself and the whole group is instant.
xmap <leader>fm  <Plug>(coc-format-selected)
nmap <leader>fm  <Plug>(coc-format-selected)

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
