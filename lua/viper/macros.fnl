; @nocompile

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

{
 :with-buf with-buf
 :with-main with-main
 :buf-map buf-map
 :map map
 }
