vim = vim or {}
_WEBTOOLS_CFG = {
  debug = false,
  keymaps = {
    rename = nil,
    repeat_rename = '.',
  },
  port = nil,
  hurl = {
    show_headers = false,
    floating = true,
    formatters = {
      json = { 'jq' },
      html = { 'prettier', '--parser', 'html' },
    },
  },
}

local browser = require('web-tools.browsersync')
local rename = require('web-tools.rename')
local open_browser = require('web-tools.openbrowser')

-- TODO: to be improved
function _G.__dot_repeat_rename(motion)
  if motion == nil then
    vim.o.operatorfunc = 'v:lua.__dot_repeat_'
    return 'g@'
  end

  -- print('counter:', counter, 'motion:', motion)
  -- counter = counter + 1
end

local create_cmd = function(cmd, func, opt)
  opt = vim.tbl_extend('force', { desc = 'web-tools ' .. cmd }, opt or {})
  vim.api.nvim_create_user_command(cmd, func, opt)
end

local function setup(cfg)
  cfg = cfg or {}
  _WEBTOOLS_CFG = vim.tbl_extend('force', _WEBTOOLS_CFG, cfg)

  -- stylua: ignore start
  create_cmd( 'BrowserSync', function(opts) require"web-tools".run(opts.args) end, { nargs = '*' })
  create_cmd( 'BrowserPreview', function(opts)
    require"web-tools".preview(opts.fargs) end, { nargs = '*' })
  create_cmd( 'BrowserRestart', function(opts) require"web-tools".restart(opts.fargs) end, { nargs = '*' })
  create_cmd( 'BrowserStop', function() require"web-tools".stop() end)
  create_cmd( 'BrowserOpen', function(opts)
    require"web-tools".open(opts.fargs) end, { nargs = '*' })
  create_cmd( 'TagRename', function(opts) require"web-tools".rename(opts) end, { nargs = '*' })
  -- stylua: ignore end

  local repeat_key = _WEBTOOLS_CFG.keymaps.repeat_rename
  if vim.fn.empty(repeat_key) == 0 then
    vim.keymap.set('n', repeat_key, function()
      require('web-tools').repeat_rename()
    end, { silent = true, noremap = true, desc = 'webtool renmae' })
  end

  local rename_key = _WEBTOOLS_CFG.keymaps.rename
  if vim.fn.empty(rename_key) == 0 then
    vim.keymap.set('n', rename_key, function()
      require('web-tools').rename()
    end, { silent = true, noremap = true, desc = 'repeat rename' })
  end
  require('web-tools.hurl').setup()
end

return {
  status = browser.status,
  run = browser.run,
  restart = browser.restart,
  stop = browser.stop,
  open = browser.open,
  preview = browser.preview_file,
  open_url = open_browser.open_url,
  rename = rename.rename,
  repeat_rename = rename.repeat_rename,
  setup = setup,
}
