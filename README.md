# broot.vim lightweight broot integration plugin for vim

A tiny plugin that integrates [broot](https://github.com/Canop/broot) with vim.
Broot is configured in such a way that when pressing enter *on a file* this file
is opened in vim.
At the same time, your broot `conf.toml` is respected, i.e. only the little
mentioned enter behavior is appended to your defaults!

## Installation

Use your favourite vim plugin manager. For instance, with `vim-plug`:

```
Plug 'https://gitlab.com/lstwn/broot.vim'
```

Then try `:Broot` in vim which opens broot in vim's current working directory.

## Customization and Usage

Set in your `.vimrc`:

```{vim}
" adjust path to config (this defaults to '~/.config/broot/conf.toml'):
let g:broot_default_conf = "<path/to/broot/conf.toml>"

" adjust broot command with (this defaults to 'br'):
let g:broot_command = 'br'

" adjust default edit/open command (this defaults to 'edit'):
let g:broot_default_edit_command = 'tabedit'

" set this to replace netrw with broot (off per default):
let g:broot_replace_netrw = 1
```

