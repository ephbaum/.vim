#!/usr/bin/env bash
#
# Set this config up on a new machine, or repair it on an existing one.
#
#   ./setup.sh          install: make state dirs, symlink, check dependencies
#   ./setup.sh --check  verify only, change nothing, non-zero on problems
#   ./setup.sh --force  replace existing files where install would refuse
#
# Idempotent: running it twice is a no-op. Anything it would overwrite gets
# moved aside with a timestamp rather than deleted, unless it is already the
# correct symlink.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
STAMP="$(date +%Y%m%d%H%M%S)"

MODE=install
for arg in "$@"; do
  case "$arg" in
    --check) MODE=check ;;
    --force) MODE=force ;;
    # sed -E, because `\?` in a BRE is a GNU extension -- BSD sed on macOS
    # reads it as a literal '?' and leaves the comment markers in the output.
    -h|--help) sed -n '2,12p' "$0" | sed -E 's/^# ?//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

problems=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
info() { printf '  \033[34m--\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; problems=$((problems + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# --- platform -------------------------------------------------------------
# This config is meant to be picked up on whatever machine is in front of you,
# so the checks below adapt instead of assuming Linux. Everything here sticks
# to POSIX-ish shell and bash 3.2, which is what stock macOS still ships.
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then PLATFORM=wsl
    elif [ -n "${WAYLAND_DISPLAY:-}" ]; then               PLATFORM=wayland
    else                                                    PLATFORM=linux
    fi
    ;;
  *) PLATFORM=unknown ;;
esac

# How you install things here, for the hints below.
pkg_hint() {
  case "$PLATFORM" in
    macos) echo "brew install $1" ;;
    unknown) echo "install $1" ;;
    *) echo "sudo apt install $1 (or your distro's equivalent)" ;;
  esac
}

head_ "Platform"
info "$PLATFORM ($OS)"

# --- where does this repo live -------------------------------------------
# .vimrc and init.lua locate themselves via stdpath('config'), which resolves
# to exactly the NVIM_CONFIG below -- XDG_CONFIG_HOME included. The directory
# name is still fixed at gitnvim, so a clone under any other name will
# half-work in confusing ways.
head_ "Location"
EXPECTED="$NVIM_CONFIG/gitnvim"
if [ "$REPO" = "$EXPECTED" ]; then
  ok "repo is at $REPO"
else
  bad "repo is at $REPO but neovim will look in $EXPECTED"
  info "move or re-clone it there -- the directory must be named gitnvim and sit"
  info "inside the nvim config dir, which is where stdpath('config') resolves to"
fi

# --- state directories ----------------------------------------------------
# Named to match .gitignore. If these move, .gitignore has to move with them.
# backupfiles/ was created here too until 2026-08, for a backupdir that
# nobackup/nowritebackup meant vim never wrote to.
head_ "State directories"
# A function rather than a loop: swapfiles/ is the only one left, and SC2043
# rightly objects to iterating over a single constant.
state_dir() {
  local d="$1"
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
}
state_dir swapfiles

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

# There is no plugin-manager step. vim-plug was fetched here until 2026-08,
# when its last three plugins were dropped or moved; lazy.nvim bootstraps
# itself from init.lua on first launch and needs nothing from this script.

# --- dependencies ---------------------------------------------------------
head_ "Dependencies"
# Third argument is the package name when it differs from the binary, so the
# hint says something you can paste on the machine you are actually on.
need() {
  local bin="$1" why="$2" pkg="${3:-$1}"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin -- $why"
  else
    bad "$bin missing -- $why; $(pkg_hint "$pkg")"
  fi
}
want() {
  local bin="$1" why="$2" pkg="${3:-$1}"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin -- $why"
  else
    warn "$bin missing -- $why; $(pkg_hint "$pkg")"
  fi
}

need nvim "the editor"                        neovim
need git  "lazy.nvim clones plugins over git" git
need node "coc.nvim runs on it"               node
want rg   "telescope live_grep (<leader>fg)"  ripgrep

# Tagbar and telescope's buffer-tags picker both shell out to ctags. Universal
# Ctags, not Exuberant, which has been unmaintained since 2009 -- and not the
# BSD ctags macOS ships at /usr/bin/ctags, which is a different program again.
if command -v ctags >/dev/null 2>&1; then
  if ctags --version 2>/dev/null | grep -qi universal; then
    ok "ctags (universal) -- <leader>tt and <leader>rr"
  else
    warn "ctags is not Universal Ctags -- <leader>tt and <leader>rr will misbehave; $(pkg_hint universal-ctags)"
  fi
else
  warn "ctags missing -- <leader>tt and <leader>rr will not work; $(pkg_hint universal-ctags)"
fi

# --- clipboard ------------------------------------------------------------
# .vimrc sets clipboard+=unnamedplus and deliberately declares no g:clipboard,
# so neovim picks a provider itself -- and silently does nothing if it finds
# none. Which tool that is differs per platform, and a yank that quietly fails
# to leave the editor is the single thing most likely to feel broken on a
# machine you just landed on. Warnings, not failures: plenty of boxes are
# headless and the editor is still fine there.
head_ "Clipboard"
case "$PLATFORM" in
  macos)
    if command -v pbcopy >/dev/null 2>&1; then
      ok "pbcopy -- built into macOS"
    else
      warn "no pbcopy, which is surprising on macOS -- :checkhealth provider"
    fi
    ;;
  wsl)
    # Neovim falls back to clip.exe plus powershell.exe, which are on PATH
    # only while Windows interop is enabled.
    if command -v clip.exe >/dev/null 2>&1; then
      ok "clip.exe -- neovim pairs it with powershell.exe to read back"
    else
      warn "WSL but no clip.exe on PATH -- Windows interop looks disabled, yanks will not reach Windows"
    fi
    ;;
  wayland)
    if command -v wl-copy >/dev/null 2>&1; then
      ok "wl-copy -- Wayland"
    else
      warn "Wayland session with no wl-copy -- $(pkg_hint wl-clipboard)"
    fi
    ;;
  linux)
    if command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1; then
      ok "xclip/xsel -- X11"
    else
      warn "no xclip or xsel -- clipboard+=unnamedplus will do nothing; $(pkg_hint xclip)"
    fi
    ;;
  *)
    info "unrecognised platform -- run :checkhealth provider to see what neovim picked"
    ;;
esac

# --- result ---------------------------------------------------------------
head_ "Result"
if [ "$problems" -eq 0 ]; then
  if [ "$MODE" = check ]; then
    echo "  all checks passed"
  else
    echo "  done -- start nvim; lazy.nvim installs everything on first launch"
  fi
  exit 0
fi
echo "  $problems problem(s)"
[ "$MODE" = check ] && echo "  run ./setup.sh to fix what can be fixed automatically"
exit 1
