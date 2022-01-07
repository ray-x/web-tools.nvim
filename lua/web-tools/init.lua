local utils = require('web-tools.utils')
local browser = require('web-tools.browsersync')
local rename = require('web-tools.rename')
local open_browser = require('web-tools.openbrowser')
vim = vim or nil
_WEBTOOLS_CFG = {
  debug = false,
  keymaps = {
    rename = '',
    repeat_rename = '.',
  },
}

local function setup(cfg)
  cfg = cfg or {}
  _WEBTOOLS_CFG = vim.tbl_extend('force', _WEBTOOLS_CFG, cfg)
  vim.cmd([[command! BrowserSync lua require"web-tools".run()]])
  vim.cmd([[command! BrowserPreview lua require"web-tools".preview()]])
  vim.cmd([[command! BrowserRestart lua require"web-tools".restart()]])
  vim.cmd([[command! BrowserStop lua require"web-tools".stop()]])
  vim.cmd([[command! BrowserOpen lua require"web-tools".open()]])
  vim.cmd([[command! -nargs=* TagRename lua require"web-tools".rename(<f-args>)]])
  local repeat_key = _WEBTOOLS_CFG.keymaps.repeat_rename or '.'
  if vim.fn.empty(repeat_key) == 0 then
    vim.api.nvim_set_keymap(
      'n',
      repeat_key,
      [[<cmd>lua require('web-tools').repeat_rename()<CR>]],
      { silent = true, noremap = true }
    )
  end

  local rename_key = _WEBTOOLS_CFG.keymaps.rename
  if vim.fn.empty(repeat_key) == 0 then
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
