if exists("b:vit_reload")
    let b:lastline = line(".")
    setlocal modifiable
    silent! 1,$d
    unlet! b:vit_reload
    unlet! b:autoloaded_vit_status
endif

if exists("b:autoloaded_vit_status") || v:version < 700
    finish
endif
let b:autoloaded_vit_status = 1
scriptencoding utf-8

if exists("b:vit")
    if exists("g:vit_status_windows") && has_key(g:vit_status_windows, b:vit.repo.gitdir)
        let [tabnum, winnum] = g:vit_status_windows[b:vit.repo.gitdir]
        if tabpagenr() != tabnum || winnr() != winnum
            let vit_status_currbuf = bufnr("%")
            execute "tabnext ".tabnum
            execute winnum." wincmd w"
            execute "bdelete ".vit_status_currbuf
            unlet vit_status_currbuf
            finish
        endif
    else
        if !exists("g:vit_status_windows")
            let g:vit_status_windows = {}
        endif
        let g:vit_status_windows[b:vit.repo.gitdir] = [tabpagenr(), winnr()]
    endif

    let b:vit.windows.status = bufnr("%")
    let b:status = b:vit.execute("status --short") " Using short here because it displays files relative to the cwd
    if len(b:status) <= 0
        let b:status = "  No changes"
    endif
else
    let b:status = "  Not a repo"
endif

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable nolist nonumber cursorline
if exists("&relativenumber")
    setlocal norelativenumber
endif

silent! put =b:status
0d_
setlocal nomodifiable

if exists("b:lastline")
    execute "normal ".b:lastline."gg"
    unlet! b:lastline
endif

" Set width of the window based on the widest text
setlocal winminwidth=20
let b:max_cols = max(map(getline(1, "$"), "len(v:val)"))
execute "vertical resize ".b:max_cols

if getline(1) =~ "^##"
    autocmd CursorMoved <buffer> execute "if line('.') == 1|normal j|endif"
    normal 2gg
endif

augroup VitStatus
    autocmd!
    autocmd FocusGained,BufWritePost * call vit#RefreshStatuses()
    autocmd BufDelete,BufWipeout <buffer> autocmd! VitStatus
    autocmd BufWinLeave <buffer> let b:vit.windows.status = -1
                                \ | if exists("g:vit_status_windows") && has_key(g:vit_status_windows, b:vit.repo.gitdir)
                                \ | unlet g:vit_status_windows[b:vit.repo.gitdir]
                                \ | endif
    autocmd VimResized <buffer> execute "vertical resize ".b:max_cols
augroup END

function! GetFileAtCursor()
    if getline(".") !~ "^##"
        return split(getline("."))[1]
    endif
endfunction

execute "silent! file ".fnamemodify(substitute(b:vit.execute("rev-parse --show-toplevel"), "\n$", "", ""), ":t")

autocmd WinEnter,WinLeave,BufEnter <buffer> execute "setlocal statusline=".b:vit.repo.branch()

nnoremap <buffer> <silent> + :call vit#Add(GetFileAtCursor())<cr>
vnoremap <buffer> <silent> + :call vit#Add(GetFileAtCursor())<cr><cr>
nnoremap <buffer> <silent> - :call vit#Unstage(GetFileAtCursor())<cr>
vnoremap <buffer> <silent> - :call vit#Unstage(GetFileAtCursor())<cr><cr>

nnoremap <buffer> <silent> <enter> :if getline(".") !~ "^##"
                             \<bar>let path=GetFileAtCursor()
                             \<bar>execute b:vit_parent_win."wincmd w"
                             \<bar>execute "edit ".path
                             \<bar>endif<cr>

nnoremap <buffer> <silent> d :call vit#OpenFileAsDiff(GetFileAtCursor(), "HEAD")<cr>
nnoremap <buffer> <silent> D :let first_tab = tabpagenr() + 1
            \<bar>call map(filter(getline(1, "$"), "v:val !~ \"^##\""), "vit#OpenFileAsDiff(split(v:val)[1], \"HEAD\")")
            \<bar>execute "tabnext ".first_tab<bar>unlet first_tab<cr>

" vim: set foldmethod=marker formatoptions-=tc:
