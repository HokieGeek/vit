function! GetGitDirectory()
    let l:path = expand("%:p:h")
    while(l:path != "/" && len(l:path) > 0)
        if (isdirectory(l:path."/.git") != 0)
            return l:path."/.git"
        endif
        let l:path = system("dirname ".l:path)
        let l:path = substitute(substitute(l:path, '\s*\n*$', '', ''), '^\s*', '', '')
    endwhile
    return ""
endfunction

function! Git(command)
    if a:command == "blame"
        call vit#PopGitBlame()
    elseif a:command == "log"
        call vit#PopGitLog()
    elseif a:command == "diff"
        call vit#PopGitDiffPrompt()
    elseif a:command == "add"
        call vit#AddFileToGit(0)
    elseif a:command == "reset"
        call vit#ResetFileInGitIndex(0)
    elseif a:command == "status"
        call vit#GitStatus()
    elseif a:command == "commit"
        call vit#GitCommit()
    elseif a:command == "checkout"
        echo "TODO: checkout"
        " call vit#GitCheckout()
    else
        echoerr "Unrecgonized git command: ".a:command
    endif
endfunction

command! -nargs=1 Git :execute Git(<q-args>)

autocmd BufWinLeave *.vitcommitmsg call vit#GitCommitFinish()
autocmd BufWinEnter * let g:GitDir = GetGitDirectory()

nnoremap <silent> Uu :call vit#ContentClear()<cr>

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
