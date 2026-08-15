#!/usr/bin/env bash
#
# Set this config up on a new machine, or repair it on an existing one.
#
#   ./setup.sh          install: make state dirs, symlink, fetch vim-plug
#   ./setup.sh --check  verify only, change nothing, non-zero on problems
#   ./setup.sh --force  replace existing files where install would refuse
#
# Idempotent: running it twice is a no-op. Anything it would overwrite gets
# moved aside with a timestamp rather than deleted, unless it is already the
# correct symlink.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PLUG_PATH="$NVIM_DATA/site/autoload/plug.vim"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
STAMP="$(date +%Y%m%d%H%M%S)"

MODE=install
for arg in "$@"; do
  case "$arg" in
    --check) MODE=check ;;
    --force) MODE=force ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

problems=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
info() { printf '  \033[34m--\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; problems=$((problems + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# --- where does this repo live -------------------------------------------
# .vimrc and init.lua reference $HOME/.config/nvim/gitnvim by absolute path,
# so a clone anywhere else will half-work in confusing ways.
head_ "Location"
EXPECTED="$NVIM_CONFIG/gitnvim"
if [ "$REPO" = "$EXPECTED" ]; then
  ok "repo is at $REPO"
else
  bad "repo is at $REPO but the config hardcodes $EXPECTED"
  info "clone it there, or update the source lines in .vimrc and lua/init.lua"
fi

# --- state directories ----------------------------------------------------
# Named to match .gitignore. If these move, .gitignore has to move with them.
# backupfiles/ was created here too until 2026-08, for a backupdir that
# nobackup/nowritebackup meant vim never wrote to.
head_ "State directories"
for d in swapfiles; do
  if [ -d "$REPO/$d" ]; then
    ok "$d/"
  elif [ "$MODE" = check ]; then
    bad "$d/ missing (vim will fall back to the cwd for swap files)"
  else
    mkdir -p "$REPO/$d" && ok "$d/ created"
  fi
  if [ -d "$REPO/$d" ] && ! git -C "$REPO" check-ignore -q "$d/probe" 2>/dev/null; then
    bad "$d/ is NOT gitignored -- editor state could be committed"
  fi
done

# --- symlinks -------------------------------------------------------------
# init.lua is the entry point; legacy.vim is the old .vimrc, sourced from it.
head_ "Symlinks"
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "$(basename "$dst") -> $src"
    return
  fi
  if [ "$MODE" = check ]; then
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      bad "$(basename "$dst") exists but does not point at $src"
    else
      bad "$(basename "$dst") missing"
    fi
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$MODE" = force ]; then
      mv "$dst" "$dst.bak.$STAMP"
      info "moved existing $(basename "$dst") to $(basename "$dst").bak.$STAMP"
    else
      bad "$(basename "$dst") exists and is not the expected symlink; re-run with --force"
      return
    fi
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst" && ok "$(basename "$dst") -> $src"
}
link "$REPO/lua/init.lua" "$NVIM_CONFIG/init.lua"
link "$REPO/.vimrc"       "$NVIM_CONFIG/legacy.vim"

# --- vim-plug -------------------------------------------------------------
# Still manages vim-misc, vim-session and coc.nvim; see bundles.vim.
# lazy.nvim bootstraps itself from init.lua and needs nothing here.
head_ "vim-plug"
if [ -s "$PLUG_PATH" ]; then
  ok "installed at $PLUG_PATH"
elif [ "$MODE" = check ]; then
  bad "not installed -- :PlugInstall will fail, and coc.nvim will not load"
else
  mkdir -p "$(dirname "$PLUG_PATH")"
  if curl -fsSLo "$PLUG_PATH" --create-dirs "$PLUG_URL"; then
    ok "downloaded"
  else
    bad "download failed from $PLUG_URL"
  fi
fi

# --- dependencies ---------------------------------------------------------
head_ "Dependencies"
need() {
  local bin="$1" why="$2"
  if command -v "$bin" >/dev/null 2>&1; then ok "$bin -- $why"; else bad "$bin missing -- $why"; fi
}
want() {
  local bin="$1" why="$2"
  if command -v "$bin" >/dev/null 2>&1; then ok "$bin -- $why"; else warn "$bin missing -- $why"; fi
}

need nvim "the editor"
need git  "lazy.nvim and vim-plug both clone over git"
need curl "fetches vim-plug"
need node "coc.nvim runs on it"
want rg   "telescope live_grep (<leader>fg)"

# Tagbar and telescope's buffer-tags picker both shell out to ctags.
# Universal Ctags, not Exuberant, which has been unmaintained since 2009.
if command -v ctags >/dev/null 2>&1; then
  if ctags --version 2>/dev/null | grep -qi universal; then
    ok "ctags (universal) -- <leader>tt and <leader>rr"
  else
    warn "ctags found but not Universal Ctags -- install universal-ctags"
  fi
else
  warn "ctags missing -- <leader>tt and <leader>rr will not work"
fi

# WSL: no clipboard helper to check for. The config sets no g:clipboard, so
# neovim picks a provider on its own -- :checkhealth provider will say which.
if grep -qi microsoft /proc/version 2>/dev/null; then
  info "WSL detected -- run :checkhealth provider if the clipboard misbehaves"
fi

# --- result ---------------------------------------------------------------
head_ "Result"
if [ "$problems" -eq 0 ]; then
  if [ "$MODE" = check ]; then
    echo "  all checks passed"
  else
    echo "  done -- start nvim, then run :PlugInstall"
  fi
  exit 0
fi
echo "  $problems problem(s)"
[ "$MODE" = check ] && echo "  run ./setup.sh to fix what can be fixed automatically"
exit 1
