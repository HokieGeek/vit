nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromShow()<cr>
nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
nnoremap <buffer> <silent> l :Git log<cr>
nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
