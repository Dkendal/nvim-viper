(local join table.concat)

(lambda filter [tbl predicate]
  (vim.tbl_filter predicate tbl))

(lambda reject [tbl predicate]
  (filter tbl #(not (predicate #1))))

(lambda flatten [tbl]
  (vim.tbl_flatten tbl))

(lambda list2map [list]
  "Convert an associative array to a key-value table"
  (if (. list 1)
    (let [tbl [] ]
      (for [i 1 (length list) 2]
        (tset tbl
              (. list i)
              (. list (+ i 1))))
      tbl))
  )

{:filter filter
 :reject reject
 :flatten flatten
 :list2map list2map
 :join join
 }
