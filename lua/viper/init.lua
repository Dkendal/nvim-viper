local fzf = require 'fzf'
local a = require 'viper.async'

local async, await, main = a.sync, a.wait, a.main
local fn, api, cmd = vim.fn, vim.api, vim.cmd
local format = string.format

local Mod = {}
local registry = {}

local fzf_opts = { ansi = true, expect = { 'ctrl-c', 'ctrl-g', 'ctrl-d', 'enter' } }

local function log_error(value)
  dump('ERROR:', value)
  api.nvim_err_writeln(vim.inspect(value))
end

-- @alias Buffer number

local function tbl2flags(tbl)
  local out = ''
  for key, value in pairs(tbl) do
    if type(value) == 'table' then
      value = table.concat(value, ',')
    end

    if value == true then
      out = out .. ' ' .. format([[--%s]], key)
    else
      out = out .. ' ' .. format([[--%s=%s]], key, vim.inspect(value))
    end
  end
  return out
end

local function merge_fzf_opts(tbl)
  return tbl2flags(vim.tbl_deep_extend('keep', fzf_opts, { color = vim.o.background }, tbl))
end

local function inspect(...)
  print(unpack(vim.tbl_map(vim.inspect, { ... })))
end

-- Replace termcodes
local function t(keys)
  return api.nvim_replace_termcodes(keys, true, true, true)
end

local function execute_list(vim_cmd)
  local str = api.nvim_exec(vim_cmd, true)
  str = vim.split(str, '[\n\r]')
  return str
end

-- Run a function with the current buffer and win, and restore back to them
-- after the function completes.
local function with_current_buf_win(func)
  local view = fn.winsaveview()
  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()

  local success, result = pcall(func)

  api.nvim_set_current_win(win)
  api.nvim_set_current_buf(buf)
  fn.winrestview(view)

  if not success then
    error(result)
  end

  return result
end

local function with_temp_buf(func)
  return with_current_buf_win(function()
    local buf = api.nvim_create_buf(false, true)
    cmd(format('botright sb %s', buf))
    api.nvim_win_set_height(0, 10)
    vim.wo.number = false
    vim.wo.signcolumn = 'no'

    local success, result = pcall(func)

    if api.nvim_buf_is_valid(buf) then
      api.nvim_buf_delete(buf, {})
    end

    if not success then
      error(result)
    end

    return result
  end)
end

function Mod.buf_call(_buffer, mode, lhs, args)
  -- just gonna ignore buffer for now because there's only ever
  -- one window open
  -- I'm fine with thie being broken if there are multiple open
  registry[0][mode][lhs](args)
end

local function map_esc_to_ctrl_c()
  api.nvim_buf_set_keymap(0, 't', '<ESC>', '<C-c>', {})
end

-- return the current line in the fzf selection
local function fzf_current_line(lines)
  for _, value in ipairs(lines) do
    -- The number of matches line if this is the current line there aren't any
    -- valid matches
    if value:match('(%d)/%d') then
      return nil
    end

    local curr_match = value:match('>%s+(.*)')

    if curr_match then
      return curr_match
    end
  end
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

-- Register an event handler for when the selected line changes in the fzf window.
local function on_selection_change(callback)
  local on_lines = function(_, bufnr, _, firstline, _, new_lastline, _, _, _)
    if (new_lastline - firstline) == 1 then
      -- Don't do anything for now when it's just the last line
      return
    end

    local status, value = pcall(function()
      local lines = api.nvim_buf_get_lines(bufnr, firstline, new_lastline, false)
      local line = fzf_current_line(lines)

      if line and line:len() > 0 then
        callback(line)
      end
    end)

    if not status then
      log_error(value)
    end
  end

  api.nvim_buf_attach(0, false, { on_lines = on_lines })
end

local function parse_vimgrep(text)
  local file, line, col = text:match('^(.+):(%d+):(%d+):')
  line = tonumber(line)
  col = tonumber(col)
  return file, line, col
end

function Mod.buffers()
  local pattern = '(%d+).*'

  async(function()
    await(main)

    local win = api.nvim_get_current_win()

    local source = execute_list('ls')

    local choice = with_temp_buf(function()
      map_esc_to_ctrl_c()

      -- buf_set_keymap(this_bufnr, 't', '<C-k>', function() return end, {})

      -- @param bufnr Buffer
      -- @param firstline Buffer
      -- @param new_lastline Buffer
      local function on_lines(_, bufnr, _, firstline, _, new_lastline, _, _, _)
        pcall(function()
          local lines = api.nvim_buf_get_lines(bufnr, firstline, new_lastline, true)
          local preview = string.match(fzf_current_line(lines) or '', pattern)

          if preview then
            main(function()
              preview = tonumber(preview)
              api.nvim_win_set_buf(win, preview)
            end)
          end
        end)
      end

      api.nvim_buf_attach(0, false, { on_lines = on_lines })

      return fzf.provided_win_fzf(source, merge_fzf_opts({}))
    end)

    local key, selection = unpack(choice)

    local buf = selection:match(pattern)

    if key == 'enter' then
      cmd(format('buf %s', buf))
      return
    end
  end)()
end

function Mod.registers()
  async(function()
    await(main)

    local source = execute_list('registers')

    local choice = with_temp_buf(function()
      map_esc_to_ctrl_c()

      return fzf.provided_win_fzf(source, merge_fzf_opts({ ['header-lines'] = 1 }))
    end)

    local key, selection = unpack(choice)

    if key == 'enter' then
      local register = string.match(selection, [[%a%s+"(.)]])
      cmd(format('put %s', register))
    end
  end)()
end

-- @param source string Shell command that returns a file path
function Mod.files(source, opts)
  opts = opts or {}
  local pattern = opts.pattern or ".*"

  async(function()
    await(main)

    local choice = with_temp_buf(function()
      map_esc_to_ctrl_c()
      return fzf.provided_win_fzf(source, merge_fzf_opts({}))
    end)

    local key, selection = unpack(choice)

    local file = selection:match(pattern)

    if key == 'enter' then
      cmd(format('e %s', file))
    end
  end)()
end

-- @param source string Shell command that returns vimgrep formatted results
function Mod.grep(source)
  local win = api.nvim_get_current_win()

  async(function()
    await(main)

    local ns = api.nvim_create_namespace('Viper Grep')
    local hl_group = 'Search'

    local choice = with_temp_buf(function()
      map_esc_to_ctrl_c()

      on_selection_change(function(text)
        local file, line, col = parse_vimgrep(text)

        if file == nil then
          return
        end

        local new_buf = fn.bufexists(file) == 0
        local buf = fn.bufadd(file)

        main(function()

          api.nvim_buf_clear_namespace(buf, ns, 0, -1)
          api.nvim_buf_add_highlight(buf, ns, hl_group, line - 1, 0, -1)
          api.nvim_win_set_buf(win, buf)

          api.nvim_buf_call(buf, function()
            fn.setpos('.', { buf, line, col })

            -- center the buffer in the window around the selection
            cmd 'keepjumps normal zz'

            if new_buf then
              cmd 'filetype detect'
            end
          end)
        end)
      end)

      return fzf.provided_win_fzf(source, merge_fzf_opts({}))
    end)

    api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local key, selection = unpack(choice)

    local file, line = parse_vimgrep(selection)

    if key == 'enter' then
      cmd(format('e +%d %s', line, file))
    end
  end)()
end

function Mod.init()
  api.nvim_exec([[
  command! ViperBuffers :lua require("viper").buffers()
  command! ViperRegisters :lua require("viper").registers()
  command! -nargs=* ViperFiles :lua require("viper.functions").files(<q-args>)
  command! -nargs=* ViperGrep :lua require("viper.functions").grep(<q-args>)

  command! -nargs=* ViperGitStatus :lua require("viper").files("git -c color.status=always status --short", { pattern = ".* (.*)" })
  ]], false)
end

Mod.init()

return Mod
