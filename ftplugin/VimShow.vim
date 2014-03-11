augroup VitShow
    autocmd!
    autocmd Filetype VitShow nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromBuffer()<cr>
    " autocmd Filetype VitShow nnoremap <buffer> <silent> o :call vit#CheckoutFromGitBuffer()<cr>
    autocmd Filetype VitShow nnoremap <buffer> <silent> l :Git log<cr>
    autocmd Filetype VitShow nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
augroup END
