autocmd CursorMoved <buffer> execute "let &cursorline=".((line(".") == 1) ? "0" : "1")
nnoremap <buffer> <silent> <enter> :execute "wincmd h<bar>edit ".split(getline("."))[1]<cr>
