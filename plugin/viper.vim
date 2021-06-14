let dir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let &runtimepath .= ',' . dir . '/build'
lua require("viper")
