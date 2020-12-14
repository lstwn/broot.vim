# broot.vim lightweight broot integration plugin for vim

A tiny plugin that integrates [broot](https://github.com/Canop/broot) with vim.
Broot is configured in such a way that when pressing enter *on a file* this file
is opened in vim.
At the same time, your broot `conf.toml` is respected, i.e. only the little
mentioned enter behavior is appended to your defaults!

![demo](demo.gif)

## Installation

Use your favourite vim plugin manager. For instance, with `vim-plug`:

```
Plug 'https://gitlab.com/lstwn/broot.vim'
```

Then try `:Broot` in vim which opens broot in vim's current working directory.

## Customization and Usage

Other than the four commands `:BrootCurrentDirectory`, `:BrootWorkingDirectory`
`:BrootHomeDirectory` and `:Broot`, this plugin does no mappings
at all or defines any further commands.

Here are the arguments to the commands (all args are optional):
```
:Broot <directory> <edit_command>      " supports autocomplete only for directory arg
:BrootHomeDirectory <edit_command>     " supports autocomplete for edit_command arg
:BrootCurrentDirectory <edit_command>  " supports autocomplete for edit_command arg
:BrootWorkingDirectory <edit_command>  " supports autocomplete for edit_command arg

<edit_command> defaults to g:broot_default_edit_command.
<directory> defaults to the current working directory.
```

You might want to set in your `.vimrc`:

```{vim}
" I highly recommend setting something like this:
nnoremap <silent> <leader>e :BrootWorkingDirectory<CR>
nnoremap <silent> - :BrootCurrentDirectory<CR>

" you might want to:
command! BrootWorkingDirectoryNewTab call g:OpenBrootIn(".", "tabedit")
" but you could also do ':Broot . tabedit' as a command!

" adjust path to config (this defaults to '~/.config/broot/conf.toml'):
let g:broot_default_conf_path = "<path/to/broot/conf.toml>"

" set this to replace netrw with broot (off per default):
let g:broot_replace_netrw = 1

" if you want to change the config that is appended on top of your regular
" broot conf.toml set this array of strings (default shown):
let g:broot_vim_conf = [
            \ '[[verbs]]',
            \ 'key = "enter"',
            \ 'execution = ":print_path"',
            \ 'apply_to = "file"',
            \ ]

" adjust broot command with (this defaults to 'br'):
let g:broot_command = 'br'

" adjust default edit/open command (this defaults to 'edit'):
let g:broot_default_edit_command = 'tabedit'
```

## Thanks

Special thanks to [ranger.vim](https://github.com/francoiscabrol/ranger.vim)
for some inspiration and avoidance of some common pitfalls!
