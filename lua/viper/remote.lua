local function warn(msg)
  return vim.api.nvim_err_writeln(msg)
end
local function log(msg)
  return vim.api.nvim_out_write((msg .. "\n"))
end
local function main(arg)
  local chan = vim.fn.sockconnect("pipe", "/tmp/nvim.sock", {rpc = true})
  return vim.fn.rpcrequest(chan, "nvim_command", arg)
end
return main
