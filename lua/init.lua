-- Entry point. Symlinked to <nvim config dir>/init.lua -- that is
-- $XDG_CONFIG_HOME/nvim, or ~/.config/nvim when the variable is unset. Paths
-- below go through stdpath('config') so they follow it either way.
--
-- Order matters here and has bitten before:
--   1. bootstrap lazy.nvim
--   2. set mapleader     -- before any plugin config() runs
--   3. lazy.setup()      -- plugin config() functions execute here
--   4. source legacy.vim -- the old .vimrc: options and the remaining keymaps
--   5. local AI: find a backend, then set up gen.nvim, minuet and their keymaps
--
-- Step 4 is late because legacy.vim is the older half of the config, and an
-- error raised in it aborts everything after it in this file too.
--
-- See README.md for keybindings.

-- lazy.nvim bootstraps itself on first launch; nothing to install by hand.
-- vim.uv is the current name; vim.loop is the deprecated alias kept for older
-- versions. Worth caring about because CI fails the build on anything written
-- to stderr during startup, and deprecation warnings go to stderr.
local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Must be set before lazy.setup() so plugin config functions that call
-- vim.keymap.set('<leader>...') (telescope, etc.) bind to the right key
-- instead of the default '\' leader. legacy.vim also sets this later, which
-- is now a harmless no-op.
vim.g.mapleader = ' '

-- Disable netrw. nvim-tree owns the file sidebar (<leader>nt) and its docs ask
-- for this explicitly -- with both live, whichever hooks BufEnter first wins
-- when you open a directory. Must be set before lazy.setup(), because netrw's
-- plugin file loads during startup and only checks these at that point.
--
-- What this gives up: :Explore/:Lexplore, and netrw's remote-file handling
-- (`nvim scp://host/path`). `gx` is unaffected -- neovim has had its own since
-- 0.10 and no longer routes it through netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Remote-plugin providers, all optional and none of them used here: every
-- plugin in the list below is lua or vimscript. Left enabled they cost a
-- $PATH probe at startup and three WARNINGs in :checkhealth for tooling this
-- config never calls. The python3 provider is deliberately *not* disabled --
-- pynvim is installed and healthy, so it stays available.
--
-- Note this is the node *provider* (the `neovim` npm package), which is a
-- different thing from needing node at all -- most language servers still
-- install over npm. See the LSP block below.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Local AI: ghost text (minuet) and on-demand edits (gen.nvim), served by
-- whichever local backend is running -- ollama first, then LM Studio. With
-- neither, both plugins stay unloaded and their keymaps are never set: same
-- rule as the language servers below, absent backend, quiet editor. Detection
-- and setup happen at the bottom of this file.
--
-- On ollama, two models, because the two jobs pull in opposite directions:
-- ghost text fires on every pause in insert mode, so it wants the smallest
-- model that still completes sensibly; edits run only when asked and can
-- afford something bigger. qwen2.5-coder because ollama ships its
-- fill-in-the-middle template, so the model sees the code after the cursor.
-- 1.5b is sized for CPU -- no GPU reaches WSL on the box this was written on.
--
-- On LM Studio, one model for both: whatever it serves first, unless named.
-- Loading a second model there means evicting the first, per request.
--
-- Everything is an env var, because the right answer differs per machine.
-- NVIM_AI_BACKEND=ollama|lmstudio skips detection -- useful when the server
-- will be started after nvim -- and NVIM_AI_BACKEND=none turns it all off.
local ai = {
  backend         = vim.env.NVIM_AI_BACKEND,
  host            = vim.env.NVIM_AI_HOST or 'localhost',
  ollama_port     = vim.env.NVIM_AI_OLLAMA_PORT or '11434',
  lmstudio_port   = vim.env.NVIM_AI_LMSTUDIO_PORT or '1234',
  fim_model       = vim.env.NVIM_AI_FIM_MODEL or 'qwen2.5-coder:1.5b',
  edit_model      = vim.env.NVIM_AI_EDIT_MODEL or 'qwen2.5-coder:7b',
  lmstudio_model  = vim.env.NVIM_AI_LMSTUDIO_MODEL,
}

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  'StanAngeloff/php.vim',
  'easymotion/vim-easymotion',
  'ethanmuller/scratch.vim',
  'majutsushi/tagbar',
  'mattn/emmet-vim',
  'morhetz/gruvbox',
  'pangloss/vim-javascript',
  'sheerun/vim-polyglot',
  'tpope/vim-sensible',
  'tpope/vim-surround',
  'tribela/vim-transparent',
  'wuelnerdotexe/vim-astro',
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = { theme = 'gruvbox' },
        sections = {
          -- 'diagnostics' reads vim.diagnostic, so it follows neovim's own LSP
          -- client. This slot called coc#status() until 2026-08; leaving that
          -- in after coc was removed would have thrown E117 on every redraw,
          -- which is how the 2026 statusline bug started the first time.
          lualine_c = { 'filename', 'diagnostics' },
          -- lualine_x gains minuet's request spinner once an AI backend is
          -- found; see the bottom of this file.
        },
      })
    end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function() require('nvim-tree').setup({}) end,
  },
  {
    'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>rr', builtin.current_buffer_tags, {})
    end,
  },
  -- Replaced coc.nvim in 2026-08. lspconfig supplies only the per-server
  -- cmd/filetypes/root-marker data; neovim's own client does the rest, and
  -- wires K, C-] (tagfunc), grr/gri/grn/gra/grt, gO and omnifunc itself when
  -- a client attaches. See `:h lsp-defaults` -- there is nothing to map here.
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Servers are third-party binaries; neovim ships none. This config gets
      -- carried to machines that have none of them installed, so enable only
      -- what is actually present rather than letting nvim try to spawn a
      -- missing command on every matching buffer. Absent server, quiet editor.
      --
      -- Values are the executable to look for -- also the thing to install if
      -- you want that language working on this machine. The npm ones are
      -- `npm i -g typescript-language-server typescript@5`,
      -- `npm i -g vscode-langservers-extracted` (eslint/json/html/css) and
      -- `npm i -g intelephense`; lua-language-server comes from brew or apt.
      --
      -- The `@5` is load-bearing as of 2026: `typescript` latest is now the 7.x
      -- native port, which ships a `tsc` binary and no `lib/tsserver.js`.
      -- typescript-language-server still drives the 5.x javascript tsserver, so
      -- a bare `npm i -g typescript` leaves ts_ls exiting at startup with
      -- "Could not find a valid TypeScript installation" -- and because that
      -- kills the server rather than the editor, it looks like the LSP config
      -- silently doing nothing. Drop the pin once ts_ls speaks to tsgo.
      local servers = {
        ts_ls        = 'typescript-language-server',
        eslint       = 'vscode-eslint-language-server',
        jsonls       = 'vscode-json-language-server',
        html         = 'vscode-html-language-server',
        cssls        = 'vscode-css-language-server',
        intelephense = 'intelephense',
        lua_ls       = 'lua-language-server',
      }
      for server, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
          vim.lsp.enable(server)
        end
      end
    end,
  },
  -- The two AI plugins. lazy = true, so neither loads -- and neither :Gen nor
  -- :Minuet exists -- until the bottom of this file finds a backend and
  -- requires them. Their setup lives down there too, since it depends on
  -- which backend answered.
  { 'milanglacier/minuet-ai.nvim', lazy = true, dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'David-Kunz/gen.nvim', lazy = true },
}, {
  -- lazy.nvim builds a private lua 5.1 + luarocks under stdpath('data') the
  -- first time it wants a rock, and reports the missing interpreter as an
  -- ERROR in :checkhealth until it does. No plugin above needs a rock --
  -- checkhealth says so itself -- so the build never gets triggered and the
  -- error is permanent.
  --
  -- Disabling the feature outright rather than just `hererocks = false`:
  -- the latter only declines to build the private copy, so lazy then hunts
  -- for a *system* luarocks and warns three times when that is missing too.
  -- Set this back to true if a plugin that actually wants a rock is added.
  rocks = { enabled = false },
})

-- The old .vimrc. Everything above is available to it; nothing below runs if
-- it throws.
vim.cmd('source ' .. vim.fn.stdpath('config') .. '/legacy.vim')

-- --- local AI ---------------------------------------------------------------
-- Settings are in the `ai` table near the top. Detection is async: two curls
-- at localhost, where a closed port is refused in a millisecond or two -- but
-- still nothing startup should wait on. The keymaps appear when it resolves,
-- long before fingers get to them.

local function ai_url(port) return 'http://' .. ai.host .. ':' .. port end

-- GET a URL; cb(body) on a 2xx, cb(nil) on anything else, refusal included.
local function probe(url, cb)
  vim.system({ 'curl', '-sf', '-m', '2', url }, { text = true }, function(r)
    vim.schedule(function() cb(r.code == 0 and r.stdout or nil) end)
  end)
end

-- LM Studio's /v1/models lists everything downloaded, including the embedding
-- model it ships with by default, which cannot chat. The first that isn't one.
local function lmstudio_models(body)
  local ok, list = pcall(vim.json.decode, body or '')
  local ids = {}
  if ok and type(list) == 'table' and type(list.data) == 'table' then
    for _, m in ipairs(list.data) do
      if type(m.id) == 'string' and not m.id:find('embed') then table.insert(ids, m.id) end
    end
  end
  return ids
end

-- cb(backend, lmstudio_model), or cb(nil) for none.
local function ai_detect(cb)
  if ai.backend == 'none' or vim.fn.executable('curl') == 0 then return cb(nil) end
  if ai.backend == 'ollama' then return cb('ollama') end
  local function try_lmstudio()
    if ai.backend == 'lmstudio' and ai.lmstudio_model then
      return cb('lmstudio', ai.lmstudio_model)
    end
    probe(ai_url(ai.lmstudio_port) .. '/v1/models', function(body)
      local model = ai.lmstudio_model or lmstudio_models(body)[1]
      if body and model then cb('lmstudio', model) else cb(nil) end
    end)
  end
  if ai.backend == 'lmstudio' then return try_lmstudio() end
  probe(ai_url(ai.ollama_port) .. '/api/tags', function(body)
    if body then cb('ollama') else try_lmstudio() end
  end)
end

local function ai_setup(backend, lmstudio_model)
  local port = backend == 'ollama' and ai.ollama_port or ai.lmstudio_port
  local url = ai_url(port)

  -- Ghost text: a suggestion drawn after the cursor while typing in insert
  -- mode. On ollama it is true fill-in-the-middle against /v1/completions,
  -- which ollama 0.1.x lacks (./setup.sh --check probes for it). On LM Studio it goes through chat instead, which works with whatever
  -- instruct model is loaded -- FIM would need one with a FIM template.
  --
  -- Alt keys because insert mode has nothing free that's easier to reach:
  -- <Tab> belongs to the markdown list mappings in legacy.vim. Not minuet's
  -- default <A-[> for prev, though: a terminal sends Alt-[ as ESC [, which is
  -- also how every arrow and function key starts, so it arrives ambiguous.
  local minuet = {
    n_completions = 1,
    -- Characters of context around the cursor. Small because prompt
    -- processing dominates latency on CPU; raise it on a GPU.
    context_window = 1024,
    request_timeout = 5,
    virtualtext = {
      auto_trigger_ft = { '*' },
      auto_trigger_ignore_ft = { 'TelescopePrompt', 'NvimTree', 'lazy', 'help' },
      keymap = {
        accept         = '<A-l>', -- the whole suggestion
        accept_line    = '<A-j>', -- one line of it
        accept_n_lines = '<A-z>', -- prompts for a count
        prev           = '<A-p>', -- also requests one when none is showing
        next           = '<A-n>',
        dismiss        = '<A-e>',
      },
    },
  }
  -- api_key is the *name* of an env var holding the key. Neither backend
  -- wants one, but minuet refuses to send without it, and TERM is always set.
  if backend == 'ollama' then
    minuet.provider = 'openai_fim_compatible'
    minuet.provider_options = { openai_fim_compatible = {
      api_key = 'TERM', name = 'Ollama', end_point = url .. '/v1/completions',
      model = ai.fim_model,
      -- Stop at the first blank line. Small models don't reliably emit their
      -- end-of-middle token, and without this 1.5b finished the function it
      -- was asked for, then invented two more after it.
      optional = { max_tokens = 64, top_p = 0.9, stop = { '\n\n' } },
    } }
  else
    minuet.provider = 'openai_compatible'
    minuet.provider_options = { openai_compatible = {
      api_key = 'TERM', name = 'LM Studio', end_point = url .. '/v1/chat/completions',
      model = lmstudio_model, stream = true, optional = { max_tokens = 64, top_p = 0.9 },
    } }
  end
  require('minuet').setup(minuet)

  -- minuet arms ghost text per buffer on FileType, which has already fired
  -- for any file named on the command line. Arm those by hand.
  local ignore = minuet.virtualtext.auto_trigger_ignore_ft
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local ft = vim.bo[buf].filetype
    if vim.api.nvim_buf_is_loaded(buf) and ft ~= '' and not vim.tbl_contains(ignore, ft) then
      vim.b[buf].minuet_virtual_text_auto_trigger = true
    end
  end

  -- Edits on demand: select, pick a prompt, get the rewrite back in place.
  -- phi3:medium sat here until 2026-09 without ever having been pulled.
  local gen = {
    model = backend == 'ollama' and ai.edit_model or lmstudio_model,
    host = ai.host,
    port = port,
    -- gen's README still lists "split", but the code dropped it in favour of
    -- these two, and warns "Invalid display mode" on every prompt.
    display_mode = "horizontal-split",
    no_auto_close = true,
    show_prompt = true,
    show_model = true,
  }
  if backend == 'lmstudio' then
    -- gen speaks ollama's /api/chat out of the box, but already parses
    -- OpenAI-style streams, so only the request has to change. Its default
    -- init runs `ollama serve`, which is not the backend here.
    gen.command = function(o)
      return 'curl -q --silent --no-buffer -X POST http://' .. o.host .. ':' .. o.port
        .. '/v1/chat/completions -H "Content-Type: application/json" -d $body'
    end
    gen.init = function() end
    gen.list_models = function(o)
      return lmstudio_models(vim.fn.system({ 'curl', '-sf', ai_url(o.port) .. '/v1/models' }))
    end
  end
  require('gen').setup(gen)

  -- Spinner while a ghost-text request is in flight. On CPU a request can
  -- take a second or two, and without this there is no telling "still
  -- thinking" apart from "nothing to suggest".
  local lualine = require('lualine')
  local statusline = lualine.get_config()
  table.insert(statusline.sections.lualine_x, 1, { require('minuet.lualine'), display_on_idle = false })
  lualine.setup(statusline)

  -- gen.nvim. Note 'x' and not 'v': 'v' is visual *plus select*, and a
  -- select-mode binding is not wanted here -- printable keys there replace
  -- the selection, so the mapping is dead weight at best. This is also why
  -- :checkhealth used to report these overlaps twice, once for `x` and once
  -- for `s`.
  --
  -- The grammar fix lived on <leader><leader>ss until 2026-08. That sat on
  -- top of easymotion, which owns <leader><leader> as its prefix and maps
  -- <leader><leader>s to easymotion-s -- so every visual-mode easymotion-s had
  -- to wait out 'timeoutlen' (1s) while vim checked for a second `s`, and a
  -- fast typist got Gen instead. <leader>g is unmapped, so the whole
  -- <leader>g space is free for gen.nvim.
  --
  -- All but <leader>] act on a visual selection and replace it. gen shows the
  -- output in a split first; `u` undoes a rewrite you don't want.
  vim.keymap.set({ 'n', 'x' }, '<leader>]', ':Gen<CR>')
  vim.keymap.set('x', '<leader>gs', ':Gen Enhance_Grammar_Spelling<CR>')
  vim.keymap.set('x', '<leader>gw', ':Gen Enhance_Wording<CR>')
  vim.keymap.set('x', '<leader>gc', ':Gen Change_Code<CR>') -- asks what to change
  vim.keymap.set('x', '<leader>gr', ':Gen Review_Code<CR>') -- read-only, no replace

  -- Ghost text on and off. Worth having because on CPU the constant requests
  -- are felt, and some files (long prose, anything sensitive) are better
  -- without.
  vim.keymap.set('n', '<leader>ga', ':Minuet virtualtext toggle<CR>')

  ai.active = backend .. ' at ' .. url .. ' (' .. gen.model .. ')'
end

-- Which backend got picked, since with none the only symptom is keys that
-- do nothing. Detection runs once; restart nvim after starting a server.
vim.api.nvim_create_user_command('AIBackend', function()
  print(ai.active or (ai.backend == 'none' and 'none -- NVIM_AI_BACKEND=none')
    or 'none -- no ollama or LM Studio answered at startup; see NVIM_AI_* in init.lua')
end, {})

ai_detect(function(backend, model)
  if backend then ai_setup(backend, model) end
end)
