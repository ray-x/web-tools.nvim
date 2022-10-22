-- https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua
local M = {}

local validate = vim.validate
local vfn = vim.fn
local api = vim.api

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
  local dot = vim.fn.getreg('r')
  log(dot, M)
  -- if dot ~= '' and dot ~= M.dot and dot ~= M.newname then
  --   M.newname = nil
  --   log(M, 'exec normal')
  --   vim.cmd([[execute "normal! ."]])
  --   M.dot = vim.fn.getreg('.')
  --   input = M.dot
  -- end
  if vim.fn.empty(input) == 1 then
    if vim.fn.empty(M.newname) == 1 then
      return
    end
    input = M.newname
  end
  M.rename(input)
end

-- neovim lsp.lua

function M.rename(new_name, options)
  log(new_name, options, 'rename')
  options = options or {}
  local bufnr = options.bufnr or api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({
    bufnr = bufnr,
    name = options.name,
  })
  if options.filter then
    clients = vim.tbl_filter(options.filter, clients)
  end

  -- Clients must at least support rename, prepareRename is optional
  clients = vim.tbl_filter(function(client)
    return client.supports_method('textDocument/rename')
  end, clients)

  if #clients == 0 then
    vim.notify('[LSP] Rename, no matching language servers with rename capability.')
  end

  local has_guihua, floating = pcall(require, 'guihua.floating')
  local win = api.nvim_get_current_win()

  -- Compute early to account for cursor movements after going async
  local cword = vim.fn.expand('<cword>')

  ---@private
  local function get_text_at_range(range, offset_encoding)
    return api.nvim_buf_get_text(
      bufnr,
      range.start.line,
      util._get_line_byte_from_position(bufnr, range.start, offset_encoding),
      range['end'].line,
      util._get_line_byte_from_position(bufnr, range['end'], offset_encoding),
      {}
    )[1]
  end

  local try_use_client
  try_use_client = function(idx, client)
    if not client then
      return
    end

    ---@private
    local function rename(name)
      local params = util.make_position_params(win, client.offset_encoding)
      params.newName = name
      log(params, name)
      local handler = client.handlers['textDocument/rename'] or vim.lsp.handlers['textDocument/rename']

      M.newname = name

      vim.fn.setreg('r', name)
      M.dot = vim.fn.getreg('r')
      client.request('textDocument/rename', params, function(...)
        handler(...)
        try_use_client(next(clients, idx))
      end, bufnr)
    end

    local input_fun = vim.ui.input

    if has_guihua then
      vim.ui.input = floating.input
    end

    if client.supports_method('textDocument/prepareRename') then
      local params = util.make_position_params(win, client.offset_encoding)
      client.request('textDocument/prepareRename', params, function(err, result)
        if err or result == nil then
          if next(clients, idx) then
            try_use_client(next(clients, idx))
          else
            local msg = err and ('Error on prepareRename: ' .. (err.message or '')) or 'Nothing to rename'
            vim.notify(msg, vim.log.levels.INFO)
          end
          return
        end

        if new_name then
          rename(new_name)
          return
        end

        local prompt_opts = {
          prompt = 'New Name: ',
        }
        -- result: Range | { range: Range, placeholder: string }
        if result.placeholder then
          prompt_opts.default = result.placeholder
        elseif result.start then
          prompt_opts.default = get_text_at_range(result, client.offset_encoding)
        elseif result.range then
          prompt_opts.default = get_text_at_range(result.range, client.offset_encoding)
        else
          prompt_opts.default = cword
        end
        vim.ui.input(prompt_opts, function(input)
          if not input or #input == 0 then
            return
          end
          rename(input)
        end)
      end, bufnr)
    else
      assert(client.supports_method('textDocument/rename'), 'Client must support textDocument/rename')
      if new_name then
        log('rename to ', new_name)
        rename(new_name)
        return
      end

      local prompt_opts = {
        prompt = 'New tag name: ',
        default = cword,
      }
      vim.ui.input(prompt_opts, function(input)
        if not input or #input == 0 then
          log('you should input a new tag name')
          return
        end
        log('rename to ', input)
        rename(input)
      end)
    end
  end

  try_use_client(next(clients))
end

return M
