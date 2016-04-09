" nnoremap <buffer> <silent> v :call vit#HandleRevisionSelection()<cr>

if exists("b:vit_is_standalone")
    if !exists("b:vit_log_lastshownrev")
        let b:vit_log_lastshownrev = ""
        " let b:vit_log_shown_cache = {}
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
        let l:rev = vit#GetRevFromGitLog()
        if b:vit_log_lastshownrev != l:rev
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
            setlocal nomodifiable
            wincmd p
        endif
    endfunction

    autocmd CursorMoved <buffer> call LoadLogEntry()
else
    nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
    nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call vit#ShowFromLog()<cr>
endif
