nnoremap <buffer> <silent> v :call vit#HandleRevisionSelection()<cr>
nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call vit#ShowFromLog()<cr>
" nnoremap <buffer> <silent> <enter> :call vit#ShowFromLog()<cr>

if !exists("b:vit_is_standalone")
    nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
" else
    " if !exists("g:vit_log_lastshownrev")
        " let g:vit_log_lastshownrev = ""
    " endif

    " function! LoadLogEntry()
    "     let l:rev = vit#GetRevFromGitLog()
    "     call vit#PopGitShow(l:rev)
    " endfunction

    " autocmd CursorMoved * call LoadLogEntry()

    " call LoadLogEntry()
endif
