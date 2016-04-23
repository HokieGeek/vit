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

if !exists("b:vit")
    let b:vit = getbufvar(b:vit_ref_bufnr, "vit")
endif

let b:log = b:vit.execute("--no-pager log --no-color --graph --pretty=format:'\%h -\%d \%s (\%cr) <\%an>' -- ".b:vit.path.absolute)
if strlen(b:log) <= 0
    echohl WarningMsg
    echom "No log was generated"
    echohl None
    finish
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
    " echomsg "VitLog#Git(".string(a:000).")"
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

if exists("g:vit_standalone") " {{{
    if bufnr("$") > 1
        bdelete #
    endif

    " Create the new window to use for the git show output
    " TODO: this is no good
    let s:tmpbufnr = b:vit_ref_bufnr
    botright new
    let b:vit_ref_bufnr = s:tmpbufnr
    execute "resize ".string(&lines * 0.60)

    echom "Applying ft"
    setlocal filetype=VitShow
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    let s:vitshow_winnr = winnr()
    wincmd p

    let g:vit_log_entry_cache = {}

    function! LoadLogEntry()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevUnderCursor()
            if strlen(l:rev) <= 0
                break
            endif

            if l:rev !~ "^[\|\\/*]"
                if has_key(g:vit_log_entry_cache, l:rev)
                    let l:rev_entry = g:vit_log_entry_cache[l:rev]
                else
                    let l:rev_entry = b:vit.execute("show ".l:rev)
                    let g:vit_log_entry_cache[l:rev] = l:rev_entry
                endif

                " Switch to the VitShow window and paste the new output
                execute s:vitshow_winnr." wincmd w"
                setlocal modifiable

                " Remove old entry and add new one
                silent! 1,$d
                silent! put =l:rev_entry
                silent! 0d_

                setlocal nomodifiable
                wincmd p
            else
                if b:vit_log_lastline > line(".")
                    let l:newline = line(".")-1
                else
                    let l:newline = line(".")+1
                endif
                call cursor(l:newline, 0)
                call LoadLogEntry()
            endif
            let b:vit_log_lastline = line(".")
        endif
    endfunction

    autocmd CursorMoved <buffer> call LoadLogEntry()
" }}}
else " {{{

    resize 30

    function! SkipNonCommits()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevUnderCursor()
            if l:rev =~ "^[\|\\/*]"
                if b:vit_log_lastline > line(".")
                    let l:newline = line(".")-1
                else
                    let l:newline = line(".")+1
                endif
                call cursor(l:newline, 0)
                call SkipNonCommits()

                " return 0
            endif
            let b:vit_log_lastline = line(".")

            " return 1
        endif
    endfunction

    autocmd CursorMoved <buffer> call SkipNonCommits()

    nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevUnderCursor())<cr>
endif " }}}

nnoremap <buffer> <silent> d :call vit#OpenFilesInRevisionAsDiff(GetRevUnderCursor())<cr>

" Makes way more sense to make sure that gj/gk aren't used by default when wrapping
nnoremap <buffer> j j
nnoremap <buffer> k k

" vim: set foldmethod=marker formatoptions-=tc:
