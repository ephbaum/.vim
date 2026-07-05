 # .vim (`.vimrc` in `$HOME/.config/nvim/`)

I'm tired of constantly having to remember how to set up and configure vim.

 Updated: 2023-01-01 - I have made some adjustments to try switching to a Lua config. I'm taking small steps and instead of using my `.vimrc` as `init.vim`, I'm linking to `legacy.vim` for the time being, with the plan of gradually bringing the configuration over. I have also added lazy.nvim and gen.nvim.

## 2026-07-04 Modernization

Picked this config back up on a new machine and it was silently broken: `nvim` started, but a big chunk of keybindings just didn't exist. Worth documenting both the bug and the cleanup that followed, since some of it is a real behavior change.

### The startup bug

`legacy.vim` had `set statusline^=%{coc#status()}...` — prepending onto the statusline. vim-airline sets `&statusline` starting with `%!airline#statusline(1)...`, and `%!` is only legal as the very first two characters of the option. Prepending in front of it produced `E539: Illegal character <!>`, which is a hard error, not a warning. Because `legacy.vim` is sourced from `init.lua` via `vim.cmd('source ...')`, that error aborted execution right there — meaning everything after that line in `legacy.vim` (all the coc keymaps: `gd`, `gr`, `K`, rename, format, code actions, `CocList` mappings...) and everything after it in `init.lua` (sourcing coc.vim's own plugin file, the gen.nvim keymaps) silently never ran. `^=` → `+=` fixed it, but it prompted a closer look at the rest of the config.

### coc.nvim had zero extensions installed

Turned out `coc.nvim` was just wiring up the completion UI with no language server or linter behind it at all — `:CocList extensions` was empty. Added a declarative extension list in `lua/init.lua`:

```lua
vim.g.coc_global_extensions = {
  'coc-json', 'coc-tsserver', 'coc-eslint',
  'coc-html', 'coc-css', 'coc-phpls',
}
```

coc auto-installs anything missing from this list on startup — no manual `:CocInstall` needed, and adding a language later is a one-line change. (Note: the PHP extension's npm package is `coc-phpls`, not `coc-intelephense` — it wraps intelephense internally but that's not the package name.)

With coc actually doing diagnostics now, `syntastic` (deprecated by its own author years ago) was redundant and could fight with coc over the statusline/loclist. Removed it, along with `vim-phpcs` (a syntastic-only PHP style integration) and its `g:syntastic_*` settings.

### Plugin swaps (old vimscript → modern Lua)

| Was | Now | Why it's a behavior change |
|---|---|---|
| `bling/vim-airline` | `lualine.nvim` | Statusline only — no keybinding change. Gruvbox-themed, coc status embedded as a component. |
| `scrooloose/nerdtree` | `nvim-tree.lua` | `<leader>nt` still toggles it, just via `:NvimTreeToggle`. |
| `scrooloose/nerdcommenter` | `Comment.nvim` | **Comment toggle is now `gcc` (line) / `gc` (motion or visual selection)** — Comment.nvim's defaults, not nerdcommenter's. No custom nerdcommenter binding existed before, so this is the one to relearn. |
| `ctrlpvim/ctrlp.vim` | `telescope.nvim` | `<leader>ff` = find files, `<leader>fg` = live grep (ripgrep-backed, replaces the ripgrep `:Rg` quickfix command from the ag.vim → ripgrep swap earlier this session), `<leader>rr` = current-buffer tags (uses `ctags`, same as Tagbar). |

Also pruned as dead weight (unreachable from any keymap or the active `gruvbox` colorscheme):
- `marijnh/tern_for_vim`, `walm/jshint.vim` — pre-LSP JS tooling, fully superseded by `coc-tsserver`/`coc-eslint`.
- `sjl/badwolf`, `tomasr/molokai`, `tpope/vim-vividchalk`, `jonathanfilip/vim-lucius` — unused colorschemes.
- `johngrib/vim-game-snake` — a novelty plugin, not doing anything.
- Two orphaned `g:easytags_*` settings in `.vimrc` — `xolox/vim-easytags` isn't in the plugin list at all anymore (an even older, already-completed migration).

### A leader-timing gotcha worth knowing

`mapleader` is now set (`vim.g.mapleader = ' '`) at the *top* of `lua/init.lua`, before `lazy.setup()` runs, not later in `legacy.vim` like before. Plugin `config` functions (telescope's keymaps, for instance) run during `lazy.setup()` — if `mapleader` isn't set yet at that point, `<leader>` silently falls back to the default `\`, and the keymap ends up bound to the wrong key with no error. `legacy.vim` still sets `mapleader` too; that's now a harmless no-op kept for anyone still reading it top-to-bottom.

### Left alone, on purpose

`vim-misc`, `vim-session`, and `coc.nvim` itself are still installed via vim-plug (see `bundles.vim`), not lazy.nvim — that's why `:checkhealth`'s lazy.nvim section flags "paths on the rtp from another plugin manager." Not a bug, just two plugin managers coexisting mid-migration. Folding that trio into lazy.nvim too would be a reasonable future cleanup, but wasn't done in this pass.

This document will just assuming I'm rolling forward forever, check the git history for older configurations. Good luck.

This installation is taking place on Ubuntu 20.04 WSL. I wish it was possible to use Arch under Windows instead :fingers-crossed:

For this iteration, I plan to relocate everything to live within the `$HOME/.config/nvim` folder as it's been long enough that I've put off dealing with this. (I anticipate a file path update will be necessary along with an update to the `README.md`.)

Next, I may attempt to automate this process. :rolling-eyes:

## Initial Commands

1. Create a new config directory and navigate into it:
   ```bash
   mkdir -p $HOME/.config/nvim && cd $HOME/.config/nvim
   ```
2. Clone the repository:
   ```bash
   git clone git@github.com:ephbaum/.vim.git gitnvim
   ```
3. Create necessary directories (`.vimrc` points `directory`/`backupdir` here):
   ```bash
   mkdir -p gitnvim/swapfiles gitnvim/backupfiles
   ```
4. Symlink your `.vimrc` file:
   ```bash
   ln -s ~/.config/nvim/gitnvim/.vimrc ~/.config/nvim/legacy.vim
   ```
5. Symlink your `init.lua` file:
    ```bash
    ln -s ~/.config/nvim/gitnvim/lua/init.lua ~/.config/nvim/init.lua
    ```

## Plugins

Then, follow the Neovim instructions to use [Vim Plug](https://github.com/junegunn/vim-plug):

```bash
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

After launching `nvim`:

```vim
:PlugInstall
```

## After Care

You will want to install [Exuberant CTags](http://ctags.sourceforge.net/) for improved tagging functionality. Under Ubuntu, that's straightforward:

```bash
sudo apt install exuberant-ctags
```

Additionally, consider installing Node.js if needed. Other platforms may vary.

## Powerline Font

Currently, I prefer [FiraCode](https://github.com/tonsky/FiraCode). However, that preference might change later.

Under WSL2, adding this font is now simple using the Microsoft Terminal. It looks particularly impressive with transparency and scanlines enabled:

![Screenshot of Microsoft Terminal window displaying NVIM running with FiraCode and Scanlines](images/nvim_fira_code_windows_terminal_gruvbox.png)
