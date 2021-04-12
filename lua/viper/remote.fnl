(fn warn [msg]
  "Write to strderr"
  (vim.api.nvim_err_writeln msg))

(fn log [msg]
  "Write to stdout"
  (vim.api.nvim_out_write (.. msg "\n")))

(fn main [arg]
  "main function"
  (local chan (vim.fn.sockconnect "pipe" "/tmp/nvim.sock" { :rpc true }))

  (vim.fn.rpcrequest chan "nvim_command" arg))
