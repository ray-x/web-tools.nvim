# Liveview.nvim

Neovim Wrapper for browser sync
View your html/css files with a live server

HTML & CSS tag rename, repeat rename action

## Install

Install browser sync

```
npm install -g browser-sync
```

## Plug

```vim
Plug 'ray-x/web-tools.nvim'
```

## Setup

```lua
require'liveview'.setup({
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
| BrowserPreview | preview current file with browser sync |
| BrowserRestart | restart browser sync                   |
| Browserstop    | stop browser sync                      |
| TagRename      | rename html tag                        |
