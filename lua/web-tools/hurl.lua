-- hurl is a simple HTTP client using rust
-- this is a lua wrapper for hurl

--[[
-- sample response
HTTP/2 200
date: Wed, 18 Jan 2023 06:59:41 GMT
content-type: application/json; charset=utf-8
content-length: 197
x-powered-by: Express
access-control-allow-origin: *
etag: W/"c5-JcOmw9u3dvyFVM6HmHdGzMiWAPA"
via: 1.1 vegur
cache-control: max-age=14400
cf-cache-status: HIT
age: 2917
accept-ranges: bytes
report-to: {"endpoints":[{"url":"https:\/\/a.nel.cloudflare.com\/report\/v3?s=4TvCUZH1hlni6%2BWyBJ8eaOxLx7QXq9DnBUJ8pcsBFUGxFi14T7syE4B%2FYVGJvj5%2B4cj4yO%2FMJSHnkyzR4tvayPCx1yb2ykmTj8ow6w04nryuEaIXTgfRpQZ%2Bmw%3D%3D"}],"group":"cf-nel","max_age":604800}
nel: {"success_fraction":0,"report_to":"cf-nel","max_age":604800}
server: cloudflare
cf-ray: 78b573069f9aa979-SYD

{"page":5,"per_page":6,"total":12,"total_pages":2,"data":[],"support":{"url":"https://reqres.in/#support-heading","text":"To keep ReqRes free, contributions towards server costs are appreciated!"}}⏎

]]
--
local testdata = {
  'HTTP/2 200',
  'date: Wed, 18 Jan 2023 09:08:10 GMT',
  'accept-ranges: bytes',
  'cf-ray: 78b62f3f1d116a48-SYD',
  '',
  '{"page":2,"per_page":6,"total":12,"total_pages":2,"data":[{"id":7,"email":"michael.lawson@reqres.in","first_name":"Michael","last_name":"Lawson","avatar":"https://reqres.in/img/faces/7-image.jpg"},{"id":8,"email":"lindsay.ferguson@reqres.in","first_name":"Lindsay","last_name":"Ferguson","avatar":"https://reqres.in/img/faces/8-image.jpg"}],"support":{"url":"https://reqres.in/#support-heading","text":"contributions are appreciated!"}}',
}

local util = require('web-tools.utils')
local log = util.log
-- Parse Request -------------------------------------------
------------------------------------------------------------

vim = vim or {}
local response = {}

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
  -- local headers = P.readlines(dump_path)
  local status = tonumber(string.match(data[1], '([%w+]%d+)'))
  head_state = 'start'
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
  log(response)
end

local function format(body, ft)
  if not ft or not body or not _WEBTOOLS_CFG.hurl then
    return
  end
  local formatter = _WEBTOOLS_CFG.hurl.formatters[ft]
  if not formatter then
    log('formatter not setup for ' .. (ft or ''))
    return
  end
  -- jq for json and prettier for html
  local stdout = vim.fn.systemlist(formatter, body)
  if vim.v.shell_error ~= 0 then
    log('formatter failed' .. tostring(vim.v.shell_error))
    return
  end
  return stdout
end

local show_float = function(resp)
  local data = resp.raw or resp.body
  if #data == 0 then
    return
  end
  local has_guihua, textview = pcall(require, 'guihua.textview')
  if not has_guihua then
    util.log('Failed to load guihua.textview')

    log(data)
    vim.fn.setloclist(0, {}, ' ', {
      title = 'hurl response',
      lines = data,
    })
    vim.cmd('lopen')
    return
  end

  local content_type = nil

  -- get content type
  for header, val in pairs(resp.headers) do
    if string.lower(header):find('^content%-type') then
      content_type = val:match('application/(%l+)') or val:match('text/(%l+)')
      break
    end
  end

  local d = format(resp.body, content_type)
  if not d then
    d = resp.raw or { resp.body }
  end

  if not _WEBTOOLS_CFG.hurl.show_headers then
    data = d
    if resp.headers[1] then
      table.insert(data, 1, resp.headers[1])
    end
  end
  local win = textview:new({
    relative = 'cursor',
    syntax = content_type,
    ft = content_type,
    rect = {
      height = 40,
      width = _WEBTOOLS_CFG.floating_width or 90,
      pos_x = 0,
      pos_y = 2,
    },
    enter = true,
    data = data,
  })

  -- log(win)
  if not win then
    log(win.buf)
    vim.api.nvim_buf_set_option(win, 'wrap', true)
    log('draw data', data)
    if not content_type then
      vim.api.nvim_buf_set_option(win.buf, 'filetype', content_type)
    end
    -- vim.api.nvim_win_set_option(win.win, 'number', true)
    win:on_draw(data)
    vim.cmd('setlocal number')
    return
  end
end

-- _WEBTOOLS_CFG = { debug = true }
-- on_output(200, testdata, 'stdout')
-- show_float(response)

local function request(opts, callback)
  local cmd = vim.list_extend({ 'hurl', '-i', '--no-color' }, opts)
  response = {}

  vim.fn.jobstart(cmd, {
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(i, code)
      log('exit', i, code)
      if code ~= 0 then
        vim.notify(
          string.format(
            'hurl: %s error exit_code=%s response=%s',
            vim.inspect(cmd),
            code,
            vim.inspect(response)
          )
        )
      end

      log(response)
      if callback then
        return callback(response)
      else
        if _WEBTOOLS_CFG and _WEBTOOLS_CFG.hurl.floating then
          show_float(response)
        else
          -- show messages

          local lines = response.raw or response.body
          if #lines == 0 then
            return
          end
          vim.fn.setqflist({}, ' ', {
            title = 'hurl finished',
            lines = lines,
          })
          vim.cmd('copen')
        end
      end
    end,
  })
end

-- _WEBTOOLS_CFG = { debug = true, hurl = { floating = true, formatters = { json = 'jq', html = 'prettier' } } }
-- print(vim.fn.getcwd())
-- request({ '../tests/get.http' })

local function run_file(fname, opts)
  opts = opts or {}
  table.insert(opts, fname)
  request(opts)
end

local function run_current_file(opts)
  opts = opts or {}
  table.insert(opts, vim.fn.expand('%:p'))
  request(opts)
end

function trimr(s)
  return (string.gsub(s, '^(%s*.-)%s*$', '%1'))
end

local function curl_to_hurl(args, range)
  local start = 1
  local endl = vim.fn.line('$')

  if range then
    start = vim.fn.getpos("'<")[2]
    endl = vim.fn.getpos("'>")[2]
  end
  local alt_file
  if not args.bang then
    alt_file = vim.fn.expand('%:r') .. '.hurl'
  end

  local line = vim.fn.getline(start)
  line = vim.fn.substitute(line, [[curl .\+ \(\w\+\) ['"]\(.\+\)['"]\( \\\)*]], '\\1 \\2', 'g')

  local write = {}
  line = trimr(line)
  write[#write + 1] = line
  -- vim.fn.setline(1, line)

  local lines = vim.fn.getline(start + 1, endl)
  local json = false
  for i, l in ipairs(lines) do
    line = trimr(l)
    i = i + 1
    if line:find('--header') then
      line = vim.fn.substitute(line, [[--header ['"]\(.\+\):\(.\+\)['"]\( \\\)*]], '\\1:\\2', 'g')
      -- vim.fn.setline(i, line)
      write[#write + 1] = line
    end
    if line:find('--data') then
      write[#write + 1] = '{'
      json = true
    elseif line:find("}'") then
      write[#write + 1] = '}'
      json = false
    elseif json then
      write[#write + 1] = line
    end
  end
  if alt_file then
    vim.fn.writefile(write, alt_file, 'a')
    vim.cmd('edit ' .. alt_file)
  else
    for i, l in ipairs(write) do
      vim.fn.setline(start + i - 1, l)
    end
  end
end

local function run_selection(opts, range)
  opts = opts or {}
  local lines = util.get_visual_selection()
  log(range)
  if not lines then
    return
  end
  local fname = util.create_tmp_file(lines)

  table.insert(opts, fname)
  request(opts)
  vim.defer_fn(function()
    os.remove(fname)
  end, 1000)
end

local function setup()
  util.create_cmd('HurlRun', function(opts)
    if opts.range ~= 0 then
      run_selection(opts.fargs, opts.range)
    else
      require('web-tools.hurl').run_current_file(opts.fargs)
    end
  end, { nargs = '*', range = true })

  util.create_cmd('CurlToHurl', function(opts)
    if opts.range ~= 0 then
      require('web-tools.hurl').curl_to_hurl(opts, opts.range or true)
    else
      require('web-tools.hurl').curl_to_hurl(opts)
    end
  end, { nargs = '*', range = true, bang = true })
end

return {
  request = request,
  on_output = on_output,
  run_current_file = run_current_file,
  run_selection = run_selection,
  run_file = run_file,
  curl_to_hurl = curl_to_hurl,
  setup = setup,
}
