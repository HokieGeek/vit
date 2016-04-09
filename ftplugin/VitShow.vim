if !exists("b:vit_is_standalone")
    " nnoremap <buffer> <silent> <esc> :Git log<bar>execute g:vit_log_lastline<cr>
" else
    nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromShow()<cr>
    nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
endif
