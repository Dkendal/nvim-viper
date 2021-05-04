local uv = vim.loop
local function set_timeout(timeout, callback)
  assert((nil ~= callback), string.format("Missing argument %s on %s:%s", "callback", "fnl/viper/timers.fnl", 3))
  assert((nil ~= timeout), string.format("Missing argument %s on %s:%s", "timeout", "fnl/viper/timers.fnl", 3))
  local timer = uv.new_timer()
  local ontimeout
  local function _0_()
    uv.timer_stop(timer)
    uv.close(timer)
    return callback()
  end
  ontimeout = _0_
  uv.timer_start(timer, timeout, 0, ontimeout)
  return timer
end
local function clear_timeout(timer)
  assert((nil ~= timer), string.format("Missing argument %s on %s:%s", "timer", "fnl/viper/timers.fnl", 13))
  uv.timer_stop(timer)
  return uv.close(timer)
end
local function debounce(timeout, callback)
  assert((nil ~= callback), string.format("Missing argument %s on %s:%s", "callback", "fnl/viper/timers.fnl", 18))
  assert((nil ~= timeout), string.format("Missing argument %s on %s:%s", "timeout", "fnl/viper/timers.fnl", 18))
  local timer = nil
  local function _0_(...)
    if (timer and uv.is_active(timer)) then
      clear_timeout(timer)
    end
    local vargs = {...}
    local func
    local function _2_()
      return callback(unpack(vargs))
    end
    func = _2_
    timer = set_timeout(timeout, func)
    return nil
  end
  return _0_
end
return {["clear-timeout"] = clear_timeout, ["set-timeout"] = set_timeout, debounce = debounce}
