if exists("b:autoloaded_vit_blame") || v:version < 700
    finish
endif
let b:autoloaded_vit_blame = 1
scriptencoding utf-8

wincmd h
wincmd x

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

let b:vit.windows.blame = bufnr("%")

let b:result = b:vit.repo.execute("blame --date=short ".b:vit.path.absolute)
silent! put =b:result
0d_

normal f)bbE
execute "vertical resize ".col(".")
normal 0

execute bufwinnr(b:vit.bufnr)." wincmd w"
mkview! 9
call setbufvar(b:vit.windows.blame, "vit_blame_starting_linenum", line("."))
setlocal nofoldenable
wincmd p
noautocmd execute b:vit_blame_starting_linenum
unlet b:vit_blame_starting_linenum

function! s:GetRevFromBlame()
    return substitute(getline("."), '^\^\?\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

setlocal cursorline nomodifiable nonumber nofoldenable
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! s:MoveWindowCursor(winnr)
    let l:currline = line(".")
    execute a:winnr." wincmd w"
    execute "normal ".l:currline."gg"
    wincmd p
endfunction

augroup VitBlame
    autocmd!
    autocmd CursorMoved <buffer> call s:MoveWindowCursor(bufwinnr(b:vit.bufnr))
    execute "autocmd CursorMoved <buffer=".b:vit.bufnr."> call s:MoveWindowCursor(".winnr().")"
    execute "autocmd BufWinLeave <buffer> ".bufwinnr(b:vit.bufnr)." wincmd w | silent loadview 9 | let b:vit.windows.blame=-1"
    autocmd BufWinLeave <buffer> autocmd! VitBlame
augroup END
" }}}

autocmd WinEnter,WinLeave,BufEnter <buffer> setlocal statusline=\ 

nnoremap <buffer> <silent> <enter> :call vit#windows#ShowWindow(<SID>GetRevFromBlame())<cr>
nnoremap <buffer> <silent> d :call vit#windows#OpenFilesInRevisionAsDiff(<SID>GetRevFromBlame())<cr>

" vim:set formatoptions-=tc foldmethod=expr foldexpr=getline(v\:lnum)=~#'^\s*fu[nction]*'?'a1'\:getline(v\:lnum)=~#'^\s*endf[unction]*'?'s1'\:'=':
