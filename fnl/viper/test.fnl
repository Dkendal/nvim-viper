(require-macros :viper.macros)

(local A (require :viper.autocmd))
(local R (require :viper.registry))

(A.augroup :my/test
           #(A.au :event [:WinLeave :BufWinLeave] :pattern :*
                  :callback (defcallback #(print "hello world from lua"))))
