(local fzf (require "fzf"))
(local util (require "viper.util"))
(local a (require "viper.async"))

(local api vim.api)

(local mod {})

(macro with-buf [buf ...]
  '(api.nvim_buf_call ,buf #(do ,...)))

(macro with-main [...]
  '(a.main #(do ,...)))

(fn match-error [value]
  (error (.. "No matching case for: " (vim.inspect value))))

(fn cmd [...]
  "Vim cmd"
  (vim.cmd (table.concat [...] " ")))

(fn log [...]
  "Log a message to a special [Lua Messages] buffer"

  (local buf (vim.fn.bufadd "[Lua Messages]"))
  (local objects (vim.tbl_map vim.inspect [...]))
  (local str (table.concat objects " "))
  (local lines (vim.split str "\n"))

  (a.main
    #(vim.api.nvim_buf_call
       buf
       #(do
          (set vim.bo.buflisted true)
          (set vim.bo.swapfile false)
          (set vim.bo.buftype "nofile")

          (vim.api.nvim_buf_set_lines 0 -1 -1 false lines)
          (local n (vim.api.nvim_buf_line_count 0))
          (vim.api.nvim_win_set_cursor 0 [n 0]))))
  ...)

(fn parse-vimgrep [text]
  (local (file line col) (text:match "^(.+):(%d+):(%d+):"))
  [file (tonumber line) (tonumber col)])

(lambda result-get [result]
  "Return the success value of a result, or throw an error."
  (match result
    [false reason] (error reason)
    [true value] value))

(lambda map-esc-to-ctrl-c []
  (api.nvim_buf_set_keymap 0 "t" "<ESC>" "<C-c>" {}))

(lambda with-cursor [func]
  "Restore buffer position after func completes"
  (let
    [view (vim.fn.winsaveview)
    buf (api.nvim_get_current_buf)
    win (api.nvim_get_current_win)]

    (local result [(pcall func)])

    (api.nvim_set_current_win win)
    (api.nvim_set_current_buf buf)
    (vim.fn.winrestview view)

    (result-get result)))

(fn with-temp-buf [func]
  "Execute func in a temporary buffer"
  (with-cursor
    (fn []
      (local buf (api.nvim_create_buf false true))
      (vim.cmd (.. "botright sb "  buf))
      (api.nvim_win_set_height 0 10)
      (set vim.wo.number false)
      (set vim.wo.signcolumn "no")

      (local result [(pcall func)])

      (when (api.nvim_buf_is_valid buf)
        (api.nvim_buf_delete buf {}))

      (result-get result))))

(lambda run-fzf [opts]
  "
  Params

  opts.fzf-opts?: map - Flags to pass to FZF
  opts.process?: (string -> T) - Preprocessing to apply to the selection
  opts.sink?: ([string T] -> void) - Callback for final selection
  opts.config?: (-> void) - Callback that is run in the temp buffer, before FZF
    is called
  opts.on-change: (T -> void) - Callback to preview a selection while FZF is
    active
  "
  (local fzf-opts
    (-> opts.fzf-opts
      (or {})
      (util.merge_fzf_opts)))

  (local sink opts.sink)
  (local source opts.source)

  (->
    #(->
      #(do
        ; Any setup to run before running but within the temp buffer
        (when opts.config (opts.config))

        (when opts.on-change
          (util.on_selection_change
            #(opts.on-change
              (if opts.process (opts.process $1) $1))))

        ; Run fzf as an external command

        (->
          (match source
            [:shell value] value
            _ (match-error _))

          (fzf.provided_win_fzf fzf-opts)))

      (with-temp-buf)
      ; Result of fzf is fed to sink
      (match
        ; If the process callback is supplied transform the value by it
        (where [key selection] opts.process) [key (opts.process selection)]
        _ _)
      (sink))
    ; Run on the main thread
    (a.sync)
    (a.main)))


(lambda files [source ?opts]
  "
  @param source string Shell command that returns a file path
  "
  (run-fzf
    { :source [:shell source]

      :config
      (map_esc_to_ctrl_c)

      :sink
      #(match $1
        [:enter selection] (cmd :e selection))}))

(lambda grep [source ?opts]
  "
  Params

  source: string - Shell command that returns vimgrep compatible output
  opts?: map - unused
  "
  (local opts (or opts {}))

  (local ns (api.nvim_create_namespace "Viper Grep"))
  (local hl-group "Search")
  (local win (api.nvim_get_current_win))

  (run-fzf
    { :source [:shell source]

      :config #(map_esc_to_ctrl_c)

      :process parse-vimgrep

      :on-change
      (lambda [[file line col]]
        (local new? (= 0 (vim.fn.bufexists file)))
        (local buf (vim.fn.bufadd file))
        (with-main
          (api.nvim_buf_clear_namespace buf ns 0 -1 )
          ; Highlight selection
          (api.nvim_buf_add_highlight buf ns hl_group (- line 1) 0 -1 )
          ; Change window to selected buffer
          (api.nvim_win_set_buf win buf)
          (with-buf buf
            ; Move cursor to selection, center screen
            (vim.fn.setpos "." [buf line col])
            (cmd "keepjumps normal zz")
            (when new? (cmd "filetype detect")))))

      :sink
      #(match $1
        [:enter selection] (inspect selection))}))

{
  :files files
  :grep grep
  :log log
}