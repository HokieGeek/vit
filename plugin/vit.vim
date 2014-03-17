function! GetGitDirectory()
    let l:path = expand("%:p:h")
    while(l:path != "/" && len(l:path) > 0)
        if (isdirectory(l:path."/.git") != 0)
            return l:path."/.git"
        endif
        " let l:path = expand(l:path+":h") " Causes infinite loop
        let l:path = system("dirname ".l:path)
        let l:path = substitute(substitute(l:path, '\s*\n*$', '', ''), '^\s*', '', '')
    endwhile
    return ""
endfunction

function! Git(...)
    " echo "Git: ".a:1.": ".a:0
    if exists("b:GitDir")
        if a:0 > 0
            let l:args = split(a:1)
            let l:command = l:args[0]
            let l:cmd_args = join(l:args[1:], ' ')

            if l:command == "log"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "#"
                endif
                call vit#PopGitFileLog(l:cmd_args)
            elseif l:command == "add"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#AddFilesToGit(l:cmd_args, 0)
            elseif l:command == "reset"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#ResetFilesInGitIndex(l:cmd_args, 0)
            elseif l:command == "checkout" || l:command == "co"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "HEAD"
                endif
                call vit#GitCheckoutCurrentFile(l:cmd_args)
            elseif l:command == "diff"
                echomsg "diff: ".len(l:cmd_args).": ".l:cmd_args
                if len(l:cmd_args) <= 0
                    call vit#PopGitDiffPrompt()
                else
                    echomsg "HERE"
                    call vit#PopGitDiff(l:cmd_args)
                endif
            elseif l:command == "blame"
                call vit#PopGitBlame()
            elseif l:command == "commit"
                call vit#GitCommit(l:cmd_args)
            elseif l:command == "status"
                call vit#GitStatus()
            else
                echohl WarningMsg
                echomsg "Unrecognized git command: ".l:command
                echohl None
            endif
        else
            echohl WarningMsg
            echomsg "No command given"
            echohl None
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction

" autocmd BufWinEnter * command! -buffer -complete=file -nargs=? Git :execute Git(<f-args>)
autocmd BufWinEnter * command! -buffer -nargs=? Git :execute Git(<f-args>)
autocmd BufWinEnter * let b:GitDir = GetGitDirectory()

autocmd BufWinLeave *.vitcommitmsg call vit#GitCommitFinish()
" autocmd BufWinLeave * call vit#ExitVitWindow()

nnoremap <silent> Uu :call vit#ContentClear()<cr>
nnoremap <silent> Uo :call vit#PopDiff("#")<cr>
nnoremap <silent> Ug :Git diff<cr>
nnoremap <silent> Ub :Git blame<cr>
nnoremap <silent> Ul :Git log<cr>
nnoremap <silent> Us :Git status<cr>

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
