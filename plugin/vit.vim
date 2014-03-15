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

            if l:command == "add"
                " call vit#AddFilesToGit((len(l:args) > 1 ? l:cmd_args : expand("%")), 0)
                if len(l:args) > 1
                    call vit#AddFilesToGit(l:cmd_args, 0)
                else
                    call vit#AddCurrentFileToGit(0)
                endif
            elseif l:command == "reset"
                " call vit#ResetFilesInGitIndex((len(l:args) > 1 ? l:cmd_args : expand("%")), 0)
                if len(l:args) > 1
                    call vit#ResetFilesInGitIndex(l:cmd_args, 0)
                else
                    call vit#ResetCurrentFileInGitIndex(0)
                endif
            elseif l:command == "checkout" || l:command == "co"
                " call vit#CheckoutCurrentFile((len(l:args) > 1 ? l:cmd_args : "HEAD"), 0)
                if len(l:args) > 1
                    call vit#GitCheckoutCurrentFile(l:cmd_args)
                else
                    call vit#GitCheckoutCurrentFile("HEAD")
                endif
            elseif l:command == "commit" | call vit#GitCommit(l:cmd_args)
            elseif l:command == "blame" | call vit#PopGitBlame()
            elseif l:command == "log" | call vit#PopGitLog()
            elseif l:command == "diff" | call vit#PopGitDiffPrompt()
            elseif l:command == "status" | call vit#GitStatus()
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

command! -buffer -nargs=? Git :execute Git(<f-args>)

autocmd BufWinEnter * let b:GitDir = GetGitDirectory()

autocmd BufWinLeave *.vitcommitmsg call vit#GitCommitFinish()
autocmd FileType VitStatus,VitLog,VitShow,VitDiff cnoremap <buffer> q call vit#ContentClear()
" autocmd FileType VitStatus,VitLog,VitShow,VitDiff autocmd BufWinLeave call vit#ContentClear()

nnoremap <silent> Uu :call vit#ContentClear()<cr>
" Diff unsaved changes against file saved on disk
nnoremap <silent> Uo :call vit#PopDiff("#")<cr>
nnoremap <silent> Ug :Git diff<cr>
nnoremap <silent> Ub :Git blame<cr>
nnoremap <silent> Ul :Git log<cr>
nnoremap <silent> Us :Git status<cr>

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
