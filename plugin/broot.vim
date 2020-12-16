if exists("g:loaded_broot") || &compatible
    finish
endif
let g:loaded_broot = 1

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
let s:broot_exec = s:broot_command." --conf '".s:broot_conf_paths."'"

let s:broot_default_edit_command = get(g:, 'broot_default_edit_command', 'edit')
let s:broot_default_explore_path = get(g:, 'broot_default_explore_path', '.')

" Opens broot in the given path and opens the file(s) according to edit_cmd
function! g:OpenBrootIn(...) abort
    let l:edit_cmd = get(a:, 2, s:broot_default_edit_command)
    let l:path = expand(get(a:, 1, s:broot_default_explore_path))
    let l:out_file = tempname()
    try
        silent execute '!'.s:broot_exec." --out '".l:out_file."' ".l:path
        if (filereadable(l:out_file))
            for l:file in readfile(l:out_file)
                let l:file = fnamemodify(l:file, ":~:.")
                execute l:edit_cmd." ".l:file
            endfor
            call delete(l:out_file)
        endif
        filetype detect
    catch
        echoerr "[Broot.vim] Error: " . v:exception
    finally
        redraw!
    endtry
endfunction

function! g:GetEditCommandAutocomplete(arg_lead, cmd_line, cursor_pos)
    return ['edit', 'tabedit', 'drop', 'tab drop', 'split', 'vsplit',]
endfunction

command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootCurrentDirectory call g:OpenBrootIn("%:p:h", <f-args>)
command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootWorkingDirectory call g:OpenBrootIn(".", <f-args>)
command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootHomeDirectory call g:OpenBrootIn("~", <f-args>)
command! -nargs=? -complete=dir BrootHorizontalSplit call g:OpenBrootIn(<f-args>, 'split')
command! -nargs=? -complete=dir BrootVerticalSplit call g:OpenBrootIn(<f-args>, 'vsplit')
command! -nargs=? -complete=dir BrootTab call g:OpenBrootIn(<f-args>, 'tabedit')
command! -nargs=* -complete=dir Broot call g:OpenBrootIn(<f-args>)

" Open Broot in the directory passed by argument
function! s:OpenBrootOnVimLoadDir(argv_path) abort
    " Delete empty buffer created by vim
    bdelete!
    call g:OpenBrootIn(a:argv_path, 'edit')
endfunction

" To open broot when vim loads a directory
if exists('g:broot_replace_netrw') && g:broot_replace_netrw
    augroup broot_replace_netrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        autocmd BufEnter * if isdirectory(expand("%")) | call s:OpenBrootOnVimLoadDir("%") | endif
    augroup END
    command! -nargs=0 Explore  call g:OpenBrootIn(s:broot_default_explore_path, 'edit')
    command! -nargs=0 Hexplore call g:OpenBrootIn(s:broot_default_explore_path, 'split')
    command! -nargs=0 Vexplore call g:OpenBrootIn(s:broot_default_explore_path, 'vsplit')
    command! -nargs=0 Texplore call g:OpenBrootIn(s:broot_default_explore_path, 'tabedit')
endif
