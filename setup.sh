#!/usr/bin/env bash
#
# Set this config up on a new machine, or repair it on an existing one.
#
#   ./setup.sh          install: make state dirs, wire up, check dependencies
#   ./setup.sh --check  verify only, change nothing, non-zero on problems
#   ./setup.sh --force  replace existing files where install would refuse
#
# Idempotent: running it twice is a no-op. Anything it would overwrite gets
# moved aside with a timestamp rather than deleted, unless it already wires
# this repo into neovim.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
# NVIM_CONFIG is computed just after the platform block below, not here: the
# default config directory differs on Windows, so it has to know the platform.

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
  # Git Bash and MSYS2 say MINGW64_NT-10.0-26300, Cygwin says CYGWIN_NT-...
  # All of them drive a *native* nvim.exe, which differs from every case above
  # in two ways that matter here: where it keeps its config, and not having
  # symlinks available without elevation.
  MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
  *) PLATFORM=unknown ;;
esac

# How you install things here, for the hints below.
pkg_hint() {
  case "$PLATFORM" in
    macos) echo "brew install $1" ;;
    windows)
      # winget ids resemble neither the binary nor the brew/apt package name,
      # so hand back the real id -- "winget install ripgrep" resolves to
      # nothing, which is a worse hint than none.
      case "$1" in
        neovim)          echo "winget install Neovim.Neovim" ;;
        git)             echo "winget install Git.Git" ;;
        ripgrep)         echo "winget install BurntSushi.ripgrep.MSVC" ;;
        node)            echo "winget install OpenJS.NodeJS" ;;
        universal-ctags) echo "winget install UniversalCtags.Ctags" ;;
        *)               echo "winget install $1" ;;
      esac
      ;;
    unknown) echo "install $1" ;;
    *) echo "sudo apt install $1 (or your distro's equivalent)" ;;
  esac
}

head_ "Platform"
info "$PLATFORM ($OS)"

# Where neovim keeps its config. XDG_CONFIG_HOME wins everywhere -- neovim
# honours it on all platforms -- but the *fallback* is not $HOME/.config on
# Windows: a native nvim.exe uses %LOCALAPPDATA%\nvim. Assuming the unix
# default made this script insist the repo was in the wrong place while it sat
# in exactly the right one, and then link into a directory nvim never reads.
#
# cygpath turns the Windows value into the /c/... form the comparisons below
# use; it ships with Git Bash, MSYS2 and Cygwin alike, and is absent (and
# unnecessary) everywhere else.
win_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else echo "$1"; fi
}
if [ -n "${XDG_CONFIG_HOME:-}" ]; then
  CONFIG_HOME="$(win_path "$XDG_CONFIG_HOME")"
elif [ "$PLATFORM" = windows ]; then
  CONFIG_HOME="$(win_path "${LOCALAPPDATA:-$HOME/AppData/Local}")"
else
  CONFIG_HOME="$HOME/.config"
fi
NVIM_CONFIG="$CONFIG_HOME/nvim"

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

# --- wiring ---------------------------------------------------------------
# init.lua is the entry point; legacy.vim is the old .vimrc, sourced from it.
# Both go in as symlinks, so editing the repo edits the live config.
#
# Except on Windows, where symlinks are not really available: `ln -s` under
# Git Bash and MSYS2 silently *copies* unless MSYS=winsymlinks:nativestrict is
# set, and a real NTFS symlink needs elevation or Developer Mode even then. So
# the symlink path there leaves copies that go quietly stale the next time this
# repo is pulled -- the failure mode being edits to the repo that change
# nothing -- and a --check that reports a broken link forever, because
# `readlink` on a copy returns nothing. A two-line stub that sources the repo
# file needs no privileges, cannot drift, and says what it is in its first line.
head_ "Wiring"

# What each file gets on Windows. Both resolve through stdpath('config'), the
# same way the repo's own files locate themselves, so no drive letter or user
# name is baked in and XDG_CONFIG_HOME keeps working.
stub_text() {
  case "$1" in
    init.lua)
      echo "-- Stub written by setup.sh: Windows has no symlinks without elevation."
      echo "dofile(vim.fn.stdpath('config') .. '/gitnvim/lua/init.lua')"
      ;;
    legacy.vim)
      echo '" Stub written by setup.sh: Windows has no symlinks without elevation.'
      echo "execute 'source' fnameescape(stdpath('config') . '/gitnvim/.vimrc')"
      ;;
  esac
}

# Is $dst already wired to this repo? A symlink pointing at $src, or -- on
# Windows -- a stub that names the repo directory.
wired() {
  local src="$1" dst="$2"
  if [ "$PLATFORM" = windows ]; then
    [ -f "$dst" ] && grep -q 'gitnvim' "$dst" 2>/dev/null
  else
    [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]
  fi
}

link() {
  local src="$1" dst="$2" name
  name="$(basename "$dst")"
  if wired "$src" "$dst"; then
    if [ "$PLATFORM" = windows ]; then
      ok "$name sources the repo"
    else
      ok "$name -> $src"
    fi
    return
  fi
  if [ "$MODE" = check ]; then
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      bad "$name exists but is not wired to this repo"
    else
      bad "$name missing"
    fi
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$MODE" = force ]; then
      mv "$dst" "$dst.bak.$STAMP"
      info "moved existing $name to $name.bak.$STAMP"
    else
      bad "$name exists and is not the expected wiring; re-run with --force"
      return
    fi
  fi
  mkdir -p "$(dirname "$dst")"
  if [ "$PLATFORM" = windows ]; then
    stub_text "$name" > "$dst" && ok "$name sources the repo (stub -- Windows has no symlinks)"
  else
    ln -s "$src" "$dst" && ok "$name -> $src"
  fi
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
want rg   "telescope live_grep (<leader>fg)"  ripgrep
# node was a `need` until 2026-08, purely because coc.nvim ran on it. Neovim's
# own LSP client replaced coc; node is now only needed for the language
# servers that happen to be npm packages, and those are optional too.
want node "most language servers install over npm"  node

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

# --- language servers -----------------------------------------------------
# All optional. lua/init.lua enables only the servers whose binary is present,
# so a machine with none of them gets a quiet editor rather than errors -- this
# just reports which you have here. Summarised on two lines instead of one
# warning each, because a fresh box legitimately has none.
head_ "Language servers"
have=""
miss=""
for bin in typescript-language-server vscode-eslint-language-server \
           vscode-json-language-server vscode-html-language-server \
           vscode-css-language-server intelephense lua-language-server; do
  if command -v "$bin" >/dev/null 2>&1; then
    have="$have $bin"
  else
    miss="$miss $bin"
  fi
done
if [ -n "$have" ]; then ok "present:$have"; fi
if [ -n "$miss" ]; then info "absent (optional):$miss"; fi

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
  windows)
    # Neovim's own Windows builds ship win32yank.exe next to nvim.exe and pick
    # it up themselves, so this is normally already working -- the one platform
    # here where the clipboard needs nothing installed. Looked for next to the
    # nvim binary as well as on PATH, because that is where it actually lives.
    nvim_bin="$(command -v nvim || true)"
    if command -v win32yank.exe >/dev/null 2>&1 \
       || { [ -n "$nvim_bin" ] && [ -x "$(dirname "$nvim_bin")/win32yank.exe" ]; }; then
      ok "win32yank -- bundled with neovim's Windows build"
    else
      warn "no win32yank found -- :checkhealth provider says what neovim picked"
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
