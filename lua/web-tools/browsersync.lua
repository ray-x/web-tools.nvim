local utils = require('web-tools.utils')
vim = vim or nil
local vfn = vim.fn
local log = utils.log

local job
local port
local info = ''
local M = {}

--[[ [Browsersync] Access URLs:
 --------------------------------------
       Local: http://localhost:3000
    External: http://192.168.1.11:3000
 --------------------------------------
          UI: http://localhost:3001
 UI External: http://localhost:3001
 --------------------------------------
[Browsersync] Serving files from: ./
[Browsersync] Watching files... ]]

_WEBTOOLS_CFG = _WEBTOOLS_CFG or { debug = false }

M.running = function()
  if not job then
    return false
  end
  log(job, vim.fn.jobwait({ job }, 0))
  return vim.fn.jobwait({ job }, 0)[1] == -1
end

M.status = function()
  if M.running() then
    return '鷺 ' .. tostring(port or _WEBTOOLs_CFG.port)
  end
end

M.stop = function()
  if M.running() then
    log('stop ', job)
    if job then
      vim.fn.jobstop(job)
    end
    job = nil
    port = nil
  end
end

M.open_browser = function(url)
  require('web-tools.openbrowser').open(url)
end

M.open = function(...)
  args = { ... }
  args.callback = function()
    M.open(args)
  end

  if not M.running() then
    vim.defer_fn(function()
      M.run(args)
    end, 1)
    vim.notify('waiting for browser sync to start')
    return
  end
  local _port = port
  local path = '/'
  if args[1] and type(args[1]) == 'string' and vim.fn.exists(args[1]) then
    path = args[1]
  end
  if not M.running() then
    vim.notify('server not started', vim.lsp.log_levels.ERROR)
  end
  local slash = '/'
  if path == '/' then
    slash = ''
  end
  local url = 'http://localhost:' .. tostring(_port) .. slash .. path
  M.open_browser(url)
end

M.run = function(args)
  local cmd = {
    vim.o.shell,
    vim.o.shellcmdflag,
  }
  if vim.fn.executable('browser-sync') == 0 then
    return vim.notify(
      'browser-sync not found please install with npm install -g browser-sync',
      vim.lsp.log_levels.ERROR
    )
  end
  local opts = { 'browser-sync', 'start', '--server', '--watch', '--no-open' }

  if M.running() then
    M.stop()
  end
  local callback = function()
    log('default callback')
  end

  if args.callback then
    callback = args.callback
  end
  if args then
    for i = 1, #args do
      log(args[i])
      if args[i] == '--files' then
        if args[i + 1] ~= nil then
          -- wrap next arg with ""
          args[i + 1] = [["]] .. args[i + 1] .. [["]]
        end
      end
      table.insert(opts, args[i])
    end
  end

  opts = table.concat(opts, ' ')
  table.insert(cmd, opts)

  log('fmt cmd:', cmd, opts)
  job = vim.fn.jobstart(cmd, {
    on_stdout = function(job_id, data, event)
      log(job_id, data)
      -- print('job started', job_id)
      data = utils.handle_job_data(data)
      if not data then
        return
      end
      local last = false
      if type(data) == 'table' then
        for _, line in pairs(data) do
          info = info .. line .. '\n'
          if string.find(line, 'Local') then
            port = vim.fn.matchstr(line, [[\v:\zs\d+$$]])
          end
          if line:find('Watching') then
            last = true
          end
        end
      end
      utils.log('port:', port)
      utils.log(info)

      if last then
        vim.defer_fn(function()
          log('callback')
          callback()
        end, 50)
      end
    end,
    on_stderr = function(job_id, data, event)
      data = utils.handle_job_data(data)
      if not data then
        return
      end
      log(job_id, data)
      vim.notify(vim.inspect(data) .. ' from stderr', vim.lsp.log_levels.ERROR)
    end,
    on_exit = function(job_id, data, event)
      log('exit', job_id, data)
      vim.notify(vim.inspect(data), vim.lsp.log_levels.INFO)

      vim.fn.chanclose(job, 'stderr')
      vim.fn.chanclose(job, 'stdout')
    end,
    cwd = vim.fn.getcwd(),
    -- stdout_buffered = true,
    -- stderr_buffered = true,
  })
  if job == 0 then
    log('job create failure', job)
  end
  log('job id', job)
  vim.fn.chanclose(job, 'stdin')
end

M.restart = function(args)
  M.stop()
  M.run(args)
end

M.preview_file = function()
  local delay = 500

  local filename = vfn.fnamemodify(vfn.expand('%'), ':~:.')
  if not M.running() then
    M.run({
      callback = function()
        M.open(filename)
      end,
    })
  else
    M.open(filename)
  end
end
return M
