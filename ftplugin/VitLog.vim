nnoremap <buffer> <silent> <enter> :call vit#HandleRevisionSelection()<cr>
nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
nnoremap <buffer> <silent> v :call vit#ShowFromLog()<cr>
nnoremap <buffer> <silent> <esc> :call vit#ContentClear()<cr>
