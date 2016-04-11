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
    setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nonumber nocursorline nolist
    if exists("&relativenumber")
        setlocal norelativenumber
    endif
    execute "resize ".string(&lines * 0.60)
    wincmd p

    function! LoadLogEntry()
        if b:vit_log_lastline != line(".")
            let b:vit_log_lastline = line(".")
            
            let l:rev = GetRevFromGitLog()
            
            if l:rev !~ "[\|\\/*]"
                " This needs to be executed before switching away from the log
                let l:rev_show = vit#ExecuteGit("show ".l:rev)

                " Switch to the VitShow window and paste the new output
                wincmd j
                setlocal modifiable
                silent! 1,$d

                silent! put =l:rev_show
                silent! 0d_
                if winheight(0) <= 1
                    execute "resize ".string(&lines * 0.60)
                endif
            else
                wincmd j
                setlocal modifiable
                silent! 1,$d
            endif
            
            setlocal nomodifiable
            wincmd p
        endif
    endfunction

    autocmd CursorMoved <buffer> call LoadLogEntry()

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
