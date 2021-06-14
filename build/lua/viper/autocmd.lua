local L = require("viper.list")
local function nil_3f(term)
  return (term == nil)
end
local function pack(...)
  local out = {...}
  return out
end
local function au_cmd(opts)
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
  local callback
  do
    local res_0_ = opts.callback
    callback = (res_0_ and res_0_)
  end
  local cmd
  do
    local res_0_ = opts.cmd
    cmd = (res_0_ and res_0_)
  end
  local cmd0
  if callback then
    cmd0 = (":call v:lua.viper(\"" .. callback .. "\")")
  else
    cmd0 = (":" .. cmd)
  end
  local cmdlist
  local _1_
  if bang then
    _1_ = "autocmd!"
  else
    _1_ = "autocmd"
  end
  local _4_
  do
    local _3_0 = buffer
    if (_3_0 == nil) then
      _4_ = nil
    elseif (_3_0 == false) then
      _4_ = nil
    elseif (_3_0 == true) then
      _4_ = "<buffer>"
    elseif (nil ~= _3_0) then
      local n = _3_0
      _4_ = ("<buffer=" .. n .. ">")
    else
    _4_ = nil
    end
  end
  local _5_
  if once then
    _5_ = "++once"
  else
  _5_ = nil
  end
  local _7_
  if nested then
    _7_ = "++nested"
  else
  _7_ = nil
  end
  cmdlist = {_1_, _4_, group, L.join(event, ","), pattern, _5_, _7_, cmd0}
  return L.join(L.reject(L.flatten(cmdlist), nil_3f), " ")
end
local function au(...)
  return vim.cmd(au_cmd(L.list2map(pack(...))))
end
local function au_21(...)
  return vim.cmd(au_cmd(L.list2map(pack("bang", true, ...))))
end
local function augroup(name, callback)
  vim.cmd(("augroup " .. name))
  vim.cmd("autocmd!")
  callback()
  return vim.cmd("augroup END")
end
return {["au!"] = au_21, au = au, augroup = augroup}
