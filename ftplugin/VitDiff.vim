augroup GitDiff
    autocmd!
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> o :call CheckoutFromGitBuffer()<cr>
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> l :Git log<cr>
    " autocmd Filetype GitDiff nnoremap <buffer> <silent> v :call ShowFromGitBuffer()<cr>
    autocmd Filetype GitDiff nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
augroup END

