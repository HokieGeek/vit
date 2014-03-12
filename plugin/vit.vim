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

function! GetGitStatusLine()
    "FIXME 
    let l:branch=vit#GetGitBranch()
    " let l:branch=g:GitBranch
    if len(l:branch) > 0
        " TODO: only update the file status when the file is saved?
        let l:status=vit#GitFileStatus()
        if l:status == 3 " Modified
            let l:hl="%#SL_HL_GitModified#"
        elseif l:status == 4 " Staged and not modified
            let l:hl="%#SL_HL_GitStaged#"
        elseif l:status == 2 " Untracked
            let l:hl="%#SL_HL_GitUntracked#"
        else
            let l:hl="%#SL_HL_GitBranch#"
        endif

        return l:hl."\ ".l:branch."\ "
    else
        return ""
    endif
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

" Highlighting {{{
augroup VitLogHighlighting
    autocmd!
    autocmd Filetype VitLog
        \ highlight CursorLine ctermbg=darkblue ctermfg=white cterm=bold |
        \ highlight VitLogTime ctermbg=none ctermfg=cyan cterm=none | let m = matchadd("VitLogTime", " \(.* ago\) \<") |
        \ highlight VitLogAuthor ctermbg=none ctermfg=green cterm=none | let m = matchadd("VitLogAuthor", "\<.*\> -") |
        \ highlight VitLogMessage ctermbg=none ctermfg=lightgray cterm=none | let m = matchadd("VitLogMessage", "-.*") |
        \ highlight VitLogBranch ctermbg=none ctermfg=yellow cterm=none | let m = matchadd("VitLogBranch", "- \(.*\)") |
        \ highlight VitLogGraph ctermbg=none ctermfg=lightgray cterm=none | let m = matchadd("VitLogGraph", "^[\*\s|/\]* ") |
        \ highlight VitLogDash ctermbg=none ctermfg=lightgray cterm=none | let m = matchadd("VitLogDash", "-")
augroup END

augroup VitShowHighlighting
    autocmd!
    autocmd Filetype VitShow
        \ highlight VitShowCommit ctermbg=none ctermfg=yellow cterm=none | let m = matchadd("VitShowCommit", "^commit .*$") |
        \ highlight VitShowDiffLines ctermbg=none ctermfg=cyan cterm=none | let m = matchadd("VitShowDiffLines", "^@@ .* @@ ") |
        \ highlight VitShowSub ctermbg=none ctermfg=red cterm=none | let m = matchadd("VitShowSub", "^-.*$") |
        \ highlight VitShowAdd ctermbg=none ctermfg=green cterm=none | let m = matchadd("VitShowAdd", "^+.*$") |
        \ highlight VitShowInfo1 ctermbg=none ctermfg=white cterm=bold | let m = matchadd("VitShowInfo1", "^diff --git .*") |
        \ highlight VitShowInfo2 ctermbg=none ctermfg=white cterm=bold | let m = matchadd("VitShowInfo2", "^index .*") |
        \ highlight VitShowInfo3 ctermbg=none ctermfg=white cterm=bold | let m = matchadd("VitShowInfo3", "^--- a.*") |
        \ highlight VitShowInfo4 ctermbg=none ctermfg=white cterm=bold | let m = matchadd("VitShowInfo4", "^+++ b.*")
augroup END

augroup VitStatusHighlighting
    autocmd!
    autocmd Filetype VitStatus
        \ highlight VitStatusColumn2 ctermbg=none ctermfg=darkred cterm=none | let m = matchadd("VitStatusColumn2", "^.. ") |
        \ highlight VitStatusColumn1 ctermbg=none ctermfg=darkgreen cterm=none | let m = matchadd("VitStatusColumn1", "^.") |
        \ highlight VitStatusUntracked ctermbg=none ctermfg=darkred cterm=none | let m = matchadd("VitStatusUntracked", "^\?\? ") |
        \ highlight VitStatusBranch ctermbg=none ctermfg=darkgreen cterm=none | let m = matchadd("VitStatusBranch", "## .*") |
        \ highlight VitStatusBranchHashes ctermbg=none ctermfg=white cterm=none | let m = matchadd("VitStatusBranchHashes", "## ")
augroup END
" }}}

" FileType mappings {{{
" augroup Vit
    " autocmd!
    " autocmd Filetype VitLog nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromLog()<cr>
    " autocmd Filetype VitLog nnoremap <buffer> <silent> o :call vit#CheckoutFromGitLog()<cr>
    " autocmd Filetype VitLog nnoremap <buffer> <silent> v :call vit#ShowFromGitLog()<cr>
    " autocmd Filetype VitLog nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
" augroup END

" augroup GitDiff
    " autocmd!
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> o :call CheckoutFromGitBuffer()<cr>
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> l :Git log<cr>
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> v :call ShowFromGitBuffer()<cr>
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
" augroup END

" augroup VitShow
    " autocmd!
    " autocmd Filetype VitShow nnoremap <buffer> <silent> <enter> :call PopGitDiffFromBuffer()<cr>
    " autocmd Filetype VitShow nnoremap <buffer> <silent> o :call CheckoutFromGitBuffer()<cr>
    " autocmd Filetype VitShow nnoremap <buffer> <silent> l :Git log<cr>
    " autocmd Filetype VitShow nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
" augroup END
" }}}

autocmd BufWinLeave *.vitcommitmsg call vit#GitCommitFinish()
autocmd BufWinEnter * let g:GitDir = GetGitDirectory()

nnoremap <silent> Uu :call vit#ContentClear()<cr>
" Diff current file with a given git revision. If no input given, diffs against head
" nnoremap <silent> Ug :Git diff<cr>
" nnoremap <silent> Ub :Git blame<cr>
" nnoremap <silent> Ul :Git log<cr>
" nnoremap <silent> Us :Git status<cr>

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
