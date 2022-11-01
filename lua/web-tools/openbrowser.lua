local M = {}
vim = vim or nil
local api = vim.api
local vfn = vim.fn
local exists = vfn.exists
local has = vfn.has
local empty = vfn.empty
local winsaveview = vfn.winsaveview
local executable = vfn.executable
local searchpair = vfn.searchpair
local matchstr = vfn.matchstr
local winrestview = vfn.winrestview
local getline = vfn.getline
local line = vfn.line
local col = vfn.col
local util = require('web-tools.utils')
local log = function(...)
  print(vim.inspect(...))
end

-- https://github.com/tyru/open-browser.vim/blob/master/autoload/vital/openbrowser.vim
-- https://github.com/baiyunping333/newvim/blob/master/plugin/openbrowser.vim
-- https://gist.github.com/habamax/0a6c1d2013ea68adcf2a52024468752e

local function open_cmd()
  local cmd = ':sclient !open'
  if exists('$WSLENV') ~= 0 then
    vim.cmd('lcd /mnt/c')
    cmd = ':silent !cmd.exe /C start'
  elseif has('win32') ~= 0 or has('win32unix') ~= 0 then
    cmd = ':silent !start'
  elseif executable('xdg-open') == 1 then
    cmd = ':silent !xdg-open'
  elseif executable('open') == 1 then
    cmd = ':silent !open'
  else
    vim.notify(' platform not supported ', vim.lsp.log_levels.ERROR)
  end
  return cmd
end

local function open_url(url)
  local cmd = open_cmd()
  local rx_base = [[\%(\%(http\|ftp\|irc\)s\?\|file\)://\S]]
  local rx_bare = rx_base .. [[\+]]
  local rx_embd = rx_base .. [[\{-}]]
  if url ~= nil and url:sub(1, 4) == 'www.' then
    url = 'http://' .. url
  end
  if url then
    cmd = cmd .. ' "' .. vfn.escape(url, '#%!') .. '"'
    if util.is_windows() then
      cmd = cmd .. ' ' .. vfn.escape(url, '#%!')
    end
    log(cmd)
    vim.cmd(cmd)
    return
  end

  -- asciidoc URL http://github.com[queries]
  if empty(url) == 1 then
    local save_view = winsaveview()
    if searchpair(rx_bare .. '[', '', [[]\zs]], 'cW', '', line('.')) > 0 then
      url = matchstr(string.sub(getline('.'), col('.'), -1), [[\S\{-}\ze[]])
    end
    winrestview(save_view)
  end

  -- HTML URL <a href='http://www.python.org'>Python is here</a> <a href='http://www.google.com'>google is here</a>

  --          <a href="http://www.python.org"/>
  if empty(url) == 1 then
    local save_view = winsaveview()
    local m = searchpair([[<as+href=]], '', [[\(</a>\|/>\)\zs]], 'cW', '', line('.'))
    if m > 0 then
      -- print(getline('.'):sub(col('.') - 1, -1))
      url = matchstr(getline('.'), [[href=["'."'".']\?\zs\S\{-}\ze["'."'".']\?/\?>]])
      print(url)
    end
    winrestview(save_view)
  end

  -- HTML URL <a href='http://www.python.org'>Python is here</a>
  if empty(url) == 1 then
    url = matchstr(vfn.expand('<cfile>'), rx_bare)
  end
  if empty(url) == 1 then
    return
  end
  print(cmd)
  cmd = cmd .. ' "' .. vfn.escape(url, '#%!') .. '"'
  print('cmd', cmd)
  vim.cmd(cmd)

  if exists('$WSLENV') ~= 0 then
    vim.cmd('lcd -')
  end
end

-- open_url('http://www.google.com')
return {
  open = open_url,
}
