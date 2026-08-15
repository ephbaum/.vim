# .vim

My neovim configuration. The repo is named `.vim` for historical reasons — it
used to *be* `~/.vim`. It now lives at `~/.config/nvim/gitnvim` and is wired
into neovim by two symlinks.

I got tired of relearning how to set this up every time I moved machines, so
the setup steps and the reasoning behind the current layout are written down
here rather than rediscovered.

## Setup

```bash
mkdir -p $HOME/.config/nvim && cd $HOME/.config/nvim
git clone git@github.com:ephbaum/.vim.git gitnvim
cd gitnvim && ./setup.sh
```

Then launch `nvim` and wait. lazy.nvim bootstraps itself and installs
everything on first start, and coc installs its extensions from
`vim.g.coc_global_extensions`.

The clone has to be named `gitnvim` and sit inside your neovim config
directory — `$XDG_CONFIG_HOME/nvim`, or `~/.config/nvim` if that variable is
unset. `.vimrc` and `lua/init.lua` locate themselves with `stdpath('config')`,
which is the same thing `setup.sh` computes, so the two agree wherever you put
it. The directory *name* is still fixed, and `setup.sh` refuses to run from
anywhere else rather than half-working.

`setup.sh` creates `swapfiles/`, symlinks `init.lua` and `legacy.vim`, and
checks for `nvim`, `node`, `git`, `ctags` and `ripgrep`. It installs no plugin
manager — lazy.nvim bootstraps itself. It's idempotent — anything it would
overwrite is moved aside with a timestamp instead.

```bash
./setup.sh --check   # verify an existing install, change nothing
./setup.sh --force   # replace files that would otherwise block the install
```

### Also worth knowing

- **ctags** must be
  [Universal Ctags](https://github.com/universal-ctags/ctags)
  (`sudo apt install universal-ctags`), not Exuberant Ctags, which this README
  recommended for years despite it being unmaintained since 2009.
- **[FiraCode](https://github.com/tonsky/FiraCode)** is the font this is tuned
  for. Under WSL, install it on the Windows side and pick it in Windows
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
| `<leader>fm` | format selection |
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

### Mappings that changed in 2026-08

All three came from coc's example config and were quietly broken or in the
way. Fixed, but they're the kind of thing muscle memory notices:

- **CocList moved from `<space>x` to `<leader>cx`.** Since leader *is* space,
  those were `<leader>` mappings wearing a disguise: `<space>a` shadowed
  `<leader>a` (code action) completely, and `<space>s` made `<leader>sp` and
  `<leader>sc` wait on timeout. The group now has a prefix of its own.
- **`<CR>` was mapped twice.** An older `complete_info()` recipe sat below the
  modern `coc#pum#confirm()` one and overrode it, so `coc#on_enter()` never
  fired — no format or snippet expansion on confirm. The old block is gone.
- **Format-selected moved from `<leader>f` to `<leader>fm`.** Leader-f is
  telescope's prefix here, so a complete mapping on `<leader>f` alone made
  `<leader>ff` and `<leader>fg` both wait out `timeoutlen` on every press.

## Layout

| File | What it is |
|---|---|
| `lua/init.lua` | entry point — lazy.nvim, plugin list, coc extensions, then sources `.vimrc` |
| `.vimrc` | the original vimscript config, symlinked as `legacy.vim`. Options, keymaps, and all the coc boilerplate |
| `setup.sh` | install or verify this config on a machine |
| `scripts/` | the checks — `check-keymaps.py` runs in CI, `check-load-order.vim` by hand |

### One plugin manager

lazy.nvim manages everything, coc.nvim included. Two files load, in this
order: `lua/init.lua`, which sources `.vimrc` (as `legacy.vim`) near its end.

The order is load-bearing in two places. `mapleader` and
`coc_global_extensions` are both set *before* `lazy.setup()` — the first so
plugin `config()` functions bind to <kbd>Space</kbd> and not `\`, the second
because that's when coc's plugin file loads and reads it. And `.vimrc` is
sourced *after* `lazy.setup()`, because its coc mappings reference
`<Plug>(coc-*)`, which doesn't exist until coc has loaded.

### Checks

`.github/workflows/ci.yml` runs one job, and every check in it is a regression
test for something that actually went wrong here. That is the bar for adding
another.

| Check | Guards against |
|---|---|
| `shellcheck setup.sh` | `setup.sh` is real bash |
| `scripts/check-keymaps.py` | `<space>a` silently shadowing `<leader>a`, which it did for years |
| no editor state tracked | the swap files and `.vimtags` that got scrubbed from history |
| no absolute `/home/…` paths | those swap files leaked `/Users/<name>/…` |

Because `mapleader` is <kbd>Space</kbd>, every `<space>x` mapping is a
`<leader>x` mapping in disguise, and vim reports nothing when a later mapping
replaces an earlier one — the first simply stops existing. The checker reads
`.vimrc` and `lua/init.lua` both, since a collision can span the two with
neither file showing both sides. It reports prefix ambiguities without
failing; the one it still flags (`<leader>a` vs `<leader>ac`) is coc's own
design, since `<leader>a` takes a motion and has to stay a complete mapping.

Two more checks run **by hand**, not in CI:

```bash
./setup.sh --check                                  # verify an install
nvim --headless -S scripts/check-load-order.vim +qa # verify startup
```

`check-load-order.vim` is the one worth knowing about. The 2026 statusline bug
made nvim exit 0 while half the config silently never ran, so exit codes prove
nothing. It sets tripwires at increasing depths of the load order — lazy's
plugin `config()` functions, early `legacy.vim`, past the statusline region,
the last lines of `legacy.vim`, then back in `init.lua` after the `source` —
plus a group checking that plugins really loaded. When one fails, the last one
that passed is where loading gave up. Run it after changing the config, or on
a new machine.

It ran in CI for about a day. Doing that meant installing neovim, node, ctags
and every plugin on every push, which came to more CI than there is config —
so it went back to being a thing you run when nvim starts but feels wrong.

### WSL clipboard

`.vimrc` sets `clipboard+=unnamedplus` and deliberately declares **no**
`g:clipboard` provider. Neovim picks one itself; under WSL it falls back to
`clip.exe` and powershell. `:checkhealth provider` reports what it chose.

A `win32yank.exe` provider was configured here briefly in 2026 and removed.
It didn't reliably work, and it put a third-party binary in the path of
everything copied out of the editor. If the clipboard isn't crossing into
Windows, fix it on the Windows or WSL side rather than reinstating a helper.

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
| **2026** | Statusline crash fixed, coc actually armed, plugin set modernized. Swap files and a ctags index scrubbed from history. A win32yank clipboard provider added and removed again. netrw retired in favour of nvim-tree. |

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

### 2026-08-15 — the cleanup pass

Picked up the thread from July: keep what earns its keep, delete the rest.

**netrw retired.** `netrw-tree.vim` dressed netrw up as a file-tree sidebar on
`<leader>lex`, and had been redundant since nvim-tree arrived in 2024. Gone,
and netrw is disabled outright in `lua/init.lua` (`g:loaded_netrw`), which is
what nvim-tree's docs ask for — with both live, a directory-open goes to
whichever hooked `BufEnter` first. Costs `:Explore` and `nvim scp://…`; `gx`
is unaffected since neovim stopped routing it through netrw in 0.10. It also
made `<leader>l` faster, which had been a prefix of `<leader>lex` and so sat
out `timeoutlen` on every press.

**vim-plug retired.** The 2024 lua migration left `vim-misc`, `vim-session`
and `coc.nvim` behind in `bundles.vim` and never followed up. coc moved to
lazy.nvim as `{ 'neoclide/coc.nvim', branch = 'release' }` — no lazy-loading
handler on purpose, since it must load during `lazy.setup()` for
`<Plug>(coc-*)` to exist by the time `legacy.vim` maps to it — and
`coc_global_extensions` moved above `lazy.setup()` for the same reason. The
other two were dropped rather than migrated: autoload and autosave were both
`'no'`, so it was two plugins in service of a manual `:SaveSession`, and
`:mksession` covers that. Kills the second plugin manager, the `:checkhealth`
warning about "paths on the rtp from another plugin manager", and a
hand-written `source …/coc.nvim/plugin/coc.vim`.

**Inert config pruned.** `vim-multiple-cursors` (deprecated by its author),
`rainbow_parentheses` (unmaintained a decade, four autocmds per startup),
`g:python_host_prog` (neovim removed the py2 provider), `set cmdheight=2` (coc
stopped needing it), the commented-out cursorline block, and `backupdir` +
`backupfiles/` — that last one the strangest, since `nobackup` and
`nowritebackup` meant nothing was ever written there, yet `setup.sh` created
the directory and `.gitignore` guarded it.

**`<leader>f` → `<leader>fm`** for coc's format-selected. Leader-f is
telescope's prefix, so a complete mapping on `<leader>f` alone made
`<leader>ff` and `<leader>fg` both wait out `timeoutlen`.

**XDG paths.** `setup.sh` honoured `XDG_CONFIG_HOME` while `.vimrc` and
`init.lua` hardcoded `~/.config/nvim`, so setting it installed the config one
place and left nvim looking in another — with `--check` reporting success
throughout. Both go through `stdpath('config')` now.

**CI right-sized.** It briefly grew a smoke job that installed neovim, node,
ctags and every plugin, on both stable and nightly, plus a step that tested
the test harness — roughly more CI than there is config. Cut back to one lint
job where every check is a regression test for something that actually broke
here. `ci-assert.vim` became `scripts/check-load-order.vim` and is run by hand
now; it's still the thing to reach for when nvim starts but feels wrong.

### 2026-08-15 — history scrub

Swap files, a ctags index, and netrw bookmarks had been committed years
earlier and carried forward ever since. All removed from history with
`git-filter-repo`; commit SHAs from 2015 onward changed as a result. If you
have an old clone, `git fetch && git reset --hard origin/main` — a `git pull`
would merge the removed files back in.

`.gitignore` was rebuilt in the same pass to actually match where this config
writes, with each entry annotated with the setting that produces it.
