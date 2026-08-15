# .vim

My neovim configuration. The repo is named `.vim` for historical reasons — it
used to *be* `~/.vim`. It now lives at `~/.config/nvim/gitnvim` and is wired
into neovim by two symlinks.

I got tired of relearning how to set this up every time I moved machines, so
the setup steps and the reasoning behind the current layout are written down
here rather than rediscovered.

## Setup

```bash
# 1. config dir
mkdir -p $HOME/.config/nvim && cd $HOME/.config/nvim

# 2. clone as "gitnvim"
git clone git@github.com:ephbaum/.vim.git gitnvim

# 3. state directories — .vimrc points directory= and backupdir= here,
#    and .gitignore expects these exact names
mkdir -p gitnvim/swapfiles gitnvim/backupfiles

# 4. neovim entry point -> lua config
ln -s ~/.config/nvim/gitnvim/lua/init.lua ~/.config/nvim/init.lua

# 5. the old vimscript config, sourced by init.lua
ln -s ~/.config/nvim/gitnvim/.vimrc ~/.config/nvim/legacy.vim
```

Then install vim-plug, which still manages three plugins (see
[Two plugin managers](#two-plugin-managers)):

```bash
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

Launch `nvim` and run `:PlugInstall`. lazy.nvim bootstraps itself on first
start, and coc installs its extensions automatically from
`vim.g.coc_global_extensions`.

### Also worth installing

- **ctags** — Tagbar (`<leader>tt`) and telescope's buffer-tags picker
  (`<leader>rr`) both shell out to it. Use
  [Universal Ctags](https://github.com/universal-ctags/ctags)
  (`sudo apt install universal-ctags`), not Exuberant Ctags, which this README
  recommended for years despite it being unmaintained since 2009.
- **Node.js** — required by coc.nvim.
- **win32yank** — WSL clipboard bridge, see below.
- **[FiraCode](https://github.com/tonsky/FiraCode)** — the font this is tuned
  for. Under WSL, install it on the Windows side and select it in Windows
  Terminal.

![Screenshot of Windows Terminal running NVIM with FiraCode, gruvbox, transparency and scanlines](images/nvim_fira_code_windows_terminal_gruvbox.png)

## Keybindings

Leader is <kbd>Space</kbd>.

### Editing

| Key | Does |
|---|---|
| `<leader>wr` | toggle wrap |
| `<leader>rtw` | strip trailing whitespace in buffer |
| `<leader>l` | delete to start of line, then join down |
| `<leader>dt` | insert current date/time |
| `<leader>sp` / `<leader>nsp` | spellcheck on / off |
| `<S-CR>` | enter insert mode (normal) / leave it (everywhere else) |
| `gcc` / `gc` | toggle comment — line / motion or visual (Comment.nvim) |
| `<Tab>` / `<S-Tab>` | indent / outdent list item (markdown only) |

### Windows and navigation

| Key | Does |
|---|---|
| `<leader>=` / `<leader>-` | widen / narrow window by a third |
| `<leader>+` / `<leader>_` | taller / shorter by a third |
| `<leader>nt` | toggle nvim-tree |
| `<leader>lex` | toggle netrw sidebar (`netrw-tree.vim`) |
| `<leader>tt` | Tagbar |
| `<leader>uu` | Gundo undo tree |
| `<leader>sc` | scratch buffer |

### Find (telescope)

| Key | Does |
|---|---|
| `<leader>ff` | find files |
| `<leader>fg` | live grep (ripgrep) |
| `<leader>rr` | tags in current buffer |

### LSP / coc

| Key | Does |
|---|---|
| `gd` `gy` `gi` `gr` | definition / type / implementation / references |
| `K` | hover docs |
| `[g` `]g` | previous / next diagnostic |
| `<leader>rn` | rename symbol |
| `<leader>f` | format selection |
| `<leader>ac` / `<leader>qf` | code action on buffer / quickfix current line |
| `if` `af` `ic` `ac` | function / class text objects |
| `<leader>a` | code action on motion or selection (e.g. `<leader>aap`) |
| `<C-s>` | expand selection range |
| `<Tab>` / `<S-Tab>` | next / previous completion item |
| `<CR>` | confirm completion |
| `<leader>c` + `a e c o s j k p` | CocList: diagnostics, extensions, commands, outline, symbols, next, prev, resume |

### AI (gen.nvim → local ollama)

| Key | Does |
|---|---|
| `<leader>]` | prompt Gen |
| `<leader><leader>ss` | fix grammar/spelling in selection |

### Two mappings that changed in 2026-08

Both were stale copy-paste from successive versions of coc's example config,
and both were silently broken. Fixed, but they're the kind of thing muscle
memory notices:

- **CocList moved from `<space>x` to `<leader>cx`.** Since leader *is* space,
  those were `<leader>` mappings wearing a disguise: `<space>a` shadowed
  `<leader>a` (code action) completely, and `<space>s` made `<leader>sp` and
  `<leader>sc` wait on timeout. The group now has a prefix of its own.
- **`<CR>` was mapped twice.** An older `complete_info()` recipe sat below the
  modern `coc#pum#confirm()` one and overrode it, so `coc#on_enter()` never
  fired — no format or snippet expansion on confirm. The old block is gone.

## Layout

| File | What it is |
|---|---|
| `lua/init.lua` | entry point — lazy.nvim, plugin list, coc extensions, then sources the other two |
| `.vimrc` | the original vimscript config, symlinked as `legacy.vim`. Options, keymaps, and all the coc boilerplate |
| `bundles.vim` | the three plugins still on vim-plug |
| `netrw-tree.vim` | netrw as a file-tree sidebar, from before nvim-tree |

### Two plugin managers

lazy.nvim manages everything except `vim-misc`, `vim-session`, and `coc.nvim`,
which are still on vim-plug in `bundles.vim`. This is why `:checkhealth` warns
about "paths on the rtp from another plugin manager" — that's expected, not
broken. Folding the last three into lazy.nvim is the obvious next cleanup.

### WSL clipboard

`clipboard+=unnamedplus` alone doesn't reach the Windows clipboard, so
`g:clipboard` is pointed at `win32yank.exe` with `--crlf` on copy and `--lf`
on paste to keep line endings from drifting across the boundary.

## History

Eleven years of moving between machines and rewriting this thing. Sparse
commit messages, so the dates carry most of the story.

| | |
|---|---|
| **2015** | Started on macOS with Vundle. tern, YouCompleteMe, jshint — the pre-LSP JavaScript stack. |
| **2016** | Polyglot arrives and starts absorbing the individual syntax plugins. |
| **2018** | First README. `.vimtags` noticed to be per-machine and, in theory, stopped being tracked. |
| **2020** | Vundle → vim-plug. `.gitignore` gets serious. Ubuntu 20.04 under WSL. |
| **2021–2022** | Manjaro → Ubuntu, another machine migration, several rounds of path fixing (*"Maybe this is the right path forever"*). |
| **2023** | Everything relocates into `$HOME/.config/nvim`. coc.nvim arrives, transparency, astro. |
| **2024** | Lua config: `init.lua` becomes the entry point, `.vimrc` demoted to `legacy.vim`, lazy.nvim and gen.nvim added. Migration deliberately partial. |
| **2026** | Statusline crash fixed, coc actually armed, plugin set modernized. WSL clipboard fixed. |

### 2026-07-04 — the modernization pass

Picked this config up on a new machine and it was silently broken: `nvim`
started, but a big chunk of keybindings just didn't exist.

**The startup bug.** `legacy.vim` had `set statusline^=%{coc#status()}...` —
prepending onto the statusline. vim-airline sets `&statusline` starting with
`%!airline#statusline(1)...`, and `%!` is only legal as the very first two
characters of the option. Prepending in front of it produced `E539: Illegal
character <!>`, a hard error rather than a warning. Because `legacy.vim` is
sourced from `init.lua` via `vim.cmd('source ...')`, that error aborted
execution on the spot — so everything after it in `legacy.vim` (all the coc
keymaps: `gd`, `gr`, `K`, rename, format, code actions, `CocList`) and
everything after it in `init.lua` (coc's own plugin file, the gen.nvim
keymaps) silently never ran. `^=` → `+=` fixed it, and prompted the rest of
this pass.

**coc.nvim had zero extensions.** It was wiring up the completion UI with no
language server behind it — `:CocList extensions` was empty. Now declared in
`lua/init.lua` via `vim.g.coc_global_extensions`, which coc auto-installs from
on startup. (The PHP one is `coc-phpls`, not `coc-intelephense` — it wraps
intelephense but that isn't the package name.)

With coc actually doing diagnostics, `syntastic` (deprecated by its own author
years ago) became redundant and could fight it over the statusline and
loclist. Removed, along with `vim-phpcs` and the `g:syntastic_*` settings.

**Plugin swaps.**

| Was | Now | Behavior change |
|---|---|---|
| `bling/vim-airline` | `lualine.nvim` | statusline only, no keybinding change. Gruvbox theme, coc status as a component. |
| `scrooloose/nerdtree` | `nvim-tree.lua` | `<leader>nt` still toggles, now via `:NvimTreeToggle`. |
| `scrooloose/nerdcommenter` | `Comment.nvim` | **comment toggle is now `gcc` / `gc`.** No custom nerdcommenter binding existed, so this is the one to relearn. |
| `ctrlpvim/ctrlp.vim` | `telescope.nvim` | `<leader>ff`, `<leader>fg`, `<leader>rr`. |

Also pruned as unreachable: `tern_for_vim` and `jshint.vim` (pre-LSP JS,
superseded by coc), the unused colorschemes (`badwolf`, `molokai`,
`vim-vividchalk`, `vim-lucius`), `vim-game-snake`, and two orphaned
`g:easytags_*` settings left over from an even older migration.

**Leader timing.** `mapleader` is now set at the top of `lua/init.lua`, before
`lazy.setup()`. Plugin `config` functions run *during* `lazy.setup()` — if
`mapleader` isn't set by then, `<leader>` silently falls back to `\` and the
keymaps bind to the wrong key with no error. `.vimrc` still sets it too, which
is now a harmless no-op.

### 2026-08-15 — history scrub

Swap files, a ctags index, and netrw bookmarks had been committed years
earlier and carried forward ever since. All removed from history with
`git-filter-repo`; commit SHAs from 2015 onward changed as a result. If you
have an old clone, `git fetch && git reset --hard origin/main` — a `git pull`
would merge the removed files back in.

`.gitignore` was rebuilt in the same pass to actually match where this config
writes, with each entry annotated with the setting that produces it.
