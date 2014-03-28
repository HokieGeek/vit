if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1
let g:vit_commands = ["log", "add", "reset", "checkout", "diff", "blame", "commit", "status", "push", "pull"]

function! vit#GitCompletion(arg_lead, cmd_line, cursor_pos) " {{{
    if len(split(a:cmd_line)) <= 2
        if a:arg_lead == ''
            return g:vit_commands
        else
            return filter(g:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}
function! Git(...) " {{{
    " echo "Git: ".a:1.": ".a:0
    if exists("b:vit_git_dir")
        if a:0 > 0
            let l:command = a:1
            let l:cmd_args = join(a:000[1:], ' ')

            " FIXME: HOLY CRAP WHAT ARE YOU DOING? just get a subset of a:000
            " let l:cmd_args = ""
            " let l:i = 2
            " let l:num_args = a:0
            " while l:i <= l:num_args
                " execute "let l:cmd_args .= ' '.a:".l:i
                " let l:i += 1
            " endwhile

            " echomsg "cmd_args = ".l:cmd_args

            if l:command == "log" || l:command == "lg"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "#"
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
                " echomsg "diff: ".len(l:cmd_args).": ".l:cmd_args
                if len(l:cmd_args) <= 0
                    call vit#PopGitDiffPrompt()
                else
                    " echomsg "HERE"
                    call vit#PopGitDiff(l:cmd_args)
                endif
            elseif l:command == "push"
                call vit#GitPush("TODO", "TODO")
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
            echohl WarningMsg
            echomsg "No command given"
            echohl None
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

autocmd BufWritePost * call vit#RefreshGitStatus()
autocmd BufWinEnter * command! -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :execute Git(<f-args>)
" autocmd BufWinEnter * command! -buffer -complete=file -nargs=* Git :execute Git(<f-args>)
autocmd BufWinEnter * call vit#init()

" autocmd BufWinLeave * call vit#ExitVitWindow()

nnoremap <silent> Uu :call vit#ContentClear()<cr>
nnoremap <silent> Uo :call vit#PopDiff("#")<cr>
nnoremap <silent> Ug :Git diff<cr>
nnoremap <silent> Ub :Git blame<cr>
nnoremap <silent> Ul :Git log<cr>
nnoremap <silent> Us :Git status<cr>

" vim: set foldmethod=marker formatoptions-=tc:
