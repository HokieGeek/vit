if exists("g:autoloaded_vit_log") || v:version < 700
    finish
endif
let g:autoloaded_vit_log = 1
scriptencoding utf-8

function! GetRevFromGitLog()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

if exists("b:vit_is_standalone")
    if !exists("b:vit_log_lastline")
        let b:vit_log_lastline = 0
    endif

    " Create the new window to use for the git show output
    botright new
    execute "resize ".string(&lines * 0.60)

    setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nonumber nocursorline nolist
    if exists("&relativenumber")
        setlocal norelativenumber
    endif
    wincmd t

    let g:vit_log_entry_cache = {}

    function! LoadLogEntry()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevFromGitLog()

            if l:rev !~ "^[\|\\/*]"
                if has_key(g:vit_log_entry_cache, l:rev)
                    let l:rev_entry = g:vit_log_entry_cache[l:rev]
                else
                    let l:rev_entry = vit#ExecuteGit("show ".l:rev)
                    let g:vit_log_entry_cache[l:rev] = l:rev_entry
                endif

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

    " nnoremap <buffer> <silent> o :call vit#OpenFilesInCommit(GetRevFromGitLog())<cr>
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
