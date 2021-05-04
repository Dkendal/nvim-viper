(local meta {})

; (set meta.__mode :kv)

(fn meta.__call [tbl name ...]
  (local func (. tbl name))
  (if (not func)
    (error (.. "viper.registry: \"" name "\" is not defined"))
    (func ...)))

(global viper {})

(setmetatable viper meta)

(fn register [name definition]
  (tset viper name definition))

(fn call [name ?args]
  ((. viper name) (or ?args [])))

(fn apply [name ?args]
  ((. viper name) (or ?args [])))

{:call call
 :apply apply
 :register register}
