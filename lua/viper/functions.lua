local fzf = require("fzf")
local util = require("viper.util")
local a = require("viper.async")
local api = vim.api
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
local function parse_vimgrep(text)
  local file, line, col = text:match("^(.+):(%d+):(%d+):")
  return {file, tonumber(line), tonumber(col)}
end
local function result_get(result)
  assert((nil ~= result), string.format("Missing argument %s on %s:%s", "result", "lua/viper/functions.fnl", 47))
  local _0_0 = result
  if ((type(_0_0) == "table") and ((_0_0)[1] == false) and (nil ~= (_0_0)[2])) then
    local reason = (_0_0)[2]
    return error(reason)
  elseif ((type(_0_0) == "table") and ((_0_0)[1] == true) and (nil ~= (_0_0)[2])) then
    local value = (_0_0)[2]
    return value
  end
end
local function map_esc_to_ctrl_c()
  return api.nvim_buf_set_keymap(0, "t", "<ESC>", "<C-c>", {})
end
local function with_cursor(func)
  assert((nil ~= func), string.format("Missing argument %s on %s:%s", "func", "lua/viper/functions.fnl", 56))
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
  assert((nil ~= opts), string.format("Missing argument %s on %s:%s", "opts", "lua/viper/functions.fnl", 88))
  local fzf_opts = util.merge_fzf_opts((opts["fzf-opts"] or {}))
  local sink = opts.sink
  local source = opts.source
  local function _0_()
    local function _4_()
      local _1_0, _2_0, _3_0 = nil, nil, nil
      local function _4_()
        if opts.config then
          opts.config()
        end
        if opts["on-change"] then
          local function _6_(_2411)
            local function _7_()
              if opts.process then
                return opts.process(_2411)
              else
                return _2411
              end
            end
            return opts["on-change"](_7_())
          end
          util.on_selection_change(_6_)
        end
        local _8_
        do
          local _7_0 = source
          if ((type(_7_0) == "table") and ((_7_0)[1] == "shell") and (nil ~= (_7_0)[2])) then
            local value = (_7_0)[2]
            _8_ = value
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
      else
        local _ = _1_0
        return _
      end
    end
    return sink(_4_())
  end
  return a.main(a.sync(_0_))
end
local function files(source, _3fopts)
  assert((nil ~= source), string.format("Missing argument %s on %s:%s", "source", "lua/viper/functions.fnl", 140))
  local function _0_(_241)
    local _1_0 = _241
    if ((type(_1_0) == "table") and ((_1_0)[1] == "enter") and (nil ~= (_1_0)[2])) then
      local selection = (_1_0)[2]
      return cmd("e", selection)
    end
  end
  return run_fzf({config = map_esc_to_ctrl_c(), sink = _0_, source = {"shell", source}})
end
local function grep(source, _3fopts)
  assert((nil ~= source), string.format("Missing argument %s on %s:%s", "source", "lua/viper/functions.fnl", 154))
  local opts = (opts or {})
  local ns = api.nvim_create_namespace("Viper Grep")
  local hl_group = "Search"
  local win = api.nvim_get_current_win()
  local function _1_(_0_0)
    local _arg_0_ = _0_0
    local file = _arg_0_[1]
    local line = _arg_0_[2]
    local col = _arg_0_[3]
    assert((nil ~= col), string.format("Missing argument %s on %s:%s", "col", "lua/viper/functions.fnl", 175))
    assert((nil ~= line), string.format("Missing argument %s on %s:%s", "line", "lua/viper/functions.fnl", 175))
    assert((nil ~= file), string.format("Missing argument %s on %s:%s", "file", "lua/viper/functions.fnl", 175))
    local new_3f = (0 == vim.fn.bufexists(file))
    local buf = vim.fn.bufadd(file)
    local function _2_()
      api.nvim_buf_clear_namespace(buf, ns, 0, -1)
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
    return a.main(_2_)
  end
  local function _2_()
    return map_esc_to_ctrl_c()
  end
  local function _3_(_241)
    local _4_0 = _241
    if ((type(_4_0) == "table") and ((_4_0)[1] == "enter") and (nil ~= (_4_0)[2])) then
      local selection = (_4_0)[2]
      return inspect(selection)
    end
  end
  return run_fzf({["on-change"] = _1_, config = _2_, process = parse_vimgrep, sink = _3_, source = {"shell", source}})
end
return {files = files, grep = grep, log = log}
