# web-tools.nvim

* Neovim Wrapper for ❤️ [browser-sync](https://github.com/BrowserSync/browser-sync) 
* http/ccs LSP.
* [Hurl/curl](https://hurl.dev/) web API testing

## Fetures
* View your html/css files with a live web server locally
* HTML & CSS tag rename, repeat rename action
* Test your web API with Hurl/curl

### web server live view

https://user-images.githubusercontent.com/1681295/187396525-82a387c8-addc-4776-9a03-78da40834d45.mov


### Test web API with Hurl

![Hurl](https://user-images.githubusercontent.com/1681295/213343683-fae07050-7e9b-45e2-a0f3-380d94105578.jpg)

## Install

- require
  - neovim 0.7+
  - browser-sync
  - optional: lspconfig & vscode-langservers-extracted

### Install browser sync

```
npm install -g browser-sync

```

### LSP for html & cssls

```
npm i -g vscode-langservers-extracted

```

### Instal hurl
[install hurl](https://hurl.dev/docs/installation.html)

### Plug

```vim
Plug 'ray-x/web-tools.nvim'

```

## Setup

```lua
require'web-tools'.setup({
  keymaps = {
    rename = nil,  -- by default use same setup of lspconfig
    repeat_rename = '.', -- . to repeat
  },
  hurl = {  -- hurl default
    show_headers = false, -- do not show http headers
    floating = false,   -- use floating windows (need guihua.lua)
    formatters = {  -- format the result by filetype
      json = { 'jq' },
      html = { 'prettier', '--parser', 'html' },
    },
  },
})

```

## Commands

| command        | Description                            |
| -------------- | -------------------------------------- |
| BrowserSync {args}    | run browser-sync server with args               |
| BrowserOpen {args}    | open browser-sync, if browser-sync is not start, start it with args|
| BrowserPreview {-f --port 3000}| preview current file with browser sync |
| BrowserRestart | restart browser sync                   |
| Browserstop    | stop browser sync                      |
| TagRename {newname}     | rename html tag                        |
| HurlRun {args}     | Run Hurl, when in Visual mode, run selected snippets  |

Note:
{args} is optional, if not provided, check [browser-sync](https://browsersync.io/docs/command-line) for all args options
--port: specify port to open, if BrowserPreview port is different from BrowserSync port, open without check
browser-sync server
