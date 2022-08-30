# web-tools.nvim

Neovim Wrapper for ❤️ [browser-sync](https://github.com/BrowserSync/browser-sync) and http/ccs LSP.
View your html/css files with a live web server locally

HTML & CSS tag rename, repeat rename action

https://user-images.githubusercontent.com/1681295/187396525-82a387c8-addc-4776-9a03-78da40834d45.mov

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
