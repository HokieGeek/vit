if exists("b:vit_reload")
    setlocal modifiable
    silent! 1,$d
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

let b:log = b:vit.execute("--no-pager log --no-color --graph --pretty=format:'\%h -\%d \%s (\%cr) <\%an>' -- ".b:vit.path.absolute)
if strlen(b:log) <= 0
    echohl WarningMsg
    echom "No log was generated"
    echohl None
    finish
endif

if !exists("g:vit_standalone")
    if b:vit.status() == 3
        let b:log = "* 0000000 - %Unstaged modifications%\n".b:log
    endif
endif

silent! put =b:log
0d_
setlocal nomodifiable

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

if exists("g:vit_standalone") " {{{
    if bufnr("$") > 1
        bdelete #
    endif

    " Create the new window to use for the git show output
    let s:vit = b:vit
    botright new

    let b:vit = s:vit
    execute "resize ".string(&lines * 0.60)

    setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    wincmd p

    if !exists("b:vit_log_lastline")
        let b:vit_log_lastline = 0
    endif

    let g:vit_log_entry_cache = {}

    function! s:LoadLogEntry(rev)
        if has_key(g:vit_log_entry_cache, a:rev)
            let l:rev_entry = g:vit_log_entry_cache[a:rev]
        else
            let l:rev_entry = vit#ExecuteGit("show ".a:rev)
            let g:vit_log_entry_cache[a:rev] = l:rev_entry
        endif

        " Switch to the VitShow window and paste the new output
        execute bufwinnr(b:vit.windows.show)." wincmd w"
        wincmd j
        setlocal modifiable

        " Remove old entry and add new one
        silent! 1,$d
        silent! put =l:rev_entry
        silent! 0d_

        setlocal nomodifiable
        wincmd p
        wincmd t
    endfunction

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:LoadLogEntry"))
" }}}
else " {{{

    execute "resize ".string(&lines * 0.30)

    if !exists("b:vit_log_lastline")
        let b:vit_log_lastline = 1
    endif

    let b:reffile_winnr = bufwinnr(b:vit.bufnr)
    function! s:CheckoutFileAtRevision(rev)
        let l:vit = b:vit
        execute b:reffile_winnr." wincmd w"
        if a:rev == "0000000"
            execute "buffer ".l:vit.bufnr
        else
            let l:fileRev = l:vit.execute("show ".a:rev.":".l:vit.path.relative)
            enew
            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
            silent! put =l:fileRev
            silent! 0d_
            filetype detect
    resize 30

    function! s:CheckoutFileAtRevision(rev)
        if a:rev == "0000000"
            echom "Unstaged!"
        else
            echom "git checkout --patch ".a:rev." -- ".b:vit_ref_file
        endif
        wincmd p
    endfunction

    autocmd CursorMoved <buffer> call s:SkipNonCommits(function("s:CheckoutFileAtRevision"))

    nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevUnderCursor())<cr>
endif " }}}

nnoremap <buffer> <silent> d :call vit#OpenFilesInRevisionAsDiff(GetRevUnderCursor())<cr>

" Makes way more sense to make sure that gj/gk aren't used by default when wrapping
nnoremap <buffer> j j
nnoremap <buffer> k k

" vim: set foldmethod=marker formatoptions-=tc:
