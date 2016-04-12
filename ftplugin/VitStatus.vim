function! LoadFileFromStatus(line)
    let l:file = b:vit_root_dir."/".split(a:line)[1]
    execute bufwinnr(l:file)."wincmd w"
    if bufloaded(l:file)
        call vit#PopGitDiff('', '')
    else
        execute "edit ".l:file
    endif
endfunction

autocmd CursorMoved <buffer> execute "let &cursorline=".((line(".") == 1) ? "0" : "1")
nnoremap <buffer> <silent> <enter> :if line(".") != 1<bar>call LoadFileFromStatus(getline("."))<bar>endif<cr>
" if exists("b:vit_is_standalone")
    " nnoremap <buffer> <silent> q :quitall!<cr>
    " nnoremap <buffer> <silent> <esc> :quitall!<cr>
" endif
