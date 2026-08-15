" Startup assertions. Run by hand, from the repo, after changing the config or
" setting it up somewhere new:
"
"   nvim --headless -S scripts/check-load-order.vim +qa
"
" Exits non-zero and names what failed. CI does not run this -- it needs a
" full neovim install with every plugin present, which is most of what a CI
" job would be, and this repo decided that job was not worth its weight. Run
" it yourself when nvim starts but feels wrong.
"
" It exists because of the 2026 statusline bug. An E539 raised partway through
" legacy.vim aborted the rest of that file *and* the rest of init.lua, so
" roughly half the keymaps silently ceased to exist. nvim started fine and
" exited 0. Nothing looked wrong.
"
" So rather than checking that startup "worked", each assertion below is a
" tripwire at a different depth of the load order. If one fails, the point at
" which loading gave up is the last one that passed.

let s:failed = 0

function! s:Assert(desc, cond) abort
  if a:cond
    echo '  ok   ' . a:desc
  else
    echohl ErrorMsg | echomsg '  FAIL ' . a:desc | echohl None
    let s:failed += 1
  endif
endfunction

" Does a plain (non-leader) mapping exist?
function! s:Mapped(lhs, mode) abort
  return !empty(maparg(a:lhs, a:mode))
endfunction

" Does a <leader>-prefixed mapping exist? Pass only the part after the
" leader, e.g. s:LeaderMapped('ca', 'n') for <leader>ca.
"
" Editors disagree about whether <Leader> is expanded to its value at
" definition time or stored literally -- vim 9 stores `<leader>ca`, neovim
" resolves it to ` ca`. Rather than depend on either, try every form.
function! s:LeaderMapped(keys, mode) abort
  let l:lead = get(g:, 'mapleader', '\')
  for l:cand in [l:lead . a:keys, '<leader>' . a:keys, '<Leader>' . a:keys]
    if !empty(maparg(l:cand, a:mode))
      return 1
    endif
  endfor
  return 0
endfunction

echo 'Load order tripwires:'

" 1. lazy.nvim ran and its plugin config() functions executed. telescope
"    binds these inside config(), so their absence means lazy.setup() did not
"    finish -- or that mapleader was still '\' when it did.
call s:Assert('lazy: telescope <leader>ff', s:LeaderMapped('ff', 'n'))
call s:Assert('lazy: telescope <leader>fg', s:LeaderMapped('fg', 'n'))

" 2. legacy.vim was reached and its early half ran.
call s:Assert('legacy.vim early: <leader>wr', s:LeaderMapped('wr', 'n'))
call s:Assert('legacy.vim early: <leader>nt', s:LeaderMapped('nt', 'n'))

" 3. legacy.vim ran past its middle -- roughly where E539 hit in 2026.
call s:Assert('legacy.vim mid: <leader>tt (tagbar)', s:LeaderMapped('tt', 'n'))
call s:Assert('legacy.vim mid: mouse=a', &mouse ==# 'a')

" 4. legacy.vim reached its final lines. signcolumn is now the last statement
"    in the file, so this is the strongest single signal that it completed.
"    It was the CocList group until coc was removed in 2026-08.
call s:Assert('legacy.vim end: signcolumn=number', &signcolumn ==# 'number')

" 5. Control returned to init.lua and it finished. These are bound after the
"    source lines, so they only exist if legacy.vim returned cleanly.
call s:Assert('init.lua after source: <leader>]', s:LeaderMapped(']', 'n'))

echo 'Plugins actually loaded:'

" The tripwires above prove which *files* ran. They say nothing about whether
" lazy.nvim's clones succeeded, because every mapping they check is defined by
" this config rather than by a plugin -- <leader>nt is mapped in legacy.vim
" whether or not nvim-tree exists. These check for something only the plugin
" itself can provide.
call s:Assert('nvim-tree (:NvimTreeToggle)', exists(':NvimTreeToggle'))
call s:Assert('Comment.nvim (gcc)', s:Mapped('gcc', 'n'))
call s:Assert('lualine owns the statusline', &statusline =~# 'lualine')
call s:Assert('gen.nvim (:Gen)', exists(':Gen'))

" nvim-lspconfig replaced coc.nvim in 2026-08. This proves lazy cloned it, not
" that any language server is installed -- servers are third-party binaries
" and a machine with none is a supported state, not a failure.
call s:Assert('nvim-lspconfig cloned',
      \ isdirectory(stdpath('data') . '/lazy/nvim-lspconfig'))

echo 'Configuration:'

" mapleader must be set before lazy.setup(), or plugin keymaps bind to '\'.
call s:Assert('mapleader is space', get(g:, 'mapleader', '') ==# ' ')

" <CR> in insert mode should be nothing at all. Two coc mappings fought over
" this slot for years, the older silently overriding the newer; with coc gone
" the correct state is unmapped, and anything here means something re-claimed
" it. Same for <Tab>.
call s:Assert('<CR> unmapped in insert', empty(maparg('<CR>', 'i')))
call s:Assert('<Tab> unmapped in insert', empty(maparg('<Tab>', 'i')))

" State directories exist and are writable, or vim silently drops swap files
" into whatever directory you happened to open.
call s:Assert('swapfiles/ writable', filewritable(expand(&directory[:-3])) == 2)

" netrw is disabled in favour of nvim-tree, and must be set before netrw's
" plugin file loads. Asserted because this config's most reliable behaviour is
" reintroducing something that was already removed once.
call s:Assert('netrw disabled', get(g:, 'loaded_netrw', 0) == 1)
call s:Assert('netrw has no :Lexplore', !exists(':Lexplore'))

if s:failed > 0
  echohl ErrorMsg | echomsg s:failed . ' assertion(s) failed' | echohl None
  cquit 1
endif

echo 'all assertions passed'
