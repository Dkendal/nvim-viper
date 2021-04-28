(local registry {})

(lambda register [name definition]
  (tset registry name definition))

(lambda call [name ?args]
  ((. registry name) (or ?args [])))

{
 :call call
 :register register
}
