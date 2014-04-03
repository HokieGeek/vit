autocmd CursorMoved <buffer> execute "let &cursorline=".((line(".") == 1) ? "0" : "1")
nnoremap <buffer> <silent> <enter> :if line(".") != 1<bar>call vit#LoadFileFromStatus(getline("."))<bar>endif<cr>
if exists("b:vit_is_standalone")
    nnoremap <buffer> <silent> q :quitall!<cr>
    nnoremap <buffer> <silent> <esc> :quitall!<cr>
endif
