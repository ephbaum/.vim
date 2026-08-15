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
" plugins the 2024 lua migration left behind. All three are gone as of 2026-08
" (coc.nvim included), so vim-plug went with them and lazy.nvim in
" lua/init.lua manages everything.

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
" There is no backupdir counterpart: nobackup and nowritebackup are set at the
" end of this file, so vim never writes a backup to begin with. One used to
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
" <Leader>uu was :GundoToggle. gundo.vim requires Python 2.4+ and is a mirror
" of an abandoned bitbucket project; neovim removed the py2 provider, so the
" mapping had been dead for some time without ever saying so. Dropped in
" 2026-08 rather than swapped -- neovim has persistent undo and :undolist.
" simnalamburt/vim-mundo is the maintained py3 fork if the tree is missed.
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

" No python_host_prog or python3_host_prog. Both were set here until 2026-08:
" the py2 one for a provider neovim removed outright, and the py3 one pinned
" to a literal /usr/bin/python3 -- which is the Xcode CLT stub on macOS and
" the wrong interpreter on any pyenv or asdf setup. Neovim finds python3 on
" PATH by itself, and pinning it to one without pynvim is worse than leaving
" it alone. This config gets carried between machines; it should not name
" their filesystems.

" ---------------------------------------------------------------------------
" Completion and diagnostics
"
" coc.nvim lived from here to the end of this file until 2026-08 -- 174 lines,
" more than half of it, all copied from coc's own example config across
" several versions of it. It went because it was the only reason node was a
" hard requirement and because it fetched six language servers from npm on
" first launch of every new machine, which is the opposite of what this repo
" is for.
"
" Neovim's own LSP client replaces it, enabled from lua/init.lua for whichever
" servers are actually installed here. Nothing to map: neovim wires K, C-]
" (via tagfunc), grr/gri/grn/gra/grt, gO, and omnifunc itself when a client
" attaches. `:h lsp-defaults` lists them.
"
" Gone with it, if muscle memory goes looking: <Tab> and <CR> are plain <Tab>
" and <CR> again -- completion is <C-x><C-o> (LSP) or <C-n> (buffer words) --
" along with gd/gy/gi/gr, <leader>rn, <leader>fm, <leader>a, <leader>ac,
" <leader>qf and the <leader>c CocList group.
" ---------------------------------------------------------------------------

" Kept from the coc block because they are not really about coc:
"
" nobackup/nowritebackup were set for language servers that choke on backup
" files, and are also what makes the backupfiles/ entries in .gitignore moot.
set nobackup
set nowritebackup

" Quieter ins-completion, which matters more now that completion is manual.
set shortmess+=c

" Always show the signcolumn so diagnostics appearing do not shift the text.
set signcolumn=number
