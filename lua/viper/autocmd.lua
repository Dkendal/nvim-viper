local function nil_3f(term)
  return (term == nil)
end
local join = table.concat
local function filter(tbl, predicate)
  assert((nil ~= predicate), string.format("Missing argument %s on %s:%s", "predicate", "lua/viper/autocmd.fnl", 8))
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "lua/viper/autocmd.fnl", 8))
  return vim.tbl_filter(predicate, tbl)
end
local function reject(tbl, predicate)
  assert((nil ~= predicate), string.format("Missing argument %s on %s:%s", "predicate", "lua/viper/autocmd.fnl", 11))
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "lua/viper/autocmd.fnl", 11))
  local function _0_()
    local function _1_()
      return 1
    end
    return not predicate(_1_)
  end
  return filter(tbl, _0_)
end
local function flatten(tbl)
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "lua/viper/autocmd.fnl", 14))
  return vim.tbl_flatten(tbl)
end
local function pack(...)
  local out = {...}
  return out
end
local function list2map(list)
  assert((nil ~= list), string.format("Missing argument %s on %s:%s", "list", "lua/viper/autocmd.fnl", 21))
  local tbl = {}
  for i = 1, #list, 2 do
    tbl[list[i]] = list[(i + 1)]
  end
  return tbl
end
local function au_cmd(opts)
  assert((nil ~= opts), string.format("Missing argument %s on %s:%s", "opts", "lua/viper/autocmd.fnl", 30))
  local group = opts.group
  local event = opts.event
  local pattern = opts.pattern
  local nested
  do
    local res_0_ = opts.nested
    nested = (res_0_ and res_0_)
  end
  local once
  do
    local res_0_ = opts.once
    once = (res_0_ and res_0_)
  end
  local buffer
  do
    local res_0_ = opts.buffer
    buffer = (res_0_ and res_0_)
  end
  local bang
  do
    local res_0_ = opts.bang
    bang = (res_0_ and res_0_)
  end
  local cmd = opts.cmd
  local cmdlist
  local _0_
  if bang then
    _0_ = "autocmd!"
  else
    _0_ = "autocmd"
  end
  local _3_
  do
    local _2_0 = buffer
    if (_2_0 == nil) then
      _3_ = nil
    elseif (_2_0 == false) then
      _3_ = nil
    elseif (_2_0 == true) then
      _3_ = "<buffer>"
    elseif (nil ~= _2_0) then
      local n = _2_0
      _3_ = ("<buffer=" .. n .. ">")
    else
    _3_ = nil
    end
  end
  local _4_
  if once then
    _4_ = "++once"
  else
  _4_ = nil
  end
  local _6_
  if nested then
    _6_ = "++nested"
  else
  _6_ = nil
  end
  cmdlist = {_0_, _3_, group, join(event, ","), pattern, _4_, _6_, cmd}
  return join(reject(flatten(cmdlist), nil_3f), " ")
end
local function au(...)
  return vim.cmd(au_cmd(list2map(pack(...))))
end
local function au_21(...)
  return vim.cmd(au_cmd(list2map(pack("bang", true, ...))))
end
return {au = au, augroup = augroup}
