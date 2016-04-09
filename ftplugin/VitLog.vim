" nnoremap <buffer> <silent> v :call vit#HandleRevisionSelection()<cr>

if exists("b:vit_is_standalone")
    if !exists("g:vit_log_lastshownrev")
        let g:vit_log_lastshownrev = ""
    endif

    function! LoadLogEntry()
        let l:rev = vit#GetRevFromGitLog()
        wincmd o
        call vit#LoadContent("bottom", vit#ExecuteGit("show ".l:rev))
        setlocal filetype=VitShow nolist nocursorline nomodifiable nonumber
        if exists("&relativenumber")
            setlocal norelativenumber
        endif
        wincmd p
        resize 20
    endfunction

    autocmd CursorMoved <buffer> call LoadLogEntry()
else
    nnoremap <buffer> <silent> o :call vit#CheckoutFromLog()<cr>
    nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call vit#ShowFromLog()<cr>
endif
