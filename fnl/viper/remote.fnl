(fn warn [msg]
  "Write to strderr"
  (vim.api.nvim_err_writeln msg))

(fn log [msg]
  "Write to stdout"
  (vim.api.nvim_out_write (.. msg "\n")))

(fn request [cmd args ?opts]
  "RPC request"
  (let [opts (or ?opts {})
        server (or opts.servername vim.v.servername)
        chan (vim.fn.sockconnect "pipe" server { :rpc true }) ]
    (vim.fn.rpcrequest chan cmd args)))

(fn command [cmd ?opts]
  "remote command"
  (request "nvim_command" cmd ?opts))

{
 :request request
 :command command
}
