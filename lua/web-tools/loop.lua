local tmpfile
local uv = vim.uv or vim.loop
local response = {}
local util = require('web-tools.utils')
local log = util.log
local job_id


-- TODO: use functions in loop.lua
local on_output = function(code, data, event)
  local head_state
  if data[1] == '' then
    table.remove(data, 1)
  end
  if not data[1] then
    log('no data')
    return
  end
  log(code, data, event)

  if event == 'stderr' and #data > 1 then
    log('stderr', data)
    response.body = data
    response.raw = data
    response.headers = {}
    return
  end
  if not tmpfile then
    tmpfile = vim.fn.tempname()
  end
  -- we put all data to tmp file
  local fd = uv.fs_open(tmpfile, 'a', 438)
  for _, line in ipairs(data) do
    -- remove ASCII color code
    line = string.gsub(line, '\27%[[%d;]+m', '')
    print(line)
    -- if the output is a URL of http://localhost:port we can open it in browser
    if string.match(line, 'http://localhost:%d+') then
      vim.notify('open url in browser')
      local _start, _end = string.find(line, 'http://localhost:%d+')
      local url = string.sub(line, _start, _end)
      require"web-tools.openbrowser".open(url)
    end
    uv.fs_write(fd, line .. '\n', -1)
  end
  uv.fs_close(fd)
  log('write to tmpfile', tmpfile)
end
local function proccess_output()
  log('proccess_output', tmpfile)
  local fd = uv.fs_open(tmpfile, 'r', 438)
  if not fd then
    log('no tmpfile')
    return
  end
  local data_str = ''
  -- read all data line by line, seperated by \n
  while true do
    local line = uv.fs_read(fd, 1024, -1)
    -- log('read', line, i, type(line))
    if vim.fn.empty(line) == 1 then
      break
    end
    log(line)
    data_str = data_str .. line
  end
  uv.fs_close(fd)
  -- split data_str by \n
  local data = vim.split(data_str, '\n')

  local status = tonumber(string.match(data[1], '([%w+]%d+)'))
  local head_state = 'start'
  if status then
    response.status = status
    response.headers = { status = data[1] }
    response.headers_str = data[1] .. '\r\n'
  end
  for i = 2, #data do
    local line = data[i]
    if line == '' or line == nil then
      log(i, 'change to body')
      head_state = 'body'
    elseif head_state == 'start' then
      local key, value = string.match(line, '([%w-]+):%s*(.+)')
      if key and value then
        response.headers[key] = value
        response.headers_str = response.headers_str .. line .. '\r\n'
      end
    elseif head_state == 'body' then
      response.body = response.body or ''
      response.body = response.body .. line
    end
  end
  response.raw = data
  -- log(response)
  -- delete tmp file
  os.remove(tmpfile)
  tmpfile = nil
end


local function on_exit(i, code, cmd, callback)
  log('exit job id', i, code)
  if job_id == i then
    job_id = nil
  end
  if code ~= 0 then
    vim.notify(
      string.format(
        'cmd:  %s error exit_code=%s response=%s',
        vim.inspect(cmd),
        code,
        vim.inspect(response)
      )
    )
  end
  proccess_output()
  log(response)

  if callback then
    return callback(response)
  else
    local lines = response.raw or response.body
    if #lines == 0 then
      return
    end
    vim.fn.setqflist({}, ' ', {
      title = string.format('cmd %s finished', cmd),
      lines = lines,
    })
    vim.cmd('copen')
  end
  response.raw = nil
  response.body = nil
  response = {} -- release
end

local function new_job(cmd, args)
  log(cmd)
  args = args or {}
  job_id = vim.fn.jobstart(cmd, {
    on_stdout = args.on_output or on_output,
    on_stderr = args.on_output or on_output,
    on_exit = function(i, code)
      on_exit(i, code, cmd, args.callback)
    end,
  })
  log('job_id created', job_id)
end

vim.api.nvim_create_user_command('StopJob', function(args)
  local jid = job_id
  if args and args[1] then
    jid = tonumber(args[1])
  end
  if jid then
    vim.fn.jobstop(jid)
    if jid == job_id then
      job_id = nil
    end
  end
end, { nargs = '*' })


return {
  tmpfile = tmpfile,
  on_output = on_output,
  proccess_output = proccess_output,
  new_job = new_job,
  on_exit = on_exit,
}
