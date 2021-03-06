local util = {}

local os_name = vim.loop.os_uname().sysname
local is_windows = os_name == 'Windows' or os_name == 'Windows_NT'

function util.sep()
  if is_windows then
    return '\\'
  end
  return '/'
end

util.handle_job_data = function(data)
  if not data then
    return nil
  end
  -- Because the nvim.stdout's data will have an extra empty line at end on some OS (e.g. maxOS), we should remove it.
  if data[#data] == '' then
    table.remove(data, #data)
  end
  if #data < 1 then
    return nil
  end
  return data
end

util.log = function(...)
  if lprint ~= nil then
    return lprint(...)
  end
  if _WEBTOOLS_CFG.debug then
    print(...)
  end
end
util.log('ss')
return util
