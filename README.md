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

The plugin requires Vim 8 (and its terminal feature) or Neovim >=0.3.0.

It has had minimal testing on Windows.

## Customization

### Configuration

| variable name                           | description                                                                                                 | default value                                                                                |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `g:broot_default_conf_path`             | path to broot's default `conf.toml` (assumes TOML config format per default, adjust if using HJSON!)        | `expand('~/.config/broot/conf.toml')`                                                        |
| `g:broot_vim_conf`                      | appended broot config (list of config lines in TOML format _only_, no HJSON!), required windows             | `[ '[[verbs]]', 'key = "enter"', 'external = "echo +{line} {file}"', 'apply_to = "file"', ]` |
| `g:broot_command`                       | broot launch command                                                                                        | `broot`                                                                                      |
| `g:broot_shell_command`                 | command to launch a shell with command flag (per default it respects your shell choice)                     | `&shell . " " . &shellcmdflag`                                                               |
| `g:broot_redirect_command`              | if changing the `broot_shell_command` you may have to adapt the redirection command to fit your shell       | `>`                                                                                          |
| `g:broot_open_command`                  | open command for files with an ending that matches one specified in `g:broot_external_open_file_extensions` | Linux: `xdg-open`, Mac: `open`, Windows: `start`                                             |
| `g:broot_external_open_file_extensions` | list of file extensions that are opened with `g:broot_open_command`                                         | `['pdf']`                                                                                    |
| `g:broot_default_explore_path`          | default path to explore                                                                                     | `.`                                                                                          |
| `g:broot_replace_netrw`                 | set to TRUE (e.g. 1) if you want to replace netrw (see below)                                               | off                                                                                          |

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

### Windows Specifics

While the plugin works on Windows, it likely needs some specific configuration.
The default `broot_vim_conf` uses `echo` which does not work out of the box on
Windows as it available only as a shell built in and not an executable program.

A couple of options are available to resolve:

#### Install an echo.exe

If an `echo.exe` is located in PATH then the plugin will work. Find one online or
compile one yourself.

#### Update the Command Using a Different Program

You almost certainly have another printing capable program already, or can
install one. Ensure one of the options below is installed and then provide
a value for `g:broot_vim_conf` in your `.vimrc`. Use most of the default
verb, but replace the external command with one of the following:

- [coreutils](https://github.com/uutils/coreutils): `coreutils echo +{line} {file}`
- Python: `python -c "print('+{line} {file}')"`
- Node.js: `node -e "console.log('+{line} {file}')"`
- MinGW and Git Bash have a printf function that can work

Python and Node will be slow - prefer another option if possible.

#### Use PowerShell

Variation of the above. Not recommended as it is slow. Replace the external
command with:

`"powershell.exe -Command \"Write-Output ''+{line} {file}''\""`

Note the escaping of the single quote with another single quote which is
required for the vim string.

### Tip

You might want to set in your `.vimrc`:

```{vim}
nnoremap <silent> <leader>e :BrootWorkingDir<CR>
nnoremap <silent> - :BrootCurrentDir<CR>
```

## Thanks

Special thanks to [ranger.vim](https://github.com/francoiscabrol/ranger.vim)
for some inspiration and avoidance of some common pitfalls!
