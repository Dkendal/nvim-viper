local fzf = require 'fzf'
local a = require 'async'
local async, await, main = a.sync, a.wait, a.main
local fn, api, cmd = vim.fn, vim.api, vim.cmd
local format = string.format

local active = false
local source_bufnr
local source_winid

-- @alias Buffer number

local function inspect(...)
  print(unpack(vim.tbl_map(vim.inspect, { ... })))
end

local function t(keys)
  return api.nvim_replace_termcodes(keys, true, true, true)
end

local Mod = {}

local registry = {}

function Mod.buf_call(buffer, mode, lhs, args)
  registry[buffer][mode][lhs](args)
end

local function curr_line(lines)
  local match_count = '(%d)/%d'
  local current = '>%s+(.*)'

  for _, value in ipairs(lines) do
    local curr_match = string.match(value, current)

    if string.match(value, match_count) then
      break
    end

    if curr_match then
      return curr_match
    end
  end
end

local function curr_line_buf(lines)
  return string.match(curr_line(lines) or '', '(%d+).*')
end

local function buf_set_keymap(buffer, mode, lhs, rhs, opts)
  if type(rhs) == 'string' then
    api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
    return
  end

  local t_lhs = t(lhs)
  registry[buffer] = registry[buffer] or {}
  registry[buffer][mode] = registry[buffer][mode] or {}
  registry[buffer][mode][t_lhs] = rhs
  rhs = format([[<CMD>lua require("viper").buf_call(%d, "%s", "%s", {})<CR>]], buffer, mode, t_lhs)
  api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
end

local function apply_keymap(bufnr)
  buf_set_keymap(bufnr, 't', '<ESC>', '<C-c>', {})

  -- buf_set_keymap(bufnr, 't', '<C-k>', function() return end, {})

  -- Release refs to buffer maps
  api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      registry[bufnr] = nil
    end
  })
end

function Mod.buffers()
  async(function()
    await(main)

    source_bufnr = fn.bufnr()
    source_winid = fn.win_getid()
    active = true

    -- @type Buffer
    local this_bufnr = api.nvim_create_buf(false, true)

    cmd(format('botright sb %s', this_bufnr))

    api.nvim_win_set_height(0, 10)
    vim.wo.number = false
    vim.wo.signcolumn = "no"

    apply_keymap(this_bufnr)

    -- @param bufnr Buffer
    -- @param firstline Buffer
    -- @param new_lastline Buffer
    local function on_lines(_, bufnr, _, firstline, _, new_lastline, _, _, _)
      pcall(function()
        main(function()
          local lines = api.nvim_buf_get_lines(bufnr, firstline, new_lastline, true)
          local preview = curr_line_buf(lines)

          if preview then
            preview = tonumber(preview)
            api.nvim_win_set_buf(source_winid, preview)
          end
        end)
      end)
    end

    cmd [[
    silent redir => b:ls
    ls
    redir END
    ]]

    local source = vim.split(vim.b.ls, '\n')

    local opts = [[ --ansi --expect="ctrl-c,ctrl-g,ctrl-d,enter" ]]

    api.nvim_buf_attach(this_bufnr, false, { on_lines = on_lines })

    local choice = fzf.provided_win_fzf(source, opts)

    active = false

    local function reset()
      api.nvim_win_set_buf(source_winid, source_bufnr)
      fn.win_gotoid(source_winid)
    end

    if not choice then
      return reset()
    end

    local key = choice[1]

    if key == 'enter' then
      fn.win_gotoid(source_winid)
    else
      return reset()
    end
  end)()
end

function Mod.init()
  cmd [[
  command! ViperBuffers :lua require("viper").buffers()
  ]]
end

Mod.init()

return Mod
