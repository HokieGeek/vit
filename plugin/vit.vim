if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1
let g:vit_commands = ["log", "add", "reset", "checkout", "diff", "blame", "commit", "status", "push", "pull"]

function! vit#GitCompletion(arg_lead, cmd_line, cursor_pos) " {{{
    if a:cmd_line =~# "^Git add "
        let l:files = split(glob(b:vit_root_dir."/".a:arg_lead."*"))
        let l:files = map(l:files, 'v:val.(isdirectory(v:val)?"/":"")')
        let l:files = map(l:files, 'substitute(v:val, b:vit_root_dir."/", "", "")')
        return l:files
    elseif len(split(a:cmd_line)) <= 2
        if a:arg_lead ==? ''
            return g:vit_commands
        else
            return filter(g:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}
function! Git(...) " {{{
    if exists("b:vit_git_dir")
        if a:0 > 0
            " echomsg "Git(".string(a:000).")"
            let l:command = a:1
            let l:cmd_args = join(a:000[1:], ' ')

            if l:command ==# "log" || l:command ==# "lg"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#PopGitFileLog(l:cmd_args)
            elseif l:command ==# "add"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#AddFilesToGit(l:cmd_args)
            elseif l:command ==# "reset"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#ResetFilesInGitIndex(l:cmd_args)
            elseif l:command ==# "checkout" || l:command ==# "co"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "HEAD"
                endif
                call vit#GitCheckoutCurrentFile(l:cmd_args)
            elseif l:command ==# "diff"
                if len(l:cmd_args) <= 0
                    call vit#PopGitDiffPrompt()
                else
                    call vit#PopGitDiff(l:cmd_args)
                endif
            elseif l:command ==# "push"
                if len(l:cmd_args) <= 0
                    call vit#GitPush("", "")
                " elseif a:0 == 2
                    " call vit#GitPush(a:000[1], "")
                elseif a:0 > 2
                    call vit#GitPush(a:000[1], a:000[2])
                endif
            elseif l:command ==# "pull"
                " if len(l:cmd_args) <= 0
                    " call vit#GitPull("", "", 0)
                " else
                    " call vit#GitPull(a:000[2], a:000[3], 0)
                " endif
                call vit#GitPull("TODO", "TODO", 0)
            elseif l:command ==# "commit"
                call vit#GitCommit(l:cmd_args)
            elseif l:command ==# "blame"
                call vit#PopGitBlame()
            elseif l:command ==# "status" || l:command ==# "st"
                call vit#GitStatus()
            else
                echohl WarningMsg
                echomsg "Unrecognized git command: ".l:command
                echohl None
            endif
        else
            call vit#GitStatus()
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

command! DOrig :call vit#PopDiff("#")

autocmd BufWinEnter * call vit#init()

" vim: set foldmethod=marker formatoptions-=tc:
