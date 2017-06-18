if v:version < 700
    finish
endif
scriptencoding utf-8

" Initializing the buffer " {{{
if !exists("b:autoloaded_vit_log")
    wincmd k
    wincmd x

    let b:vit.windows.log = bufnr("%")
    let b:vit_reffile_winnr = b:vit.winnr()
    let b:timeformat="\%cr" " Relative time

    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodifiable nolist cursorline nonumber
    if exists("&relativenumber")
        setlocal norelativenumber
    endif

    let b:autoloaded_vit_log = 1
endif

if !exists("b:vit_log_args")
    let b:vit_log_args = ""
endif
if len(b:vit.reffile) > 0
    let b:vit_log_args .= " -- ".b:vit.path.absolute
endif

if !exists("b:vit_log_lastline")
    let b:vit_log_lastline = 0
endif
" }}}

" Functions " {{{
function! s:GetRevUnderCursor()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

function! s:Git(...) " {{{
    if a:0 > 0
        if a:1 ==# "reset"
            call vit#commands#Reset(join(a:000[1:], ' '). " ".<SID>GetRevUnderCursor())
        else
            call vit#config#git(join(a:000, ' '))
        endif
    else
        call vit#config#git()
    endif
endfunction
command! -bar -buffer -complete=customlist,vit#config#gitCompletion -nargs=* Git :call <SID>Git(<f-args>)
" }}}

function! s:SkipNonCommits(func) " {{{
    if b:vit_log_lastline != line(".")
        let l:rev = s:GetRevUnderCursor()
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

function! s:VitLogLoadShowByRev(rev) " {{{
    if b:vit.windows.show == -1
        call vit#windows#ShowWindow(a:rev)
    else
        execute bufwinnr(b:vit.windows.show)." wincmd w"
        let l:vit = b:vit
        enew
        let b:vit = l:vit
        call vit#windows#Show(a:rev, l:vit.bufnr)
    endif
endfunction " }}}

function! s:VitLogInfo() " {{{
    if tabpagenr("$") == 1
        let l:line = b:vit_toplevel.":".b:vit.repo.branch()
    else
        let l:line = b:vit.repo.branch()
    endif

    execute "setlocal statusline=".l:line."%=%l/%L"
endfunction

let b:vit_toplevel = fnamemodify(substitute(b:vit.execute("rev-parse --show-toplevel"), "\n$", "", ""), ":t")
execute "silent! file ".b:vit_toplevel

autocmd TabLeave,WinEnter,WinLeave,BufEnter,BufWritePost <buffer> call <SID>VitLogInfo()
call s:VitLogInfo() " }}}

function! s:VitLoadLog() " {{{
    setlocal modifiable
    let b:log = b:vit.execute("--no-pager log --no-color --graph --pretty=format:'\%h -\%d \%s (".b:timeformat.") <\%an>' ".b:vit_log_args)
    if strlen(b:log) <= 0
        echohl WarningMsg
        echom "No log was generated"
        echohl None
        return
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
endfunction " }}}

" }}}

" Maps and autocmds " {{{
autocmd BufWinLeave <buffer> let b:vit.windows.log = -1

" Swaps the time field in the log from relative to ISO 8601-like
nnoremap <buffer> <silent> t :let b:timeformat = b:timeformat =~ "cr" ? "\%ci" : "\%cr"<bar>call <SID>VitLoadLog()<cr>
nnoremap <buffer> <silent> d :call vit#windows#OpenFilesInRevisionAsDiff(<SID>GetRevUnderCursor())<cr>
nnoremap <buffer> <silent> R :call vit#commands#RevertFile(<SID>GetRevUnderCursor(), b:vit.path.relative)<cr>

" Makes way more sense to make sure that gj/gk aren't used by default when wrapping
nnoremap <buffer> j j
nnoremap <buffer> k k
" }}}

call s:VitLoadLog()

if exists("t:vit_log_k")
    " Deletes the window with the empty buffer
    if winnr("$") > 1
        execute "bdelete ".winbufnr(filter(range(1, winnr("$")), "v:val != ".winnr())[0])
    endif

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:VitLogLoadShowByRev")) | wincmd p
else
    if len(getline(1, "$")) > 15
        execute "resize ".string(&lines * 0.20)
    else
        execute "resize ".string(len(getline(1, "$")) + 1)
    endif

    function! s:CheckoutFileAtRevision(rev) " {{{
        let l:vit = b:vit
        execute b:vit_reffile_winnr." wincmd w"
        if a:rev == "0000000"
            execute "buffer ".l:vit.bufnr
        else
            let l:line = line(".")
            enew

            let b:vit = l:vit
            let l:fileRev = b:vit.execute("show ".a:rev.":".b:vit.path.relative)
            silent! put =l:fileRev
            silent! 0d_

            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
            execute "setlocal filetype=".getbufvar(b:vit.bufnr, "&filetype")
            execute "normal ".l:line."gg"
        endif
        wincmd p
    endfunction " }}}

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:CheckoutFileAtRevision"))
    execute "autocmd BufWinLeave <buffer> ".b:vit_reffile_winnr." wincmd w | buffer ".b:vit.bufnr

    nnoremap <buffer> <silent> <enter> :call <SID>VitLogLoadShowByRev(<SID>GetRevUnderCursor())<cr>
endif

" vim: set foldmethod=marker formatoptions-=tc:
