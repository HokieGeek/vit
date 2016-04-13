if exists("b:autoloaded_vit_blame") || v:version < 700
    finish
endif
let b:autoloaded_vit_blame = 1
scriptencoding utf-8

call vit#GetGitConfig(b:vit_ref_file)
unlet b:vit_git_dir
call vit#LoadContent(vit#ExecuteGit("blame --date=short ".b:vit_ref_file))

normal f)bbEl
execute "vertical resize ".col(".")
normal 0

setlocal cursorline nomodifiable nonumber nofoldenable
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! MoveVitBlameCursor()
    let l:currline = line(".")
    wincmd h
    execute "normal ".l:currline."gg"
    wincmd p
endfunction

augroup VitBlame
    autocmd!
    autocmd CursorMoved <buffer=1> call MoveVitBlameCursor() " FIXME: buffer=1
augroup END

function! GetRevFromBlame()
    return substitute(getline("."), '^\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction
" function! CheckoutFromBlame()
"     let l:rev = GetRevFromBlame()
"     bdelete
"     call vit#CheckoutCurrentFile(l:rev)
" endfunction

" nnoremap <buffer> <silent> <enter> :call DiffFromRev(GetRevFromBlame(), b:vit_ref_file)<cr>
" nnoremap <buffer> <silent> c :call CheckoutFromBlame()<cr>
nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevFromBlame())<cr>
