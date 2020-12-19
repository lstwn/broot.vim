if exists("g:loaded_broot") || &compatible
    finish
endif
let g:loaded_broot = 1

if !has('terminal')
    echoerr '[Broot.vim] Error: Vim version not compatible due to lack of terminal support.'
    finish
endif

let s:broot_default_conf_path = get(g:, 'broot_default_conf_path', expand('~/.config/broot/conf.toml'))
let s:broot_vim_conf_path = fnamemodify(resolve(expand('<sfile>:p')), ':h:h').'/broot.toml'
let s:broot_conf_paths = s:broot_default_conf_path.';'.s:broot_vim_conf_path

let s:broot_vim_conf = get(g:, 'broot_vim_conf', [
            \ '[[verbs]]',
            \ 'key = "enter"',
            \ 'execution = ":print_path"',
            \ 'apply_to = "file"',
            \ ])

call writefile(s:broot_vim_conf, s:broot_vim_conf_path)

let s:broot_command = get(g:, 'broot_command', 'br')
let s:broot_shell_command = get(g:, 'broot_shell_command', &shell.' -c')
let s:broot_exec = s:broot_command." --conf '".s:broot_conf_paths."'"
let s:broot_default_explore_path = get(g:, 'broot_default_explore_path', '.')

let s:out_file = ''

function! g:ReadBrootOutPath(job, exit)
    let l:buffer_number = ch_getbufnr(a:job, 'out')
    try
        if (filereadable(s:out_file))
            for l:file in readfile(s:out_file)
                let l:file = fnamemodify(l:file, ":~:.")
                execute 'edit '.l:file
            endfor
            call delete(s:out_file)
        endif
    catch
        echoerr '[Broot.vim] Error: '.v:exception
    finally
        if bufexists(l:buffer_number)
            silent execute 'bwipeout! '.l:buffer_number
        endif
    endtry
endfunction

" opens broot in the given path and in the given (split) window command
function! g:OpenBrootInPathInWindow(...) abort
    let l:path = expand(get(a:, 1, s:broot_default_explore_path))
    let l:window = get(a:, 2, '')
    let s:out_file = tempname()
    let l:broot_exec = s:broot_shell_command.' "'.s:broot_exec." --out '".s:out_file."' ".l:path.'"'
    execute l:window
    let l:buffer_number = term_start(l:broot_exec, {
                \ "term_name": s:broot_command,
                \ "term_kill": "term",
                \ "curwin": 1,
                \ "exit_cb": "g:ReadBrootOutPath",
                \ "norestore": 1,
                \})
endfunction

" opens broot in the given (split) window command and in the given path
function! g:OpenBrootInWindowInPath(...) abort
    let l:window = get(a:, 1, '')
    let l:path = expand(get(a:, 2, s:broot_default_explore_path))
    call g:OpenBrootInPathInWindow(l:path, l:window)
endfunction

command! -nargs=? -complete=command Broot           call g:OpenBrootInPathInWindow(s:broot_default_explore_path, <f-args>)
command! -nargs=? -complete=command BrootCurrentDir call g:OpenBrootInPathInWindow("%:p:h", <f-args>)
command! -nargs=? -complete=command BrootWorkingDir call g:OpenBrootInPathInWindow(".", <f-args>)
command! -nargs=? -complete=command BrootHomeDir    call g:OpenBrootInPathInWindow("~", <f-args>)

" To open broot when vim loads a directory
if exists('g:broot_replace_netrw') && g:broot_replace_netrw
    augroup broot_replace_netrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        " order is important for having the path properly resolved, i.e. first
        " expand the path then delete empty buffer created by vim
        autocmd BufEnter * if isdirectory(expand("%")) | call g:OpenBrootInPathInWindow(expand("%"), '') | bwipeout! # | endif
    augroup END
    if exists(':Explore') != 2
        command! -nargs=? -complete=dir Explore  call g:OpenBrootInWindowInPath('', <f-args>)
    endif
    if exists(':Hexplore') != 2
        command! -nargs=? -complete=dir Hexplore call g:OpenBrootInWindowInPath('split', <f-args>)
    endif
    if exists(':Vexplore') != 2
        command! -nargs=? -complete=dir Vexplore call g:OpenBrootInWindowInPath('vsplit', <f-args>)
    endif
    if exists(':Texplore') != 2
        command! -nargs=? -complete=dir Texplore call g:OpenBrootInWindowInPath('tab split', <f-args>)
    endif
endif
