if exists("g:autoloaded_vit_show") || v:version < 700
    finish
endif
let g:autoloaded_vit_show = 1
scriptencoding utf-8

function! GetRevFromGitShow()
    return substitute(getline(1), '^commit \([0-9a-f].*\)$', '\1', '')
endfunction

if !exists("b:vit_is_standalone")
    " nnoremap <buffer> <silent> <esc> :Git log<bar>execute g:vit_log_lastline<cr>
" else
    function! PopGitDiffFromShow()
        let l:rev = b:git_revision
        let l:file = b:vit_ref_file
        bdelete
        call vit#PopGitDiff(l:rev, l:file)
    endfunction
    nnoremap <buffer> <silent> <enter> :call PopGitDiffFromShow()<cr>
    " nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
endif
nnoremap <buffer> <silent> o :call vit#OpenFilesInCommit(GetRevFromGitShow())<cr>
