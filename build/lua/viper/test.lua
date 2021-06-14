local A = require("viper.autocmd")
local R = require("viper.registry")
local function _0_()
  local function _1_()
    local function _2_()
      return print("hello world from lua")
    end
    ; (require("viper.registry")).register("fnl/viper/test.fnl:8[231:261]", _2_)
    return "fnl/viper/test.fnl:8[231:261]"
  end
  return A.au("event", {"WinLeave", "BufWinLeave"}, "pattern", "*", "callback", _1_())
end
return A.augroup("my/test", _0_)
