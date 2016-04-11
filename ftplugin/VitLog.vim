if exists("g:autoloaded_vit_log") || v:version < 700
    finish
endif
let g:autoloaded_vit_log = 1
scriptencoding utf-8

function! GetRevFromGitLog()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

function! CreateNewLogEntryBuffer(content)
    " setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal filetype=VitShow buftype=nofile bufhidden=hide nobuflisted noswapfile
    setlocal nonumber nocursorline nolist
    if exists("&relativenumber")
        setlocal norelativenumber
    endif

    if strlen(a:content) > 0
        silent! put =a:content
        silent! 0d_
    else
        silent! put ="Foobar"
    endif
    resize 35 "Would be nice if I didn't have to do this every time
endfunction

if exists("b:vit_is_standalone")
    if !exists("b:vit_log_lastline")
        let b:vit_log_lastline = 0
    endif

    let b:vit_log_winnr = winnr()

    " Create the new window to use for the git show output
    botright new

    let g:vit_log_entries_winnr = 2 "winnr()
    call CreateNewLogEntryBuffer("")

    " setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal filetype=VitShow buftype=nofile bufhidden=hide nobuflisted noswapfile
    setlocal nonumber nocursorline nolist
    if exists("&relativenumber")
        setlocal norelativenumber
    endif
    execute "resize ".string(&lines * 0.60)
    wincmd t

    let g:vit_log_entry_cache = {"blank": bufnr("%") }
    wincmd p

    " TODO: maybe load each rev history into its own buffer, add the buffer to
    " a map (by rev) and switch to that? For invalid revs, all point to a
    " blank buffer (0)
    function! LoadLogEntry()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevFromGitLog()
        if has_key(g:vit_log_entry_cache, l:rev)
            echom localtime()." Found cached entry"
            " Retrieve existing buffer and switch to it
            let l:buf_num = get(g:vit_log_entry_cache, l:rev)
            " execute b:vit_log_entries_winnr." wincmd w"
            execute buffer." ".l:buf_num
        else
            if l:rev =~ "^[\|\\/*]"
                echom localtime()." Invalid entry"
                " Use blank buffer
                let l:buf_num = get(g:vit_log_entry_cache, "blank")
                " execute b:vit_log_entries_winnr." wincmd w"
                execute buffer." ".l:buf_num
            else
                echom localtime()." Creating new entry"
                " TODO: create a new buffer and load the results of execute git into it
                " execute b:vit_log_entries_winnr." wincmd w"
                let l:rev_entry = vit#ExecuteGit("show ".l:rev)
                enew
                execute "let g:vit_log_entry_cache = {'".l:rev."': ".bufnr("%")."}"
                " let g:vit_log_entry_cache = {l:rev: bufnr("%")}

                " call CreateNewLogEntryBuffer(l:rev_entry)
                call CreateNewLogEntryBuffer("New: ".l:rev)
            endif
        endif
        if l:rev !~ "^[\|\\/*]" && b:vit_log_lastshownrev != l:rev
            let b:vit_log_lastshownrev = l:rev

            if l:rev !~ "[\|\\/*]"
                " This needs to be executed before switching away from the log
                let l:rev_entry = vit#ExecuteGit("show ".l:rev)

                " Switch to the VitShow window and paste the new output
                wincmd j
                setlocal modifiable

                " Remove old entry and add new one
                silent! 1,$d
                silent! put =l:rev_entry
                silent! 0d_

                setlocal nomodifiable
                wincmd t
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

    " Makes way more sense to make sure that gj/gk aren't used by default when wrapping
    nnoremap <buffer> j j
    nnoremap <buffer> k k

    nnoremap <buffer> <silent> o :call vit#OpenFilesInCommit(GetRevFromGitLog())<cr>
else
    function! CheckoutFromLog()
        let l:rev = GetRevFromGitLog()
        bdelete
        call vit#GitCheckoutCurrentFile(l:rev)
    endfunction
    function! ShowFromLog()
        let l:rev = GetRevFromGitLog()
        bdelete
        call vit#PopGitShow(l:rev)
    endfunction

    nnoremap <buffer> <silent> o :call CheckoutFromLog()<cr>
    nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call ShowFromLog()<cr>

    nnoremap <buffer> <silent> v :let l:file = b:vit_ref_file <bar> bdelete <bar> call vit#PopGitDiff(vit#GetRevFromGitLog(), l:file)<cr>
endif
