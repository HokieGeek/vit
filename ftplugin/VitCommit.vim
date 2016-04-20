if exists("b:autoloaded_vit_commit") || v:version < 700
    finish
endif
let b:autoloaded_vit_commit = 1
scriptencoding utf-8

setlocal modifiable
let b:filename = tempname()

if strlen(b:vit_commit_args) > 0
    call append(line("$"), "echo '# ARGUMENTS: ".b:vit_commit_args)
endif
call append(line("$"), split(vit#ExecuteGit("status -s | awk '{ print \"# \" $0 }'"), "\n"))

function! VitCommit#GitCommitFinish()
    g/^#/d
    g/^\s*$/d
    write

    " Check the size of the file. If it's empty or blank, we don't commmit
    if len(readfile(b:filename)) > 0
        let l:file_args = "--file=".b:filename." ".b:vit_commit_args
        call vit#PerformCommit(l:file_args)
    else
        echohl WarningMsg
        echomsg "Cannot commit without a commit message"
        echohl None
    endif
    silent execute "bdelete! ".b:filename
    call delete(b:filename)
endfunction
cnoremap <silent> <buffer> w execute "silent file ".b:fielname<bar>w<bar>silent 0file
autocmd BufWinLeave <buffer> call VitCommit#GitCommitFinish()

resize 10
normal ggO

" Calling this to make sure we get anything useful from other plugins
" set filetype=gitcommit
