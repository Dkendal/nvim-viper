local fzf = require("fzf")
local util = require("viper.util")
local a = require("viper.async")
local remote = require("viper.remote")
local debounce = (require("viper.timers")).debounce
local api = vim.api
local autocmd = require("viper.autocmd")
local au = autocmd.au
local mod = {}
local function match_error(value)
  return error(("No matching case for: " .. vim.inspect(value)))
end
local function cmd(...)
  return vim.cmd(table.concat({...}, " "))
end
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
local function merge_fzf_opts(opts)
  return util.tbl2flags(vim.tbl_deep_extend("keep", {ansi = true, color = vim.o.background, expect = {"ctrl-c", "ctrl-g", "ctrl-d", "enter"}}, opts))
end
local function exec_list(vim_expr)
  return vim.split(api.nvim_exec(vim_expr, true), "[\n\r]")
end
local function parse_vimgrep(text)
  local file, line, col = text:match("^(.+):(%d+):(%d+):")
  return {file, tonumber(line), tonumber(col)}
end
local function result_get(result)
  assert((nil ~= result), string.format("Missing argument %s on %s:%s", "result", "lua/viper/functions.fnl", 63))
  local _0_0 = result
  if ((type(_0_0) == "table") and ((_0_0)[1] == false) and (nil ~= (_0_0)[2])) then
    local reason = (_0_0)[2]
    return error(reason)
  elseif ((type(_0_0) == "table") and ((_0_0)[1] == true) and (nil ~= (_0_0)[2])) then
    local value = (_0_0)[2]
    return value
  end
end
local function with_cursor(func)
  assert((nil ~= func), string.format("Missing argument %s on %s:%s", "func", "lua/viper/functions.fnl", 69))
  local view = vim.fn.winsaveview()
  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  local result = {pcall(func)}
  api.nvim_set_current_win(win)
  api.nvim_set_current_buf(buf)
  vim.fn.winrestview(view)
  return result_get(result)
end
local function with_temp_buf(func)
  local function _0_()
    local buf = api.nvim_create_buf(false, true)
    vim.cmd(("botright sb " .. buf))
    api.nvim_win_set_height(0, 10)
    vim.wo.number = false
    vim.wo.signcolumn = "no"
    local result = {pcall(func)}
    if api.nvim_buf_is_valid(buf) then
      api.nvim_buf_delete(buf, {})
    end
    return result_get(result)
  end
  return with_cursor(_0_)
end
local function run_fzf(opts)
  assert((nil ~= opts), string.format("Missing argument %s on %s:%s", "opts", "lua/viper/functions.fnl", 101))
  local fzf_opts = merge_fzf_opts((opts["fzf-opts"] or {}))
  local sink = opts.sink
  local source = opts.source
  local function _0_()
    local function _4_()
      local _1_0, _2_0, _3_0 = nil, nil, nil
      local function _4_()
        local function current_line()
          local pattern = "> (.*)"
          local out = nil
          for k, v in ipairs(api.nvim_buf_get_lines(0, 0, -3, false)) do
            if out then break end
            local m = string.match(v, pattern)
            if m then
              out = m
            end
          end
          return out
        end
        do
          api.nvim_buf_set_keymap(0, "t", "<ESC>", "<C-c>", {})
        end
        if opts.config then
          opts.config()
        end
        local function _6_(raw_line)
          if opts["on-change"] then
            local current_line0
            if opts.process then
              current_line0 = opts.process(raw_line)
            else
              current_line0 = raw_line
            end
            local function _8_()
              vim.b["viper-raw-current-line"] = raw_line
              vim.b["viper-current-line"] = current_line0
              return opts["on-change"](current_line0)
            end
            return vim.schedule(_8_)
          end
        end
        util.on_selection_change(debounce(100, _6_))
        local _8_
        do
          local _7_0 = source
          if ((type(_7_0) == "table") and ((_7_0)[1] == "shell") and (nil ~= (_7_0)[2])) then
            local shellcmd = (_7_0)[2]
            _8_ = shellcmd
          elseif ((type(_7_0) == "table") and ((_7_0)[1] == "vim") and (nil ~= (_7_0)[2])) then
            local expr = (_7_0)[2]
            _8_ = exec_list(expr)
          else
            local _ = _7_0
            _8_ = match_error(_)
          end
        end
        return fzf.provided_win_fzf(_8_, fzf_opts)
      end
      _1_0, _2_0, _3_0 = with_temp_buf(_4_)
      local _5_
      do
        local key = (_1_0)[1]
        local selection = (_1_0)[2]
        _5_ = (((type(_1_0) == "table") and (nil ~= (_1_0)[1]) and (nil ~= (_1_0)[2])) and opts.process)
      end
      if _5_ then
        local key = (_1_0)[1]
        local selection = (_1_0)[2]
        return {key, opts.process(selection)}
      elseif (nil ~= _1_0) then
        local k = _1_0
        return k
      end
    end
    return sink(_4_())
  end
  return a.main(a.sync(_0_))
end
local function history()
  local function _0_(_241)
    local _1_0 = _241
    if ((type(_1_0) == "table") and ((_1_0)[1] == "enter") and (nil ~= (_1_0)[2])) then
      local selection = (_1_0)[2]
      return cmd("e", selection)
    end
  end
  return run_fzf({sink = _0_, source = {"vim", "oldfiles"}})
end
local function files(source, _3fopts)
  assert((nil ~= source), string.format("Missing argument %s on %s:%s", "source", "lua/viper/functions.fnl", 179))
  local function _0_(_241)
    local _1_0 = _241
    if ((type(_1_0) == "table") and ((_1_0)[1] == "enter") and (nil ~= (_1_0)[2])) then
      local selection = (_1_0)[2]
      return cmd("e", selection)
    end
  end
  return run_fzf({sink = _0_, source = {"shell", source}})
end
local function grep(source, _3fopts)
  assert((nil ~= source), string.format("Missing argument %s on %s:%s", "source", "lua/viper/functions.fnl", 190))
  local opts = (opts or {})
  local ns = api.nvim_create_namespace("Viper Grep")
  local hl_group = "Search"
  local win = api.nvim_get_current_win()
  local buf = 0
  local function clear_highlight()
    return api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  local function _1_(_0_0)
    local _arg_0_ = _0_0
    local file = _arg_0_[1]
    local line = _arg_0_[2]
    local col = _arg_0_[3]
    assert((nil ~= col), string.format("Missing argument %s on %s:%s", "col", "lua/viper/functions.fnl", 214))
    assert((nil ~= line), string.format("Missing argument %s on %s:%s", "line", "lua/viper/functions.fnl", 214))
    assert((nil ~= file), string.format("Missing argument %s on %s:%s", "file", "lua/viper/functions.fnl", 214))
    local new_3f = (0 == vim.fn.bufexists(file))
    buf = vim.fn.bufadd(file)
    local function _2_()
      clear_highlight()
      api.nvim_buf_add_highlight(buf, ns, hl_group, (line - 1), 0, -1)
      api.nvim_win_set_buf(win, buf)
      local function _3_()
        vim.fn.setpos(".", {buf, line, col})
        cmd("keepjumps normal zz")
        if new_3f then
          return cmd("filetype detect")
        end
      end
      return api.nvim_buf_call(buf, _3_)
    end
    return vim.schedule(_2_)
  end
  local function _2_(_241)
    do
      local _3_0 = _241
      if ((type(_3_0) == "table") and ((_3_0)[1] == "enter") and ((type((_3_0)[2]) == "table") and (nil ~= ((_3_0)[2])[1]) and (nil ~= ((_3_0)[2])[2]) and true)) then
        local file = ((_3_0)[2])[1]
        local line = ((_3_0)[2])[2]
        local _ = ((_3_0)[2])[3]
        cmd("e", ("+" .. line), file)
        cmd("keepjumps", "normal", "zz")
      end
    end
    return clear_highlight()
  end
  return run_fzf({["on-change"] = _1_, process = parse_vimgrep, sink = _2_, source = {"shell", source}})
end
return {files = files, grep = grep, history = history, log = log}
