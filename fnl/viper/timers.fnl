(local uv vim.loop)

(lambda set-timeout [timeout callback]
  ""
  (let [timer (uv.new_timer)
        ontimeout (fn []
                    (uv.timer_stop timer)
                    (uv.close timer)
                    (callback))]
    (uv.timer_start timer timeout 0 ontimeout)
    timer))

(lambda clear-timeout [timer]
  ""
  (uv.timer_stop timer)
  (uv.close timer))

(lambda debounce [timeout callback]
  "Debounce `func`"
  (var timer nil)

  (fn [...]
    (when (and timer (uv.is_active timer))
      (clear-timeout timer))

    (local vargs [...])
    (local func #(callback (unpack vargs)))
    (set timer (set-timeout timeout func))))

{:set-timeout set-timeout
 :clear-timeout clear-timeout
 :debounce debounce
 }
