function! GetRevFromGitBlame()
    let l:rev = system("echo '".getline(".")."' | awk '{ print $1 }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! CheckoutFromBlame()
    let l:rev = GetRevFromGitBlame()
    bdelete
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! ShowFromBlame()
    let l:rev = GetRevFromGitBlame()
    bdelete
    call vit#PopGitShow(l:rev)
endfunction
function! PopGitDiffFromBlame()
    let l:rev = GetRevFromGitBlame()
    let l:file = b:vit_ref_file
    bdelete
    call vit#PopGitDiff(l:rev, l:file)
endfunction

nnoremap <buffer> <silent> <enter> :call PopGitDiffFromBlame()<cr>
nnoremap <buffer> <silent> o :call CheckoutFromBlame()<cr>
nnoremap <buffer> <silent> v :call ShowFromBlame()<cr>
