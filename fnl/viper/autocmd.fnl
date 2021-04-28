(import-macros {:def-remote $$} :viper.macros)

(fn nil? [term]
  (= term nil))

(local join table.concat)

(lambda filter [tbl predicate]
  (vim.tbl_filter predicate tbl))

(lambda reject [tbl predicate]
  (filter tbl #(not (predicate #1))))

(lambda flatten [tbl]
  (vim.tbl_flatten tbl))

(lambda pack [...]
  (lua "local out = {...}")
  out)

(lambda list2map [list]
  "Convert an associative array to a key-value table"
  (let [tbl [] ]
    (for [i 1 (length list) 2]
      (tset tbl
            (. list i)
            (. list (+ i 1))))
    tbl))

(lambda au-cmd [opts]
  (let [group (. opts :group)
        event (. opts :event)
        pattern (. opts :pattern)
        nested (?. opts :nested)
        once (?. opts :once)
        buffer (?. opts :buffer)
        bang (?. opts :bang)
        cmd (. opts :cmd)

        cmdlist [(if bang :autocmd! :autocmd)
                 (match buffer
                   nil nil
                   false nil
                   true "<buffer>"
                   n (.. "<buffer=" n ">"))
                 group
                 (join event ",")
                 pattern
                 (if once :++once)
                 (if nested :++nested)
                 cmd
                 ]
        ]
    (join (reject (flatten cmdlist) nil?) " ")))


(lambda au [...]
  (vim.cmd (au-cmd (list2map (pack ...)))))

(lambda au! [...]
  (vim.cmd (au-cmd (list2map (pack :bang true ...)))))

(macro with-augroup [name ...]
  `(do
     (vim.cmd ,(.. "augroup " name))
     (vim.cmd :autocmd!)
     ,...
     (vim.cmd "augroup END")))

{:au au
 :augroup augroup
 }
