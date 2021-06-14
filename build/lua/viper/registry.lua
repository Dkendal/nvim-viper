local meta = {}
meta.__call = function(tbl, name, ...)
  local func = tbl[name]
  if not func then
    return error(("viper.registry: \"" .. name .. "\" is not defined"))
  else
    return func(...)
  end
end
viper = {}
setmetatable(viper, meta)
local function register(name, definition)
  viper[name] = definition
  return nil
end
local function call(name, _3fargs)
  return viper[name]((_3fargs or {}))
end
local function apply(name, _3fargs)
  return viper[name]((_3fargs or {}))
end
return {apply = apply, call = call, register = register}
