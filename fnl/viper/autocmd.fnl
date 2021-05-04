(local L (require :viper.list))

(fn nil? [term]
  (= term nil))

(fn pack [...]
  (lua "local out = {...}")
  out)

(fn au-cmd [opts]
  (let [group (. opts :group)
        event (. opts :event)
        pattern (. opts :pattern)
        nested (?. opts :nested)
        once (?. opts :once)
        buffer (?. opts :buffer)
        bang (?. opts :bang)
        callback (?. opts :callback)
        cmd (?. opts :cmd)
        cmd (if callback
              (.. ":call v:lua.viper(\"" callback "\")")
              (.. ":" cmd))

        cmdlist [(if bang :autocmd! :autocmd)
                 (match buffer
                   nil nil
                   false nil
                   true "<buffer>"
                   n (.. "<buffer=" n ">"))
                 group
                 (L.join event ",")
                 pattern
                 (if once :++once)
                 (if nested :++nested)
                 cmd]]
    (L.join (L.reject (L.flatten cmdlist) nil?) " ")))


(fn au [...]
  (vim.cmd (au-cmd (L.list2map (pack ...)))))

(fn au! [...]
  (vim.cmd (au-cmd (L.list2map (pack :bang true ...)))))

(fn augroup [name callback]
  "Define an autogroup with the supplied name"
  (vim.cmd (.. "augroup " name))
  (vim.cmd :autocmd!)
  (callback)
  (vim.cmd "augroup END"))

{:au au
 :au! au!
 :augroup augroup}
