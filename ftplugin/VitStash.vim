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

let b:content=vit#commands#Stash("list")
if strlen(b:content) <= 0
    if tabpagenr('$') == 1
        quitall!
    else
        quit!
        echohl WarningMsg
        echom "No stash entries found"
        echohl None
    endif
    finish
endif

silent! 1,$d
silent! put=b:content
0d_

setlocal nomodifiable

" Functions " {{{
function! s:GetStashIdUnderCursor()
    return substitute(getline("."), ":.*$", "", "")
endfunction

function! s:LoadStashInfo(id)
    let l:diff = b:vit.repo.execute("stash show --stat --patch --submodule ".a:id)
    execute s:stash_diff_viewer." wincmd w"
    setlocal modifiable
    silent! 1,$d
    silent! put=l:diff
    silent! 0d_
    setlocal nomodifiable
    wincmd p
endfunction

function! s:VitStashInfo()
    let l:toplevel = fnamemodify(substitute(b:vit.repo.execute("rev-parse --show-toplevel"), "\n$", "", ""), ":t")

    if tabpagenr("$") == 1
        execute "setlocal statusline=".l:toplevel."%=%l/%L"
    else
        execute "silent! file ".l:toplevel
        setlocal statusline=%=%l/%L
    endif
endfunction
" }}}

" Autocmds " {{{
autocmd WinEnter,WinLeave,BufEnter,BufWritePost <buffer> call <SID>VitStashInfo()
autocmd TabLeave * call <SID>VitStashInfo()
call s:VitStashInfo()

autocmd CursorMoved <buffer> call s:LoadStashInfo(<SID>GetStashIdUnderCursor())
" }}}

botright new
autocmd WinEnter,WinLeave,BufEnter <buffer> setlocal statusline=\ 
setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodifiable nolist nonumber
set filetype=VitStashInfo
let s:stash_diff_viewer=winnr()
wincmd p

if len(getline(1, "$")) > 8
    execute "resize ".string(&lines * 0.20)
else
    execute "resize ".string(len(getline(1, "$")) + 1)
endif

" vim:set formatoptions-=tc foldmethod=expr foldexpr=getline(v\:lnum)=~#'^\s*fu[nction]*'?'a1'\:getline(v\:lnum)=~#'^\s*endf[unction]*'?'s1'\:'=':
