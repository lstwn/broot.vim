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

let s:broot_open_commmand = get(g:, 'broot_open_commmand', 'xdg-open')
let s:broot_external_open_file_extensions = get(g:, 'broot_external_open_file_extensions', ['pdf'])
let s:broot_command = get(g:, 'broot_command', 'br')
let s:broot_shell_command = get(g:, 'broot_shell_command', &shell.' '.&shellcmdflag)
let s:broot_exec = s:broot_command." --conf '".s:broot_conf_paths."'"
let s:broot_default_explore_path = get(g:, 'broot_default_explore_path', '.')

let s:out_file = ''
let s:current_buffer = 0
let s:alternate_buffer = 0
let s:is_current_window = 0

function! g:ReadBrootOutPath(job, exit)
    let l:buffer_number = ch_getbufnr(a:job, 'out')
    try
        let l:aborted = 1
        if (filereadable(s:out_file))
            for l:file in readfile(s:out_file)
                let l:file = fnamemodify(l:file, ":~:.")
                let l:file_extension = fnamemodify(l:file, ':e')
                if index(s:broot_external_open_file_extensions, l:file_extension) >= 0
                    silent execute '!'.s:broot_open_commmand.' '.l:file.' 2>/dev/null'
                    redraw!
                else
                    execute 'edit '.l:file
                    let l:aborted = 0
                endif
            endfor
            call delete(s:out_file)
        endif
    catch
        echoerr '[Broot.vim] Error: '.v:exception
    finally
        if l:aborted
            if s:is_current_window
                silent execute 'buffer '.s:current_buffer
            endif
            let @# = s:alternate_buffer
        else
            let @# = s:current_buffer
        endif
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
    if l:window ==# ''
        let s:is_current_window = 1
    else
        execute l:window
        let s:is_current_window = 0
    endif
    let s:current_buffer = bufnr(@%)
    let s:alternate_buffer = bufnr(@#)
    " keepalt does not work here apparently (due to function call instead of
    " a command, c.f. :h alternate-file)
    let l:buffer_number = term_start(l:broot_exec, {
                \ "term_name": s:broot_command,
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
