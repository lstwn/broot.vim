# broot.vim

> lightweight [broot](https://github.com/Canop/broot) integration plugin for neovim/vim

A tiny plugin that integrates [broot](https://github.com/Canop/broot) with neovim/vim.
Broot is configured in such a way that when pressing enter _on a file_ this file
is opened in vim.
At the same time, your broot `conf.toml` is respected, i.e. only the little
mentioned enter behavior is appended to your defaults!

![demo](demo.gif)

## Installation

Use your favourite vim plugin manager. For instance, with `vim-plug`:

```
Plug 'lstwn/broot.vim'
```

Then try `:Broot` in vim which opens broot in vim's current working directory
and in the current window
(if not configured differently, see below).

## Compatibility

This plugin is not tested on Windows. It requires Vim 8 (and its terminal
feature) or Neovim >=0.3.0.

---

The plugin changed quite a lot recently, but should now be stable (from 12/2020).

## Customization

### Configuration

| variable name                           | description                                                                                                 | default value                                                                         |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `g:broot_default_conf_path`             | path to broot's default `conf.toml`                                                                         | `expand('~/.config/broot/conf.toml')`                                                 |
| `g:broot_vim_conf`                      | appended broot config (list of lines)                                                                       | `[ '[[verbs]]', 'key = "enter"', 'execution = ":print_path"', 'apply_to = "file"', ]` |
| `g:broot_command`                       | broot launch command                                                                                        | `broot`                                                                               |
| `g:broot_shell_command`                 | command to launch a shell with command flag                                                                 | `sh -c`                                                                               |
| `g:broot_redirect_command`              | if changing the `broot_shell_command` you have to adapt the redirection command to fit your shell           | `>`                                                                                   |
| `g:broot_open_command`                  | open command for files with an ending that matches one specified in `g:broot_external_open_file_extensions` | `xdg-open`                                                                            |
| `g:broot_external_open_file_extensions` | list of file extensions that are opened with `g:broot_open_command`                                         | `['pdf']`                                                                             |
| `g:broot_default_explore_path`          | default path to explore                                                                                     | `.`                                                                                   |
| `g:broot_replace_netrw`                 | set to TRUE (e.g. 1) if you want to replace netrw (see below)                                               | off                                                                                   |

### Commands

Here are the defined commands:

```
command! -nargs=? -complete=command Broot           call g:OpenBrootInPathInWindow(s:broot_default_explore_path, <f-args>)
command! -nargs=? -complete=command BrootCurrentDir call g:OpenBrootInPathInWindow("%:p:h", <f-args>)
command! -nargs=? -complete=command BrootWorkingDir call g:OpenBrootInPathInWindow(".", <f-args>)
command! -nargs=? -complete=command BrootHomeDir    call g:OpenBrootInPathInWindow("~", <f-args>)
```

Command should be a split command, e.g. `:Broot vsplit` or `:Broot tab split`.

### Hijacking netrw

If you set `let g:broot_replace_netrw = 1` in your `.vimrc`,
netrw will not launch anymore if you open a folder but instead launch broot.

If you _additionally_ set `let g:loaded_netrwPlugin = 1` in your `.vimrc`,
not only will netrw not be loaded anymore _at all_ but also the commands
`:Explore`, `:Texplore`, `:Vexplore` and `:Hexplore` are replaced wth broot alternatives.

### Tip

You might want to set in your `.vimrc`:

```{vim}
nnoremap <silent> <leader>e :BrootWorkingDir<CR>
nnoremap <silent> - :BrootCurrentDir<CR>
```

## Thanks

Special thanks to [ranger.vim](https://github.com/francoiscabrol/ranger.vim)
for some inspiration and avoidance of some common pitfalls!
