if exists("b:vit_is_standalone")
    if !exists("b:vit_log_lastshownrev")
        let b:vit_log_lastshownrev = ""
    endif

    " Create the new window to use for the git show output
    botright new
    setlocal filetype=VitShow buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nonumber nocursorline nolist
    if exists("&relativenumber")
        setlocal norelativenumber
    endif
    " resize 40
    wincmd p

    function! LoadLogEntry()
        if exists("b:skipone")
            unlet b:skipone
            return
        endif
        let l:rev = vit#GetRevFromGitLog()
        if l:rev !~ "[\|\\/*]" && b:vit_log_lastshownrev != l:rev
            let b:vit_log_lastshownrev = l:rev

            " This needs to be executed before switching away from the log
            let l:rev_show = vit#ExecuteGit("show ".l:rev)

            " Switch to the VitShow window and paste the new output
            wincmd j
            setlocal modifiable
            silent! 1,$d

            silent! put =l:rev_show
            silent! 0d_
            resize 35
        elseif l:rev =~ "[\|\\/*]"
            wincmd j
            setlocal modifiable
            silent! 1,$d
        endif
        setlocal nomodifiable
        wincmd p
    endfunction

    autocmd CursorMoved <buffer> call LoadLogEntry()
    autocmd WinLeave <buffer> let b:skipone = 0

    nnoremap <buffer> <silent> v :call vit#OpenFilesInCommit(vit#GetRevFromGitLog())<cr>
    cnoremap <buffer> <silent> q qa
else
    nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
    nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call vit#ShowFromLog()<cr>

    nnoremap <buffer> <silent> v :let l:file = b:vit_ref_file <bar> bdelete <bar> call vit#PopGitDiff(vit#GetRevFromGitLog(), l:file)<cr>
endif
