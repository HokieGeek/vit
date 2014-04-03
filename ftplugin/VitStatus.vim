autocmd CursorMoved <buffer> execute "let &cursorline=".((line(".") == 1) ? "0" : "1")
nnoremap <buffer> <silent> <enter> :if line(".") != 1<bar>execute "wincmd h<bar>edit ".split(getline("."))[1]<bar>endif<cr>
