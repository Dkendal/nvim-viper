local format = string.format
local a = require "viper.async"

local fn, api, cmd = vim.fn, vim.api, vim.cmd

local fzf_opts = { ansi = true, expect = { 'ctrl-c', 'ctrl-g', 'ctrl-d', 'enter' } }

local function log(...)
  local buf = vim.fn.bufadd("[Lua Messages]")
  local objects = vim.tbl_map(vim.inspect, {...})
  local str = table.concat(objects, " ")
  local lines = vim.split(str, "\n")
  local function _0_()
    local function _1_()
      vim.bo.buflisted = true
      vim.bo.swapfile = false
      vim.bo.buftype = "nofile"
      vim.api.nvim_buf_set_lines(0, -1, -1, false, lines)
      local n = vim.api.nvim_buf_line_count(0)
      return vim.api.nvim_win_set_cursor(0, {n, 0})
    end
    return vim.api.nvim_buf_call(buf, _1_)
  end
  a.main(_0_)
  return ...
end

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
      log(value)
    end
  end

  api.nvim_buf_attach(0, false, { on_lines = on_lines })
end

return {
  tbl2flags = tbl2flags,
  merge_fzf_opts = merge_fzf_opts,
  on_selection_change = on_selection_change,
  fzf_current_line = fzf_current_line,
  log = log,
}
