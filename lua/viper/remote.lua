local function warn(msg)
  return vim.api.nvim_err_writeln(msg)
end
local function log(msg)
  return vim.api.nvim_out_write((msg .. "\n"))
end
local function request(cmd, args, _3fopts)
  local opts = (_3fopts or {})
  local server = (opts.servername or vim.v.servername)
  local chan = vim.fn.sockconnect("pipe", server, {rpc = true})
  return vim.fn.rpcrequest(chan, cmd, args)
end
local function command(cmd, _3fopts)
  return request("nvim_command", cmd, _3fopts)
end
return {command = command, request = request}
