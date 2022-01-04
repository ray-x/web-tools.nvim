local utils = require('web-tools.utils')
local browser = require('web-tools.browsersync')
local rename = require('web-tools.rename')
local open_browser = require('web-tools.openbrowser')
vim = vim or nil
local vfn = vim.fn
local log = utils.log
_WEBTOOLS_CFG = {
  debug = false,
}

return {
  status = browser.status,
  run = browser.run,
  restart = browser.restart,
  stop = browser.stop,
  open = browser.open,
  open_url = open_browser.open_url,
  rename = rename.rename,
  repeat_rename = rename.repeat_rename,
}
