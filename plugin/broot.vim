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

" Opens broot in the given path with the given edit_cmd
function! g:OpenBrootInPathWithEditCmd(...) abort
    let l:path = expand(get(a:, 1, s:broot_default_explore_path))
    let l:edit_cmd = get(a:, 2, s:broot_default_edit_command)
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
    catch
        echoerr "[Broot.vim] Error: " . v:exception
    finally
        filetype detect
        redraw!
    endtry
endfunction

" Opens broot with the given edit_cmd in the given path (simply reversing
" argument order)
function! g:OpenBrootWithEditCmdInPath(...) abort
    let l:edit_cmd = get(a:, 1, s:broot_default_edit_command)
    let l:path = get(a:, 2, s:broot_default_explore_path)
    call g:OpenBrootInPathWithEditCmd(l:path, l:edit_cmd)
endfunction

function! g:GetEditCommandAutocomplete(arg_lead, cmd_line, cursor_pos)
    return ['edit', 'tabedit', 'drop', 'tab drop', 'split', 'vsplit',]
endfunction

command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootCurrentDirectory call g:OpenBrootInPathWithEditCmd("%:p:h", <f-args>)
command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootWorkingDirectory call g:OpenBrootInPathWithEditCmd(".", <f-args>)
command! -nargs=? -complete=customlist,g:GetEditCommandAutocomplete BrootHomeDirectory call g:OpenBrootInPathWithEditCmd("~", <f-args>)
command! -nargs=? -complete=dir BrootHorizontalSplit call g:OpenBrootWithEditCmdInPath('split', <f-args>)
command! -nargs=? -complete=dir BrootVerticalSplit call g:OpenBrootWithEditCmdInPath('vsplit', <f-args>)
command! -nargs=? -complete=dir BrootTab call g:OpenBrootWithEditCmdInPath('tabedit', <f-args>)
command! -nargs=* -complete=dir Broot call g:OpenBrootInPathWithEditCmd(<f-args>)

" To open broot when vim loads a directory
if exists('g:broot_replace_netrw') && g:broot_replace_netrw
    augroup broot_replace_netrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        " order is important for having the path properly resolved, i.e. first
        " expand the path then delete empty buffer created by vim
        autocmd BufEnter * if isdirectory(expand("%")) | call g:OpenBrootInPathWithEditCmd(expand("%"), "edit") | bdelete! # | endif
    augroup END
    if exists(':Explore') != 2
        command! -nargs=? -complete=dir Explore  call g:OpenBrootWithEditCmdInPath('edit', <f-args>)
    endif
    if exists(':Hexplore') != 2
        command! -nargs=? -complete=dir Hexplore call g:OpenBrootWithEditCmdInPath('split', <f-args>)
    endif
    if exists(':Vexplore') != 2
        command! -nargs=? -complete=dir Vexplore call g:OpenBrootWithEditCmdInPath('vsplit', <f-args>)
    endif
    if exists(':Texplore') != 2
        command! -nargs=? -complete=dir Texplore call g:OpenBrootWithEditCmdInPath('tabedit', <f-args>)
    endif
endif
