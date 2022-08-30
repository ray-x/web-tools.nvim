# web-tools.nvim

Neovim Wrapper for ❤️ [browser-sync](https://github.com/BrowserSync/browser-sync) and http/ccs LSP.
View your html/css files with a live web server locally

HTML & CSS tag rename, repeat rename action

[![live web server](https://user-images.githubusercontent.com/1681295/187394713-57deae33-4c17-45f0-a41f-5f7a2e75ace7.jpg](https://user-images.githubusercontent.com/1681295/187393112-9eafb5ee-44f3-4ff2-829e-b37841b146c9.mp4 "web tools")

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

### Plug

```vim
Plug 'ray-x/web-tools.nvim'

```

## Setup

```lua
require'web-tools'.setup({
  keymaps = {
    rename = '',  -- by default use same setup of lspconfig
    repeat_rename = '.', -- . to repeat
  },
})

```

## Commands

| command        | Description                            |
| -------------- | -------------------------------------- |
| BrowserSync    | run browser-sync server                |
| BrowserOpen    | preview current file, if browser-sync is not start, start it |
| BrowserPreview | preview current file with browser sync |
| BrowserRestart | restart browser sync                   |
| Browserstop    | stop browser sync                      |
| TagRename {newname}     | rename html tag                        |
