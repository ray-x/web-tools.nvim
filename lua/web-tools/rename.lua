-- https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua
local M = {}

local validate = vim.validate
local vfn = vim.fn

local log = require('web-tools.utils').log
local util = require('vim.lsp.util')
-- local util = require('navigator.util')
-- local rename_prompt = 'Rename -> '

M.newname = nil
M.dot = nil

local function request(method, params, handler)
  validate({
    method = { method, 's' },
    handler = { handler, 'f', true },
  })
  vim.lsp.buf_request(0, method, params, handler)
end

M.repeat_rename = function(input)
  local dot = vim.fn.getreg('.')
  log(dot, M)
  if dot ~= '' and dot ~= M.dot and dot ~= M.newname then
    M.newname = nil
    log(M, 'exec normal')
    vim.cmd([[execute "normal! ."]])
    M.dot = vim.fn.getreg('.')
    return
  end
  if vim.fn.empty(input) == 1 then
    if vim.fn.empty(M.newname) == 1 then
      return
    end
    input = M.newname
  end
  M.rename(input)
end

-- neovim lsp.lua
function M.rename(new_name)
  local opts = {
    prompt = 'rename tag: ',
  }

  print(vim.inspect(new_name))

  ---@private
  local function on_confirm(input)
    if not (input and #input > 0) then
      log('invalid input')
      return
    end
    local params = util.make_position_params()
    params.newName = input
    M.newname = input
    M.dot = vim.fn.getreg('.')
    log(M)
    request('textDocument/rename', params)
  end

  ---@private
  local function prepare_rename(err, result)
    local input_fun = vim.ui.input

    local has_guihua, floating = pcall(require, 'guihua.floating')
    if has_guihua then
      log('gui override')
      input_fun = floating.input
    end
    if err == nil and result == nil then
      vim.notify('nothing to rename', vim.log.levels.INFO)
      return
    end
    if result and result.placeholder then
      opts.default = result.placeholder
      if not new_name then
        pcall(vim.ui.input, opts, on_confirm)
      end
    elseif result and result.start and result['end'] and result.start.line == result['end'].line then
      local line = vfn.getline(result.start.line + 1)
      local start_char = result.start.character + 1
      local end_char = result['end'].character
      opts.default = string.sub(line, start_char, end_char)
      if not new_name then
        pcall(vim.ui.input, opts, on_confirm)
      end
    else
      -- fallback to guessing symbol using <cword>
      --
      -- this can happen if the language server does not support prepareRename,
      -- returns an unexpected response, or requests for "default behavior"
      --
      -- see https://microsoft.github.io/language-server-protocol/specification#textDocument_prepareRename
      opts.default = vfn.expand('<cword>')
      if not new_name then
        pcall(input_fun, opts, on_confirm)
      end
    end
    if new_name then
      on_confirm(new_name)
    end
  end
  request('textDocument/prepareRename', util.make_position_params(), prepare_rename)
end

return M
