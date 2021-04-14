local registry = {}
local function register(name, definition)
  assert((nil ~= definition), string.format("Missing argument %s on %s:%s", "definition", "lua/viper/registry.fnl", 3))
  assert((nil ~= name), string.format("Missing argument %s on %s:%s", "name", "lua/viper/registry.fnl", 3))
  registry[name] = definition
  return nil
end
local function call(name, _3fargs)
  assert((nil ~= name), string.format("Missing argument %s on %s:%s", "name", "lua/viper/registry.fnl", 6))
  return registry[name]((_3fargs or {}))
end
return {call = call, register = register}
