if exists("b:vit_reload")
    unlet! b:autoloaded_vit_log
endif

if exists("b:autoloaded_vit_log") || v:version < 700
    finish
endif
let b:autoloaded_vit_log = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable nolist cursorline nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

let b:vit.windows.log = bufnr("%")
let b:reffile_winnr = bufwinnr(b:vit.bufnr)
let b:vit_log_entry_cache = {}

if len(b:vit.reffile) > 0
    let b:file = " -- ".b:vit.path.absolute
else
    let b:file = ""
endif

let b:timeformat="\%cr" " Relative time

function! VitLoadLog() " {{{
    setlocal modifiable
    let b:log = b:vit.execute("--no-pager log --no-color --graph --pretty=format:'\%h -\%d \%s (".b:timeformat.") <\%an>'".b:file)
    if strlen(b:log) <= 0
        echohl WarningMsg
        echom "No log was generated"
        echohl None
        finish
    endif

    if len(b:vit.reffile) > 0 && b:vit.status() == 3
        let b:log = "* 0000000 - %Unstaged modifications%\n".b:log
    endif

    let l:currline=line(".")
    silent! 1,$d
    silent! put =b:log
    0d_
    execute l:currline
    setlocal nomodifiable
endfunction
call VitLoadLog() " }}}

if exists("b:vit_reload")
    unlet! b:vit_reload
    finish
endif

if !exists("b:vit_log_lastline")
    let b:vit_log_lastline = 0
endif

function! GetRevUnderCursor()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

function! VitLog#Git(...) " {{{
    if a:0 > 0
        if a:1 ==# "reset"
            call vit#Reset(join(a:000[1:], ' '). " ".GetRevUnderCursor())
        else
            call vit#Git(join(a:000, ' '))
        endif
    else
        call vit#Git()
    endif
endfunction
command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call VitLog#Git(<f-args>)
" }}}

function! s:SkipNonCommits(func) " {{{
    if b:vit_log_lastline != line(".")
        let l:rev = GetRevUnderCursor()
        if l:rev =~ "^[\|\\/*]"
            if b:vit_log_lastline > line(".")
                let l:newline = line(".")-1
            else
                let l:newline = line(".")+1
            endif
            call cursor(l:newline, 0)
            call s:SkipNonCommits(a:func)
        else
            call a:func(l:rev)
        endif
        let b:vit_log_lastline = line(".")
    endif
endfunction " }}}

if exists("t:vit_log_standalone") " {{{
    " Deletes the window with the empty buffer TODO: get rid of this silliness
    if bufnr("$") > 1
        bdelete #
    endif

    if &lines > 20
        execute "resize ".string(&lines * 0.60)
    endif

    function! s:LoadLogEntry(rev)
        if b:vit.windows.show == -1
            call vit#ShowWindow(a:rev)
        else
            if has_key(b:vit_log_entry_cache, a:rev)
                let l:cached_buf = b:vit_log_entry_cache[a:rev]
            endif
            execute bufwinnr(b:vit.windows.show)." wincmd w"
            if exists("l:cached_buf") && bufexists(l:cached_buf) " FIXME: stop the wipe!
                execute "buffer ".l:cached_buf
            else
                execute bufwinnr(b:vit.windows.show)." wincmd w"
                let l:vit = b:vit
                enew
                let b:vit = l:vit
                call vit#Show(a:rev, b:vit.bufnr)
                " setlocal bufhidden=hide
                let l:new_cache = bufnr("%")
            endif
        endif
        wincmd p
        if exists("l:new_cache")
            let b:vit_log_entry_cache[a:rev] = l:new_cache
        endif
    endfunction

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:LoadLogEntry"))
" }}}
else " {{{
    if len(getline(1, "$")) > 15
        execute "resize ".string(&lines * 0.20)
    else
        execute "resize ".string(len(getline(1, "$")) + 1)
    endif

    function! s:CheckoutFileAtRevision(rev)
        let l:vit = b:vit
        execute b:reffile_winnr." wincmd w"
        if a:rev == "0000000"
            execute "buffer ".l:vit.bufnr
        else
            let l:fileRev = l:vit.execute("show ".a:rev.":".l:vit.path.relative)
            enew
            let b:vit = l:vit
            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
            silent! put =l:fileRev
            silent! 0d_
            filetype detect
        endif
        wincmd p
    endfunction

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:CheckoutFileAtRevision"))
    execute "autocmd BufWinLeave <buffer> "b:reffile_winnr." wincmd w | buffer ".b:vit.bufnr
    autocmd BufWinLeave <buffer> let b:vit.windows.log = -1

    nnoremap <buffer> <silent> <enter> :call vit#ShowWindow(GetRevUnderCursor())<cr>
endif " }}}

function! VitLogInfo()
    let l:toplevel = fnamemodify(substitute(b:vit.execute("rev-parse --show-toplevel"), "\n$", "", ""), ":t")

    if tabpagenr("$") == 1
        let l:line = l:toplevel.":".b:vit.repo.branch()
    else
        execute "silent! file ".l:toplevel
        let l:line = b:vit.repo.branch()
    endif

    execute "setlocal statusline=".l:line."%=%l/%L"
endfunction
autocmd WinEnter,WinLeave,BufEnter,BufWritePost <buffer> call VitLogInfo()
autocmd TabLeave * call VitLogInfo()
call VitLogInfo()

nnoremap <buffer> <silent> d :call vit#OpenFilesInRevisionAsDiff(GetRevUnderCursor())<cr>
" nnoremap <buffer> <silent> R :call vit#RevertFile(GetRevUnderCursor(), b:vit.path.relative)<cr>
" ISO 8601-like
nnoremap <buffer> <silent> T :let b:timeformat = b:timeformat =~ "cr" ? "\%ci" : "\%cr"<bar>call VitLoadLog()<cr>


" Makes way more sense to make sure that gj/gk aren't used by default when wrapping
nnoremap <buffer> j j
nnoremap <buffer> k k

" vim: set foldmethod=marker formatoptions-=tc:
