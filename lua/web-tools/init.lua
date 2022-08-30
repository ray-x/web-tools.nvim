local utils = require('web-tools.utils')
local browser = require('web-tools.browsersync')
local rename = require('web-tools.rename')
local open_browser = require('web-tools.openbrowser')

vim = vim or {}
_WEBTOOLS_CFG = {
  debug = false,
  keymaps = {
    rename = nil,
    repeat_rename = '.',
  },
}

local create_cmd = function(cmd, func, opt)
  opt = vim.tbl_extend('force', { desc = 'web-tools ' .. cmd }, opt or {})
  vim.api.nvim_create_user_command(cmd, func, opt)
end

local function setup(cfg)
  cfg = cfg or {}
  _WEBTOOLS_CFG = vim.tbl_extend('force', _WEBTOOLS_CFG, cfg)

  -- stylua: ignore start
  create_cmd( 'BrowserSync', function() require"web-tools".run() end)
  create_cmd( 'BrowserPreview', function() require"web-tools".preview() end)
  create_cmd( 'BrowserRestart', function() require"web-tools".restart() end)
  create_cmd( 'BrowserStop', function() require"web-tools".stop() end)
  create_cmd( 'BrowserOpen', function() require"web-tools".open() end)
  create_cmd( 'TagRename', function(opts) require"web-tools".rename(unpack(opts.fargs)) end, { nargs = '*' })
  -- stylua: ignore end

  local repeat_key = _WEBTOOLS_CFG.keymaps.repeat_rename
  if vim.fn.empty(repeat_key) == 0 then
    vim.api.nvim_set_keymap(
      'n',
      repeat_key,
      [[<cmd>lua require('web-tools').repeat_rename()<CR>]],
      { silent = true, noremap = true }
    )
  end

  local rename_key = _WEBTOOLS_CFG.keymaps.rename
  if vim.fn.empty(rename_key) == 0 then
    vim.api.nvim_set_keymap(
      'n',
      rename_key,
      [[<cmd>lua require('web-tools').rename()<CR>]],
      { silent = true, noremap = true }
    )
  end
end

return {
  status = browser.status,
  run = browser.run,
  restart = browser.restart,
  stop = browser.stop,
  open = browser.open,
  preview = browser.preview,
  open_url = open_browser.open_url,
  rename = rename.rename,
  repeat_rename = rename.repeat_rename,
  setup = setup,
}
