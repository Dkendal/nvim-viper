(local inspect (require :vim.inspect))
(local fennel (require :fennel))

(fn uuid []
  (with-open [fout (io.popen :uuid :r)]
             (fout:read "*l")))

(fn with-buf [buf ...]
  `(api.nvim_buf_call ,buf #(do ,...)))

(fn with-main [...]
  `(vim.schedule #(do ,...)))

(fn buf-map [mode lhs rhs ?opts]
  (let
    [(rhs callback? func-name func)
     (match rhs
       (where rhs (= (type rhs) "string")) rhs

       (where [{1 node :filename filename :line line :bytestart s :byteend e }]
              (or (= node :fn)
                  (= node :lambda)))
       (let
         [name (.. filename ":" line "[" s ":" e "]")]
         (values
           (..  "<cmd>lua "
               (fennel.compile
                 `((. (require :viper.registry) :call) ,name []))
               "<cr>")
           true
           name
           rhs)))

     opts (or ?opts {})]
    `(do
       ,(when callback?
          `((. (require :viper.registry) :register) ,func-name ,func))
       (api.nvim_buf_set_keymap
         0
         ,mode
         ,lhs
         ,rhs
         ,opts))))

(fn map [mode lhs rhs ?opts]
  (let
    [(rhs callback? func-name func)
     (match rhs
       (where rhs (= (type rhs) "string")) rhs

       (where [[node] [name] []]
              (and (or (= node :fn)
                       (= node :lambda))
                   (~= name nil)))
       (values
         (..  "lua " (fennel.compile
                       `((. (require :viper.registry) :call) ,name [])))
         true
         name
         rhs))

     opts (or ?opts {})]
    `(do
       ,(when callback?
          `((. (require :viper.registry) :register) ,func-name ,func))
       (api.nvim_buf_set_keymap
         0
         ,mode
         ,lhs
         ,rhs
         ,opts))))

(fn func-name [callback]
  (match callback
    [{:filename filename :line line :bytestart s :byteend e }]
    (.. filename ":" line "[" s ":" e "]")))

(fn def-remote [callback]
  "define remote function in registry"
  (local name (func-name callback))
  `(do
    (local registry# (require :viper.registry))
    (registry#.register ,name ,callback)
    (.. "lua require(\"viper.registry\").call(\"" ,name "\", {})")))

{:with-buf with-buf
 :with-main with-main
 :buf-map buf-map
 :map map
 :def-remote def-remote
 }
