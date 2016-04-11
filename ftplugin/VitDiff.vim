function! ShowFromDiff()
    let l:rev = b:git_revision
    bdelete
    call vit#PopGitShow(l:rev)
endfunction

nnoremap <buffer> <silent> v :call ShowFromDiff()<cr>

nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
