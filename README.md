# .vim

My neovim configuration. The repo is named `.vim` for historical reasons — it
used to *be* `~/.vim`. It now lives at `~/.config/nvim/gitnvim` and is wired
into neovim by two symlinks.

The point of it is that it comes with me: whatever machine I land on and want
to vim around properly, this is the config I pull down. macOS, bare Linux, a
Linux VM, WSL2. None of that was designed — it accreted across a decade of
moving between machines, from vim to neovim and through several plugin
managers — but portability is what it's *for*, so anything that only works on
one platform is a bug here.

I got tired of relearning how to set this up every time I moved, so the setup
steps and the reasoning behind the current layout are written down rather than
rediscovered.

## Setup

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
git clone https://github.com/ephbaum/.vim.git gitnvim   # or git@github.com:… if keys are set up
cd gitnvim && ./setup.sh
```

HTTPS first on purpose — on a machine you just got to, SSH keys are often the
thing you haven't done yet.

Then launch `nvim` and wait — lazy.nvim bootstraps itself and installs
everything on first start. Nothing else is fetched: language servers are
optional and installed per machine, if at all.

The clone has to be named `gitnvim` and sit inside your neovim config
directory — `$XDG_CONFIG_HOME/nvim`, or `~/.config/nvim` if that variable is
unset. `.vimrc` and `lua/init.lua` locate themselves with `stdpath('config')`,
which is the same thing `setup.sh` computes, so the two agree wherever you put
it. The directory *name* is still fixed, and `setup.sh` refuses to run from
anywhere else rather than half-working.

`setup.sh` creates `swapfiles/`, symlinks `init.lua` and `legacy.vim`, and
checks for `nvim` and `git`, then reports on the optional pieces — `node`,
`ctags`, `ripgrep`, a working clipboard provider, and which language servers
are on this machine. It installs no plugin manager — lazy.nvim bootstraps itself. It's
idempotent — anything it would overwrite is moved aside with a timestamp
instead.

It detects the platform first and adapts: install hints come out as `brew` on
macOS and `apt` elsewhere, and the clipboard check looks for the right tool
rather than assuming one. The script itself sticks to bash 3.2 and POSIX-ish
flags, because stock macOS still ships bash 3.2 and BSD `sed` is not GNU
`sed`.

```bash
./setup.sh --check   # verify an existing install, change nothing
./setup.sh --force   # replace files that would otherwise block the install
```

### Per-platform

`./setup.sh --check` tells you which of these you're missing on the machine
you're on; this is what it's checking against.

| | clipboard | ctags |
|---|---|---|
| **macOS** | `pbcopy` — built in | `brew install universal-ctags` (`/usr/bin/ctags` is BSD ctags, a different program) |
| **Linux / X11** | `xclip` or `xsel` | `sudo apt install universal-ctags` |
| **Linux / Wayland** | `wl-clipboard` | as above |
| **WSL2** | `clip.exe` + `powershell.exe`, on PATH only while Windows interop is on | as above |

Without a clipboard provider, `clipboard+=unnamedplus` silently does nothing
and yanks never leave the editor — `:checkhealth provider` says what neovim
settled on.

**ctags** must be [Universal Ctags](https://github.com/universal-ctags/ctags),
not Exuberant Ctags, which this README recommended for years despite it being
unmaintained since 2009.

Installing it is not always enough. On Debian/Ubuntu `/usr/bin/ctags` is an
`update-alternatives` symlink, and if `exuberant-ctags` is already installed it
keeps the link — so `apt install universal-ctags` succeeds, `ctags-universal`
appears next to it, and `ctags` still runs the 2009 one. Nothing errors; you
just keep the old binary. `./setup.sh --check` reports the flavour rather than
mere presence, which is the point. To switch:

```bash
sudo update-alternatives --set ctags /usr/bin/ctags-universal
```

**[FiraCode](https://github.com/tonsky/FiraCode)** is the font this is tuned
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
| `<leader>sc` | scratch buffer |

### Find (telescope)

| Key | Does |
|---|---|
| `<leader>ff` | find files |
| `<leader>fg` | live grep (ripgrep) |
| `<leader>rr` | tags in current buffer |

### LSP

Neovim's own client. These are **its** defaults, not mappings from this config
— they appear whenever a language server attaches and vanish quietly when none
is running. `:h lsp-defaults`.

| Key | Does |
|---|---|
| `K` | hover docs |
| `C-]` | go to definition (via `tagfunc`, so it falls back to ctags with no server) |
| `grr` `gri` `grt` | references / implementation / type definition |
| `grn` / `gra` | rename / code action |
| `gO` | document symbols |
| `C-x C-o` | completion (`omnifunc`); `C-n` for plain buffer words |
| `[d` `]d` | previous / next diagnostic |

Servers are third-party binaries and neovim ships none. `lua/init.lua` enables
only the ones whose executable is present, so a machine with none installed
gets a quiet editor rather than an error on every buffer — and `./setup.sh
--check` lists which you have. That is the trade against coc.nvim, which
auto-installed six of them over npm on first launch but made `node` mandatory
everywhere.

Install commands are in the LSP block of `lua/init.lua`, next to the server
list. One trap is worth repeating here: install TypeScript as
`typescript@5`, not `typescript`. Since 7.x that package is the native port,
which ships no `lib/tsserver.js`, and `typescript-language-server` still drives
the 5.x one — with the unpinned version it starts, fails to initialise and
exits, which reads as the LSP config doing nothing at all.

### AI (gen.nvim → local ollama)

| Key | Does |
|---|---|
| `<leader>]` | prompt Gen |
| `<leader>gs` | fix grammar/spelling in selection |

### What muscle memory will miss

coc.nvim went in 2026-08 and took its whole keymap surface with it. If your
fingers reach for one of these, this is where it went:

| Was | Now |
|---|---|
| `<Tab>` / `<CR>` in insert | plain Tab and Enter. Completion is `C-x C-o`, or `C-n` for buffer words |
| `gd` `gy` `gi` `gr` | `C-]`, `grt`, `gri`, `grr` — neovim's defaults |
| `<leader>rn` / `<leader>fm` | `grn` / `gra` (code action includes formatting) |
| `<leader>a` `<leader>ac` `<leader>qf` | `gra` |
| `<leader>c` + `a e c o s j k p` (CocList) | `gO` for symbols; `:lua vim.diagnostic.setqflist()` for the rest |
| `<leader>uu` (Gundo) | gone — it needed Python 2, which neovim removed |

## Layout

| File | What it is |
|---|---|
| `lua/init.lua` | entry point — lazy.nvim, plugin list, LSP servers, then sources `.vimrc` |
| `.vimrc` | the original vimscript config, symlinked as `legacy.vim`. Options and keymaps |
| `setup.sh` | install or verify this config on a machine |
| `scripts/` | the checks — `check-keymaps.py` runs in CI, `check-load-order.vim` by hand |

### One plugin manager

lazy.nvim manages everything. Two files load, in this order: `lua/init.lua`,
which sources `.vimrc` (as `legacy.vim`) near its end.

One bit of order is load-bearing: `mapleader` is set *before* `lazy.setup()`,
so plugin `config()` functions bind to <kbd>Space</kbd> and not `\`. Getting
that wrong produces no error, just keymaps on the wrong key.

### Checks

`.github/workflows/ci.yml` runs two jobs. Everything in them is either a
regression test for something that actually went wrong here, or a check on the
one property this repo exists for — that it works on a machine I'm not
currently sitting at. That's the bar for adding a third.

**lint**, on Linux:

| Check | Guards against |
|---|---|
| `shellcheck setup.sh` | `setup.sh` is real bash |
| `scripts/check-keymaps.py` | `<space>a` silently shadowing `<leader>a`, which it did for years |
| no editor state tracked | the swap files and `.vimtags` that got scrubbed from history |
| no absolute `/home/…` paths | those swap files leaked `/Users/<name>/…` |

**setup**, on `ubuntu-latest` *and* `macos-latest`: runs `./setup.sh`, then
`./setup.sh --check` to make it verify its own work, then checks that
`--help` renders. It installs no plugins and never starts nvim — that isn't
what it's for. It's there because macOS is where portability breaks: stock
bash is 3.2, `sed` is BSD, and `ctags` is a different program. Whether the
script survives that is the one thing I can't check from whichever machine
I happen to be on.

Because `mapleader` is <kbd>Space</kbd>, every `<space>x` mapping is a
`<leader>x` mapping in disguise, and vim reports nothing when a later mapping
replaces an earlier one — the first simply stops existing. The checker reads
`.vimrc` and `lua/init.lua` both, since a collision can span the two with
neither file showing both sides. It reports prefix ambiguities without
failing. It reports none at the moment — the last one belonged to coc, and
went with it.

It reads the files rather than asking a running vim, which keeps it cheap but
leaves one blind spot worth knowing: **it cannot see mappings owned by
plugins.** In 2026-08 `<leader><leader>ss` (gen.nvim) sat directly on top of
easymotion's `<leader><leader>` prefix, and the checker called it clean —
easymotion's half of the collision lives in the plugin, not in either file it
reads. `:checkhealth which-key` does see it, because it asks the running
editor. The two are complementary: the checker catches what CI can catch
without installing anything, which is why it's the one in CI.

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
| **2026** | Statusline crash fixed, plugin set modernized, swap files and a ctags index scrubbed from history. Then a long cleanup: netrw, vim-plug, gundo and finally coc.nvim all retired, and the config made to actually work on macOS as well as Linux. Finished by getting `:checkhealth` down to a clean report, so the next real problem has somewhere to show up. |

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

**coc.nvim retired.** It was 174 of `.vimrc`'s 320 lines — more than half the
file, copied from coc's example config across several versions of it — and the
only reason `node` was a hard requirement. On every new machine it fetched six
language servers from npm before the editor was useful, which is the opposite
of what this repo is for.

Neovim's own LSP client replaced it. `nvim-lspconfig` supplies the per-server
data; neovim wires `K`, `C-]`, `grr`/`gri`/`grn`/`gra`, `gO` and `omnifunc`
itself when a client attaches, so there are no mappings to write. The trade is
real and worth stating: coc auto-provisioned its servers, and built-in LSP does
not — servers are third-party binaries installed per machine. So `init.lua`
enables only the ones whose executable is actually present, which makes a
machine with none of them a *quiet* machine rather than a broken one. That
failure mode is the whole reason for the swap.

`.vimrc` went 320 → 178 lines, `node` became optional, and the keymap checker
went from 61 mappings with one ambiguity to 25 with none.

Worth recording: `lualine`'s config still fed `coc#status()` into the
statusline. Left in, that is `E117` on every redraw — the same shape as the
2026 statusline crash that started all of this. It now shows `vim.diagnostic`
instead.

**CI right-sized, then re-aimed.** It briefly grew a smoke job that installed
neovim, node, ctags and every plugin, on both stable and nightly, plus a step
that tested the test harness — roughly more CI than there is config. Cut back
to lint, then given one job that earns its place: `setup.sh` on macOS as well
as Linux. Testing that nvim boots on Ubuntu was never the question; whether
this installs on a machine I'm not sitting at is. `ci-assert.vim` became
`scripts/check-load-order.vim` and is run by hand now — still the thing to
reach for when nvim starts but feels wrong.

**Portability fixes**, once the actual goal got stated out loud:

- `g:python3_host_prog` pointed at a literal `/usr/bin/python3` — the Xcode CLT
  stub on macOS, the wrong interpreter under pyenv or asdf. Gone; neovim finds
  python on PATH by itself.
- `gundo.vim` (`<leader>uu`) requires Python 2.4+ and mirrors an abandoned
  bitbucket project. Neovim removed the py2 provider, so the mapping had been
  dead without ever saying so. Dropped — `:undolist` and persistent undo cover
  most of it, and `simnalamburt/vim-mundo` is the py3 fork if the tree is
  missed.
- `setup.sh --help` used `sed 's/^# \?//'`, and `\?` in a BRE is a GNU
  extension — BSD sed on macOS reads it as a literal `?` and leaves the
  comment markers in. Now `sed -E`.
- `setup.sh` detects the platform and checks for the right **clipboard**
  provider, which nothing did before. A yank that silently fails to leave the
  editor is the most "this is broken" thing on a new machine, and
  `clipboard+=unnamedplus` does exactly that with no provider installed.
- Install hints are now `brew` on macOS and `apt` elsewhere, and the ctags
  check says why `/usr/bin/ctags` on a Mac isn't the one you want.
- The README's clone line leads with HTTPS, since SSH keys are usually the
  thing you haven't set up yet on a machine you just got to.

### 2026-08-16 — the checkhealth pass

Pulled the cleanup pass down onto the WSL machine and the config felt broken.
It wasn't — `nvim` started clean and exited 0 — but `:checkhealth` reported one
error and eight warnings, and the one thing actually missing was buried in
them. Most of this pass is deleting noise so the real signal is visible.

**The one that mattered: `ts_ls` was dying silently.** Native LSP needs server
binaries and this machine had none of the seven, which the config handles by
design — absent server, quiet editor. Installing them per the note in
`init.lua` still left TypeScript dead, because `npm i -g typescript` now
resolves to **7.x, the native port**, which ships a `tsc` binary and no
`lib/tsserver.js`. `typescript-language-server` drives the 5.x javascript
tsserver, so it started, failed `initialize`, and exited. The *server* dies
rather than the editor, so there is no error to see — it reads as the LSP
config doing nothing at all. Install hint is pinned to `typescript@5` now, in
both `init.lua` and the LSP section above. Drop the pin once ts_ls speaks to
tsgo.

Worth stating because it generalises: `:checkhealth vim.lsp` reported ✅
throughout. It lists *enabled configurations*, not clients that survived
startup. The only reliable check is opening a real file and asking whether a
client attached and returned a diagnostic.

**Noise removed.**

- **lazy `rocks` disabled.** lazy builds a private lua5.1 + luarocks the first
  time a plugin wants a rock; no plugin here does, so it never builds and the
  missing interpreter is a permanent ERROR. `hererocks = false` is *not* the
  fix — lazy then hunts for a system luarocks and warns three times instead.
  `rocks = { enabled = false }` retires the whole section.
- **node, perl and ruby providers disabled.** Every plugin here is lua or
  vimscript, so these were three warnings for tooling nothing calls. python3
  stays enabled — pynvim is installed and working. Note this is the node
  *provider*, unrelated to needing node for npm-installed servers.
- `mini.icons` is left warning on purpose. `nvim-web-devicons` is installed and
  which-key's own health text says not to report it.

**`<leader><leader>ss` → `<leader>gs`**, and `'v'` → `'x'`. Easymotion owns
`<leader><leader>` and maps `<leader><leader>s`, so the old key made
visual-mode easymotion-s wait out `timeoutlen` on every press, and a fast
typist got Gen instead — the same class of bug as `<leader>f` in July, and the
second time a prefix collision has been found by reading a health report rather
than by noticing the lag. `'v'` also meant select mode, where a printable-key
mapping is dead weight. The keymap checker did not catch this one; see
**Checks** above for why.

**ctags, again.** `universal-ctags` was installed but `/usr/bin/ctags` still
ran Exuberant 5.9 — `update-alternatives` keeps the incumbent. Documented under
Per-platform. `setup.sh --check` already reported the flavour correctly, which
is how it surfaced.

**A stale assertion.** `check-load-order.vim` asserted `<Tab>` was *unmapped*
in insert — correct when it was written against coc, wrong since neovim 0.11
started mapping `<Tab>` itself to jump an active snippet (it falls through to a
literal `<Tab>` otherwise). So the one check meant to be run on a new machine
greeted you with a failure that wasn't one, which is the fastest way to teach
yourself to ignore it. Now it allows neovim's own default through and still
fails when a completion plugin claims the key — verified both ways rather than
just the passing one.

**coc leftovers.** `~/.config/coc` survived the migration at 254 MB of
extension `node_modules`. Nothing reads it. Removed. There was no
`coc-settings.json` anywhere on the system, so nothing hand-tuned was lost when
coc went — the `vim.lsp.enable()` gating in `init.lua` is the entire
configuration surface now.

### 2026-08-15 — history scrub

Swap files, a ctags index, and netrw bookmarks had been committed years
earlier and carried forward ever since. All removed from history with
`git-filter-repo`; commit SHAs from 2015 onward changed as a result. If you
have an old clone, `git fetch && git reset --hard origin/main` — a `git pull`
would merge the removed files back in.

`.gitignore` was rebuilt in the same pass to actually match where this config
writes, with each entry annotated with the setting that produces it.
