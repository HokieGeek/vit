if exists("b:autoloaded_vit_blame") || v:version < 700
    finish
endif
let b:autoloaded_vit_blame = 1
scriptencoding utf-8

call vit#GetGitConfig(b:vit_ref_file)
call vit#LoadContent(vit#ExecuteGit("blame --date=short ".b:vit_ref_file))

function! GetRevFromBlame()
    return substitute(getline("."), '^\([\^0-9a-f]\{7,}\) .*', '\1', '')
endfunction

normal f)bbEl
execute "vertical resize ".col(".")
normal 0

setlocal cursorline nomodifiable nonumber nofoldenable
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! MoveVitBlameCursor() " {{{
    let l:currline = line(".")
    wincmd h
    execute "normal ".l:currline."gg"
    wincmd p
endfunction

augroup VitBlame
    autocmd!
    autocmd CursorMoved <buffer=1> call MoveVitBlameCursor() " FIXME: buffer=1
augroup END
" }}}

nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevFromBlame())<cr>
nnoremap <buffer> <silent> o :call vit#OpenFilesInRevisionAsDiff(GetRevFromBlame())<cr>

" vim: set foldmethod=marker formatoptions-=tc:
