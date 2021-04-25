#!/bin/bash

exec >&2

set -euo pipefail

sock="/tmp/nvim.sock"

warn() {
  echo >&2 "$1"
}

subext() {
  echo "${1%%$2}$3"
}

case "$1" in
all)
  redo-ifchange bin/fennel
  redo-ifchange lua/viper/remote.lua.reload
  redo-ifchange lua/viper/registry.lua.reload
  redo-ifchange lua/viper/timers.lua.reload
  redo-ifchange lua/viper/functions.lua.reload
  ;;

clean)
  redo-targets | grep '^[^\.\.]' | xargs rm -f
  ;;

lua/*.lua.reload)
  lua="${1%%.reload}"
  redo-ifchange "$lua"
  # Automatically reload module in active vim session
  mod="$lua"
  mod="${mod##lua/}"
  mod="${mod//\//.}"
  mod="${mod%%.lua}"
  mod="${mod%%.init}"

  if [ -r "$sock" ] && [ ! "$mod" = "viper.remote" ] ; then
    nvim --headless \
      +"lua require('viper.remote').command('lua reload(\"$mod\")', { servername = \"$sock\" })" \
      +q
    warn "reloaded $mod"
  fi
  ;;

lua/*.lua)
  src=$(subext "$1" ".lua" ".fnl")

  if grep -q ';\s*@nocompile' -- "$src"; then
    exit
  fi

  redo-ifchange "$src"

  fennel \
    --add-package-path "lua/?.lua" \
    --add-package-path "/usr/share/nvim/runtime/lua/?.lua" \
    --add-fennel-path "lua/?.fnl" \
    --compile "$src" >"$3"

  ;;

*)
  warn "ERROR [$0] Don't know how to build rule: $1 $2 $3"
  exit 99
  ;;
esac
