if exists("g:loaded_broot") || &compatible
  finish
endif
let g:loaded_broot = 1

let s:broot_default_conf = get(g:, 'broot_default_conf', expand('~/.config/broot/conf.toml'))
let s:broot_vim_conf = fnamemodify(resolve(expand('<sfile>:p')), ':h:h').'/broot.toml'
let s:broot_confs = s:broot_default_conf.';'.s:broot_vim_conf

let s:broot_command = get(g:, 'broot_command', 'br')
let s:broot_exec = s:broot_command." --conf '".s:broot_confs."'"

let s:broot_default_edit_command = get(g:, 'broot_default_edit_command', 'edit')

" Opens broot in the given path and opens the file(s) according to edit_cmd
function! s:OpenBrootIn(path, edit_cmd) abort
    let l:path = expand(a:path)
    let l:out_file = tempname()
    silent execute '!'.s:broot_exec." --out '".l:out_file."' ".l:path
    if (filereadable(l:out_file))
        for f in readfile(l:out_file)
            execute a:edit_cmd." ".f
        endfor
        call delete(l:out_file)
    endif
    redraw!
    filetype detect
endfunction

command! BrootCurrentDirectory call s:OpenBrootIn("%:p:h", s:broot_default_edit_command)
command! BrootWorkingDirectory call s:OpenBrootIn(".", s:broot_default_edit_command)
command! Broot BrootWorkingDirectory

" Open Broot in the directory passed by argument
function! s:OpenBrootOnVimLoadDir(argv_path) abort
  " TODO: why not pass straight to OpenBrootIn ?
  let path = expand(a:argv_path)
  " Delete empty buffer created by vim
  bdelete!
  call s:OpenBrootIn(path, 'edit')
endfunction

" To open broot when vim loads a directory
if exists('g:broot_replace_netrw') && g:broot_replace_netrw
  augroup broot_replace_netrw
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd BufEnter * if isdirectory(expand("%")) | call s:OpenBrootOnVimLoadDir("%") | endif
  augroup END
endif
