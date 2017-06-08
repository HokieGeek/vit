if exists("b:autoloaded_vit_stash") || v:version < 700
    finish
endif
let b:autoloaded_vit_stash = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable nolist cursorline nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

let b:vit.windows.stash = bufnr("%")

let b:content=b:vit.execute("stash list")
" let b:content=vit#Stash("list")
if strlen(b:content) <= 0
    echohl WarningMsg
    echom "No stash entries were generated"
    echohl None
    finish
endif

silent! put=b:content
0d_

function! GetStashIdUnderCursor()
    return substitute(getline("."), ":.*$", "", "")
endfunction

function! s:LoadStashInfo(id)
    let l:diff = b:vit.execute("stash show --stat --patch ".a:id)
    execute s:stash_diff_viewer." wincmd w"
    silent! 1,$d
    silent! put=l:diff
    silent! 0d_
    wincmd p
endfunction

autocmd CursorMoved <buffer> call s:LoadStashInfo(GetStashIdUnderCursor())

nnoremap <buffer> <silent> a :call vit#Stash("apply ".GetStashIdUnderCursor())<cr>
nnoremap <buffer> <silent> P :call vit#Stash("pop")<cr>

botright new
setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
set filetype=VitStashInfo
let s:stash_diff_viewer=winnr()
wincmd p

if len(getline(1, "$")) > 8
    execute "resize ".string(&lines * 0.20)
else
    execute "resize ".string(len(getline(1, "$")) + 1)
endif
