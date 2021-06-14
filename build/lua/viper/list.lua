local join = table.concat
local function filter(tbl, predicate)
  assert((nil ~= predicate), string.format("Missing argument %s on %s:%s", "predicate", "fnl/viper/list.fnl", 3))
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "fnl/viper/list.fnl", 3))
  return vim.tbl_filter(predicate, tbl)
end
local function reject(tbl, predicate)
  assert((nil ~= predicate), string.format("Missing argument %s on %s:%s", "predicate", "fnl/viper/list.fnl", 6))
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "fnl/viper/list.fnl", 6))
  local function _0_()
    local function _1_()
      return 1
    end
    return not predicate(_1_)
  end
  return filter(tbl, _0_)
end
local function flatten(tbl)
  assert((nil ~= tbl), string.format("Missing argument %s on %s:%s", "tbl", "fnl/viper/list.fnl", 9))
  return vim.tbl_flatten(tbl)
end
local function list2map(list)
  assert((nil ~= list), string.format("Missing argument %s on %s:%s", "list", "fnl/viper/list.fnl", 12))
  if list[1] then
    local tbl = {}
    for i = 1, #list, 2 do
      tbl[list[i]] = list[(i + 1)]
    end
    return tbl
  end
end
return {filter = filter, flatten = flatten, join = join, list2map = list2map, reject = reject}
