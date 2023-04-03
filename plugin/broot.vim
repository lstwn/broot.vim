if exists("g:loaded_broot") || &compatible
    finish
endif
let g:loaded_broot = 1

function s:GetNVimVersion()
    redir => s
    silent! version
    redir END
    return matchstr(s, 'NVIM v\zs[^\n]*')
endfunction

function s:GetBrootVersion(broot_command)
    silent let l:version = trim(system(a:broot_command." --version"))
    return l:version
endfunction

function! s:CreateEnv()
    let env = {
        \ "os": { "name": "", "open_command": "" },
        \ "vim": {
        \     "type": "vim", "version": v:version, "terminal": v:false,
        \     "settings": {
        \              "shell": &shell,
        \              "shellcmdflag": &shellcmdflag,
        \              "shellredir": &shellredir,
        \          },
        \     },
        \ }

    let os = env.os
    if has("linux")
        let os.name = "linux"
        let os.open_command = "xdg-open"
    endif
    if has("mac")
        let os.name = "mac"
        let os.open_command = "open"
    endif
    if has("win32")
        let os.name = "win32"
        let os.open_command = "start"
    endif

    let vim = env.vim
    if has("nvim")
        let vim.type = "nvim"
        if has("nvim-0.3.0")
            let vim.terminal = v:true
        endif
        let vim.version = s:GetNVimVersion()
    else
        if has("terminal")
            let vim.terminal = v:true
        endif
    endif

    return env
endfunction

function! s:IsCompatible(env)
    return a:env.vim.terminal
endfunction

function! s:CreateConfig(env)
    let l:config = {
        \ "env": a:env,
        \ "settings": {
        \     "broot_default_conf_path": get(g:, "broot_default_conf_path", expand("~/.config/broot/conf.toml")),
        \     "broot_vim_conf": get(g:, "broot_vim_conf", [
        \         '[[verbs]]',
        \         'key = "enter"',
        \         'external = "echo +{line} {file}"',
        \         'apply_to = "file"',
        \     ]),
        \     "open_commmand": get(g:, "broot_open_command", a:env.os.open_command),
        \     "external_open_file_extensions": get(g:, "broot_external_open_file_extensions", ["pdf"]),
        \     "broot_command": get(g:, "broot_command", "broot"),
        \     "shell_command": get(g:, "broot_shell_command", &shell . " " . &shellcmdflag),
        \     "redirect_command": get(g:, "broot_redirect_command", &shellredir),
        \     "default_explore_path": get(g:, "broot_default_explore_path", "."),
        \ },
        \ }

    if !filereadable(l:config.settings.broot_default_conf_path)
        throw "Path to your broot config '".l:config.settings.broot_default_conf_path."' is invalid. Please adjust g:broot_default_conf_path variable to point to its location."
    endif

    let l:config.env.broot = s:GetBrootVersion(l:config.settings.broot_command)

    call writefile(l:config.settings.broot_vim_conf, s:broot_vim_conf_path)

    let l:broot_conf_paths = l:config.settings.broot_default_conf_path . ";" . s:broot_vim_conf_path
    let l:config.broot_exec = l:config.settings.broot_command . " --conf '" . l:broot_conf_paths . "'"

    return l:config
endfunction

let s:env = s:CreateEnv()

" expand("<sfile>:p") must be called at the top level of the script or
" it returns the stack trace and not the relative path, see:
" https://github.com/vim/vim/issues/9178#issuecomment-974887056
let s:broot_vim_conf_path = fnamemodify(resolve(expand("<sfile>:p")), ":h:h") . "/broot.toml"

try
    if !s:IsCompatible(s:env)
        throw "(n)VIM version not compatible due to lack of terminal support."
    endif
    let s:config = s:CreateConfig(s:env)
catch
    echoerr "[Broot.vim] Error: ".v:exception
    finish
endtry

function! g:BrootLogConfig()
    return json_encode(s:config)
endfunction

" type BrootSession = Record<JobId (nvim) | BufNr (vim), { 
"   out_file: string,
"   terminal_buffer: int,
"   current_buffer: int,
"   alternate_buffer: int,
"   launched_in_active_window: bool
" }>;
let s:sessions = {}

function! s:OnTerminalExit(session)
    let l:out_file = a:session.out_file
    let l:aborted = 1
    try
        if (filereadable(l:out_file))
            for l:line in readfile(l:out_file)
                let l:lineoffset = matchstr(l:line, '+\d\+')
                let l:path = l:line[len(l:lineoffset)+1:-1]
                let l:path = fnamemodify(l:path, ":~:.")
                let l:file_extension = fnamemodify(l:path, ":e")
                if index(s:config.settings.external_open_file_extensions, l:file_extension) >= 0
                    let l:cmd = "!".s:config.settings.open_commmand." '".l:path."' 2>/dev/null"
                    silent execute l:cmd
                    redraw!
                else
                    let l:cmd = "edit ".l:lineoffset." ".l:path
                    execute l:cmd
                    let l:aborted = 0
                endif
            endfor
            call delete(l:out_file)
        endif
    catch
        echoerr "[Broot.vim] Error: ".v:exception
    finally
        let l:terminal_buffer = a:session.terminal_buffer
        let l:current_buffer = a:session.current_buffer
        let l:alternate_buffer = a:session.alternate_buffer
        let l:launched_in_active_window = a:session.launched_in_active_window
        if l:aborted
            " order is important: first switch to old buffer, *then* update
            " alternate buffer
            if l:launched_in_active_window && bufexists(l:current_buffer)
                silent execute "buffer ".l:current_buffer
            endif
            if bufexists(l:alternate_buffer)
                let @# = l:alternate_buffer
            endif
        else
            if bufexists(l:current_buffer)
                let @# = l:current_buffer
            endif
        endif
        if bufexists(l:terminal_buffer)
            silent execute "bwipeout! ".l:terminal_buffer
        endif
    endtry
endfunction

function! g:OnTerminalExitNvim(job_id, code, event)
    let l:session = s:sessions[a:job_id]
    call s:OnTerminalExit(l:session)
    unlet s:sessions[a:job_id]
endfunction

function! g:OnTerminalExitVim(job, exit)
    let l:terminal_buffer = ch_getbufnr(a:job, "out")
    let l:session = s:sessions[l:terminal_buffer]
    call s:OnTerminalExit(l:session)
    unlet s:sessions[l:terminal_buffer]
endfunction

function! s:OpenTerminal(command, session) abort
    if has("nvim")
        " do not replace the current buffer
        enew
        let l:job_id = termopen(a:command, {
                    \ "on_exit": "g:OnTerminalExitNvim",
                    \})
        " rename the terminal buffer name to
        " something more readable than the long gibberish
        execute "file ".s:config.settings.broot_command." ".l:job_id
        let a:session.terminal_buffer = bufnr()
        let s:sessions[l:job_id] = a:session
        " for a clean terminal (the TermOpen autocmd does not work when
        " starting nvim with a directory)
        startinsert
        setlocal nonumber norelativenumber signcolumn=no colorcolumn=0
    else
        let l:terminal_buffer = term_start(a:command, {
                    \ "term_name": s:config.settings.broot_command,
                    \ "curwin": 1,
                    \ "exit_cb": "g:OnTerminalExitVim",
                    \ "norestore": 1,
                    \})
        let a:session.terminal_buffer = l:terminal_buffer
        let s:sessions[l:terminal_buffer] = a:session
    endif
endfunction

" opens broot in the given path and in the given (split) window command
function! g:OpenBrootInPathInWindow(...) abort
    let l:path = expand(get(a:, 1, s:config.settings.default_explore_path))
    let l:path = isdirectory(l:path) ? l:path : s:config.settings.default_explore_path
    let l:window = get(a:, 2, "")
    let l:session = { "out_file": tempname() }
    let l:command = s:config.settings.shell_command.' "'.s:config.broot_exec." '".l:path."' ".s:config.settings.redirect_command." ".l:session.out_file.'"'
    if l:window ==# ""
        let l:session.launched_in_active_window = 1
    else
        execute l:window
        let l:session.launched_in_active_window = 0
    endif
    let l:session.current_buffer = bufnr(@%)
    let l:session.alternate_buffer = bufnr(@#)
    " keepalt does not work here apparently
    " (due to function call instead of a command, c.f. :h alternate-file)
    call s:OpenTerminal(l:command, l:session)
endfunction

" opens broot in the given (split) window command and in the given path
function! g:OpenBrootInWindowInPath(...) abort
    let l:window = get(a:, 1, "")
    let l:path = expand(get(a:, 2, s:config.settings.default_explore_path))
    call g:OpenBrootInPathInWindow(l:path, l:window)
endfunction

command! -nargs=? -complete=command Broot           call g:OpenBrootInPathInWindow(s:config.settings.default_explore_path, <f-args>)
command! -nargs=? -complete=command BrootCurrentDir call g:OpenBrootInPathInWindow("%:p:h", <f-args>)
command! -nargs=? -complete=command BrootWorkingDir call g:OpenBrootInPathInWindow(".", <f-args>)
command! -nargs=? -complete=command BrootHomeDir    call g:OpenBrootInPathInWindow("~", <f-args>)

" To open broot when vim loads a directory
if exists("g:broot_replace_netrw") && g:broot_replace_netrw
    augroup broot_replace_netrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        " order is important for having the path properly resolved, i.e. first
        " expand the path then delete empty buffer created by vim
        autocmd BufEnter * if isdirectory(expand("%")) | call g:OpenBrootInPathInWindow(expand("%"), "") | bwipeout! # | endif
    augroup END
    if exists(":Explore") != 2
        command! -nargs=? -complete=dir Explore  call g:OpenBrootInWindowInPath("", <f-args>)
    endif
    if exists(":Hexplore") != 2
        command! -nargs=? -complete=dir Hexplore call g:OpenBrootInWindowInPath("split", <f-args>)
    endif
    if exists(":Vexplore") != 2
        command! -nargs=? -complete=dir Vexplore call g:OpenBrootInWindowInPath("vsplit", <f-args>)
    endif
    if exists(":Texplore") != 2
        command! -nargs=? -complete=dir Texplore call g:OpenBrootInWindowInPath("tab split", <f-args>)
    endif
endif
