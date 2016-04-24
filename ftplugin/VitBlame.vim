if exists("b:autoloaded_vit_blame") || v:version < 700
    finish
endif
let b:autoloaded_vit_blame = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

let b:vit = getbufvar(b:vit_ref_bufnr, "vit")
let b:vit.windows.blame = bufnr("%")

let b:result = b:vit.execute("blame --date=short ".b:vit.path.absolute)
silent! put =b:result
0d_

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

function! s:MoveWindowCursor(winnr) " {{{
    let l:currline = line(".")
    execute a:winnr." wincmd w"
    execute "normal ".l:currline."gg"
    wincmd p
endfunction

augroup VitBlame
    autocmd!
    autocmd CursorMoved <buffer> call s:MoveWindowCursor(bufwinnr(b:vit_ref_file))
    execute "autocmd CursorMoved <buffer=".bufnr(b:vit_ref_file)."> call s:MoveWindowCursor(".winnr().")"
augroup END
" }}}

nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevFromBlame())<cr>
nnoremap <buffer> <silent> d :call vit#OpenFilesInRevisionAsDiff(GetRevFromBlame())<cr>

" vim: set foldmethod=marker formatoptions-=tc:
