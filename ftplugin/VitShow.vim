nnoremap <buffer> <silent> <enter> :call vit#PopGitDiffFromShow()<cr>
nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
if exists("b:vit_is_standalone")
    nnoremap <buffer> <silent> q :quitall!<cr>
    nnoremap <buffer> <silent> <esc> :quitall!<cr>
    " nnoremap <buffer> <silent> l :silent! bdelete!<bar>Git log<bar>silent! bdelete! #<cr>
    nnoremap <buffer> <silent> l :Git log<cr>
else
    nnoremap <buffer> <silent> l :silent! bdelete!<bar>Git log<cr>
endif
