#!/bin/bash

exec >&2

set -euo pipefail

source scripts/fnamemodify.sh

sock="/tmp/nvim.sock"

warn() {
  echo >&2 "$1"
}

reload() {
  local mod="$1"

  if [ -r "$sock" ] && [ ! "$mod" = "viper.remote" ]; then
    nvim --headless \
      +"lua require('viper.remote').command('lua reload(\"$mod\")', { servername = \"$sock\" })" \
      +q

    warn "reloaded $mod"
  fi
}

arg1="$1"

@@() {
  fnamemodify "$arg1" "$1"
}

case "$1" in
all)
  redo-ifchange bin/fennel
  redo-ifchange lua/viper/remote.lua.reload
  redo-ifchange lua/viper/registry.lua.reload
  redo-ifchange lua/viper/list.lua.reload
  redo-ifchange lua/viper/autocmd.lua.reload
  redo-ifchange lua/viper/timers.lua.reload
  redo-ifchange lua/viper/functions.lua.reload
  redo-ifchange lua/viper/test.lua.reload
  ;;

clean)
  redo-targets | grep '^[^\.\.]' | xargs rm -f
  ;;

lua/*.lua.reload)
  lua=$(@@ :r)

  redo-ifchange "$lua"
  # Automatically reload module in active vim session
  reload "$(@@ 'r:r:s?lua/??:s?/init$??:s?/?.?')"
  ;;

lua/*.lua)
  fnl="$(@@ :gs?lua?fnl?)"
  redo-ifchange "$fnl"

  if grep require-macros --silent; then
    redo-ifchange fnl/viper/macros.fnl
  fi

  if grep import-macros --silent; then
    redo-ifchange fnl/viper/macros.fnl
  fi

  fennel \
    --add-package-path "lua/?.lua" \
    --add-package-path "/usr/share/nvim/runtime/lua/?.lua" \
    --add-fennel-path "fnl/?.fnl" \
    --compile "$fnl" >"$3"
  ;;

*)
  warn "ERROR [$0] Don't know how to build rule: $1 $2 $3"
  exit 99
  ;;
esac
