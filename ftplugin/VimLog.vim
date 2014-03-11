augroup VitLog
    autocmd!
    autocmd Filetype VitLog nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromLog()<cr>
    autocmd Filetype VitLog nnoremap <buffer> <silent> o :call vit#CheckoutFromGitLog()<cr>
    autocmd Filetype VitLog nnoremap <buffer> <silent> v :call vit#ShowFromGitLog()<cr>
    autocmd Filetype VitLog nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
augroup END

