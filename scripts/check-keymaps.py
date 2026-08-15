#!/usr/bin/env python3
"""Find keymaps in this config that quietly override each other.

mapleader is <space> here, which means every `<space>x` mapping is really a
`<leader>x` mapping in disguise. That is not obvious while reading, and it is
how `<space>a` came to shadow `<leader>a` for years without anyone noticing --
vim reports no error when a later mapping replaces an earlier one, the first
one simply stops existing.

Reports two things:

  collision  two mappings, same mode, same keys. The later one wins and the
             earlier one is dead. Always a bug. Exits non-zero.

  ambiguity  a complete mapping that is also the prefix of a longer one, e.g.
             <leader>a and <leader>ac. Both still work, but the shorter one
             waits out 'timeoutlen' first. Reported, does not fail -- coc's
             own suggested mappings do this deliberately.

Static analysis: it reads the files rather than asking a running vim, so it
does not see mappings from plugins the way :map would. Good enough to catch
the class of bug above without needing nvim and every plugin installed.

Reads both halves of the config. It covered only the vimscript files until
2026-08, which left a real ambiguity invisible: <leader>f (coc
format-selected, .vimrc) is a prefix of <leader>ff and <leader>fg (telescope,
lua/init.lua), and no single file contains both sides of that.
"""

import re
import sys
from collections import defaultdict
from pathlib import Path

# Which concrete modes each :map variant applies to.
MODES = {
    "map": "nvo", "noremap": "nvo",
    "nmap": "n", "nnoremap": "n",
    "imap": "i", "inoremap": "i",
    "vmap": "v", "vnoremap": "v",
    "xmap": "x", "xnoremap": "x",
    "smap": "s", "snoremap": "s",
    "omap": "o", "onoremap": "o",
    "cmap": "c", "cnoremap": "c",
    "tmap": "t", "tnoremap": "t",
}

MAP_ARGS = r"(?:<(?:silent|expr|buffer|unique|nowait|script)>\s*)*"
MAPPING = re.compile(r"(\w+)\s+" + MAP_ARGS + r"(\S+)")

# An :autocmd's own arguments sit in front of the mapping it defines, e.g.
#   au FileType markdown nnoremap <Tab> >>_
# MAPPING anchors on the first word, so it used to read `au` here, find it
# absent from MODES, and skip the line -- the markdown <Tab> mappings were
# invisible until 2026-08. Strip the event and pattern first.
AUTOCMD = re.compile(r"^au(?:t|to|toc|tocm|tocmd)?!?\s+")

# vim.keymap.set('n', '<leader>ff', ...) / vim.keymap.set({'n','v'}, '<leader>]', ...)
LUA_KEYMAP = re.compile(
    r"""vim\.keymap\.set\(\s*
        (\{[^}]*\}|'[^']*'|"[^"]*")   # mode, or a table of modes
        \s*,\s*
        ('[^']*'|"[^"]*")             # lhs
    """,
    re.VERBOSE,
)

VIM_FILES = [".vimrc"]
LUA_FILES = ["lua/init.lua"]
FILES = VIM_FILES + LUA_FILES


def normalise(lhs: str) -> str:
    """Canonical form of a mapping's left-hand side.

    <leader> and <space> are the same key here, and vim treats <CR>/<cr> and
    friends case-insensitively -- so both have to collapse or real collisions
    slip through.
    """
    lhs = re.sub(r"<[Ll]eader>", "<L>", lhs)
    lhs = re.sub(r"<[Ss]pace>", "<L>", lhs)
    lhs = re.sub(r"<([A-Za-z-]+)>", lambda m: "<" + m.group(1).upper() + ">", lhs)
    return lhs


def strip_autocmd(line: str) -> str:
    """`au FileType markdown nnoremap <Tab> >>_` -> `nnoremap <Tab> >>_`.

    Drops the :autocmd keyword, its event list and its file pattern, leaving
    whatever command follows. Lines whose command is not a mapping (`set`,
    `call`, `syn match`) survive this and get filtered out by MODES as usual.
    """
    m = AUTOCMD.match(line)
    if not m:
        return line
    parts = line[m.end():].split(None, 2)
    return parts[2] if len(parts) == 3 else line


def parse_vim(name: str, text: str, found):
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith('"'):
            continue
        m = MAPPING.match(strip_autocmd(line))
        if not m or m.group(1) not in MODES:
            continue
        for mode in MODES[m.group(1)]:
            found[(mode, normalise(m.group(2)))].append((name, lineno, line))


def parse_lua(name: str, text: str, found):
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if line.startswith("--"):
            continue
        m = LUA_KEYMAP.search(line)
        if not m:
            continue
        # Modes are already concrete here, unlike the :map variants. '' is
        # vim.keymap.set's shorthand for the same nvo that :map means.
        modes = "".join(re.findall(r"['\"]([^'\"]*)['\"]", m.group(1))) or "nvo"
        lhs = m.group(2)[1:-1]
        for mode in modes:
            found[(mode, normalise(lhs))].append((name, lineno, line))


def parse(root: Path):
    found = defaultdict(list)
    for name in FILES:
        path = root / name
        if not path.exists():
            continue
        text = path.read_text()
        if name in LUA_FILES:
            parse_lua(name, text, found)
        else:
            parse_vim(name, text, found)
    return found


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    found = parse(root)

    collisions = {k: v for k, v in found.items() if len(v) > 1}
    keys = sorted(found)
    ambiguities = [
        (mode, lhs, sorted({o for (m, o) in keys if m == mode and o != lhs and o.startswith(lhs)}))
        for mode, lhs in keys
    ]
    ambiguities = [a for a in ambiguities if a[2]]

    if collisions:
        print("COLLISIONS -- later mapping wins, earlier one is dead:\n")
        for (mode, lhs), sites in sorted(collisions.items()):
            print(f"  [{mode}] {lhs}")
            for name, lineno, line in sites:
                print(f"        {name}:{lineno}  {line[:78]}")
        print()

    if ambiguities:
        print("Ambiguous prefixes -- shorter mapping waits for 'timeoutlen':\n")
        for mode, lhs, longer in ambiguities:
            print(f"  [{mode}] {lhs:14} -> also a prefix of {', '.join(longer)}")
        print()

    total = sum(len(v) for v in found.values())
    print(f"{total} mappings across {len(FILES)} files, "
          f"{len(collisions)} collision(s), {len(ambiguities)} ambiguity(ies)")
    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
