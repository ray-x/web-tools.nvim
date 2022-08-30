local utils = require('web-tools.utils')
vim = vim or nil
local vfn = vim.fn
local log = utils.log
_WEBTOOLS = {}

local job
local port
local info = ''

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

_LIVEVIEW_CFG = {
  debug = false,
}

local running = function()
  if job == nil then
    return false
  end
  log(job, vim.fn.jobwait({ job }, 0))
  return vim.fn.jobwait({ job }, 0)[1] == -1
end
local status = function()
  if running() then
    return '鷺 ' .. tostring(_LIVEVIEW_CFG.port or port or 3000)
  end
end
local stop = function()
  if running() then
    vim.fn.jobstop(job)
    job = nil
    port = nil
  end
end

local function open_browser(url)
  require('web-tools.openbrowser').open(url)
end

local open = function(path, _port)
  _port = _port or port
  path = path or '/'
  if not running() then
    vim.notify('server not started', vim.lsp.log_levels.ERROR)
  end
  local slash = '/'
  if path == '/' then
    slash = ''
  end
  local url = 'http://localhost:' .. tostring(_port) .. slash .. path
  open_browser(url)
end

local run = function(...)
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

  if running() then
    stop()
  end
  local args = { ... }
  if args then
    for i = 1, #args do
      if args[i] == '--files' then
        if args[i + 1] ~= nil then
          -- wrap next arg with ""
          args[i + 1] = [["]] .. args[i + 1] .. [["]]
        end
      end
    end
    vim.list_extend(opts, args)
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
      if type(data) == 'table' then
        for _, line in pairs(data) do
          info = info .. line .. '\n'
          if string.find(line, 'Local') then
            port = vim.fn.matchstr(line, [[\v:\zs\d+$$]])
          end
        end
      end
      utils.log('port:', port)
      vim.notify(info, vim.lsp.log_levels.DEBUG)
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
      log(job_id, data)
      vim.notify(vim.inspect(data), vim.lsp.log_levels.INFO)
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

  -- if vim.o.ft == 'html' then
  --   vim.defer_fn(function()
  --     if job ~= nil and port ~= nil then
  --       local filename = vfn.fnamemodify(vfn.expand('%'), ':~:.')
  --       open(filename)
  --     end
  --   end, 1000)
  -- end

  -- vim.fn.chanclose(job, 'stderr')
  -- vim.fn.chanclose(job, 'stdout')
end

local function restart()
  stop()
  run()
end

local function preview_file()
  local delay = 500
  if not running() then
    run()
    delay = 1000
  end
  vim.defer_fn(function()
    local filename = vfn.fnamemodify(vfn.expand('%'), ':~:.')
    open(filename)
  end, delay)
end

return {
  status = status,
  run = run,
  open = open,
  restart = restart,
  preview = preview_file,
  stop = stop,
}
