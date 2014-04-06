if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1
let g:vit_commands = ["log", "add", "reset", "checkout", "diff", "blame", "commit", "status", "push", "pull"]

function! vit#GitCompletion(arg_lead, cmd_line, cursor_pos) " {{{
    " TODO: if arg_lead is 'add', then do a filename completion at b:vit_git_dir
    if len(split(a:cmd_line)) <= 2
        if a:arg_lead == ''
            return g:vit_commands
        else
            return filter(g:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}
function! Git(...) " {{{
    if exists("b:vit_git_dir")
        if a:0 > 0
            echomsg "Git(".string(a:000).")"
            let l:command = a:1
            let l:cmd_args = join(a:000[1:], ' ')

            if l:command == "log" || l:command == "lg"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#PopGitFileLog(l:cmd_args)
            elseif l:command == "add"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#AddFilesToGit(l:cmd_args)
            elseif l:command == "reset"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#ResetFilesInGitIndex(l:cmd_args)
            elseif l:command == "checkout" || l:command == "co"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "HEAD"
                endif
                call vit#GitCheckoutCurrentFile(l:cmd_args)
            elseif l:command == "diff"
                if len(l:cmd_args) <= 0
                    call vit#PopGitDiffPrompt()
                else
                    call vit#PopGitDiff(l:cmd_args)
                endif
            elseif l:command == "push"
                call vit#GitPush("", "")
            elseif l:command == "pull"
                call vit#GitPull("TODO", "TODO", 0)
            elseif l:command == "commit"
                call vit#GitCommit(l:cmd_args)
            elseif l:command == "blame"
                call vit#PopGitBlame()
            elseif l:command == "status" || l:command == "st"
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
