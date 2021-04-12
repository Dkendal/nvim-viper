#!/bin/bash

exec >&2

set -euo pipefail

warn() {
  echo >&2 "$1"
}

subext() {
  echo "${1%%$2}$3"
}

case "$1" in
all)
  redo-ifchange bin/fennel
  redo all.fnl
  nvim --headless \
    +"lua require('viper.remote')('lua reload(\"viper.functions\")')" \
    +"lua require('viper.remote')('lua reload(\"viper\")')" \
    +q
  ;;

clean)
  redo-targets | grep '^[^\.\.]' | xargs rm -f
  ;;

all.fnl)
  for file in lua/**/*.fnl; do
    subext "$file" ".fnl" ".lua"
  done | xargs redo-ifchange
  ;;

lua/*.lua)
  src=$(subext "$1" ".lua" ".fnl")
  redo-ifchange "$src"
  fennel --compile "$src" >"$3"
  # Automatically reload module in active vim session
  module="$1"
  module="${module##lua/}"
  module="${module%%.lua}"
  module="${module/\//.}"
  ;;

*)
  warn "ERROR [$0] Don't know how to build rule: $1 $2 $3"
  exit 99
  ;;
esac
