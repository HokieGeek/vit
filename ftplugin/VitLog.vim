nnoremap <buffer> <silent> <enter> :call vit#HandleRevisionSelection()<cr>
nnoremap <buffer> <silent> v :call vit#ShowFromLog()<cr>
if exists("b:vit_is_standalone")
    nnoremap <buffer> <silent> q :quitall!<cr>
    nnoremap <buffer> <silent> <esc> :quitall!<cr>
else
    nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
endif
