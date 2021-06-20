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
    local t_0_ = opts
    if (nil ~= t_0_) then
      t_0_ = (t_0_).nested
    end
    nested = t_0_
  end
  local once
  do
    local t_1_ = opts
    if (nil ~= t_1_) then
      t_1_ = (t_1_).once
    end
    once = t_1_
  end
  local buffer
  do
    local t_2_ = opts
    if (nil ~= t_2_) then
      t_2_ = (t_2_).buffer
    end
    buffer = t_2_
  end
  local bang
  do
    local t_3_ = opts
    if (nil ~= t_3_) then
      t_3_ = (t_3_).bang
    end
    bang = t_3_
  end
  local callback
  do
    local t_4_ = opts
    if (nil ~= t_4_) then
      t_4_ = (t_4_).callback
    end
    callback = t_4_
  end
  local cmd
  do
    local t_5_ = opts
    if (nil ~= t_5_) then
      t_5_ = (t_5_).cmd
    end
    cmd = t_5_
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
    local _3_ = buffer
    if (_3_ == nil) then
      _4_ = nil
    elseif (_3_ == false) then
      _4_ = nil
    elseif (_3_ == true) then
      _4_ = "<buffer>"
    elseif (nil ~= _3_) then
      local n = _3_
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
