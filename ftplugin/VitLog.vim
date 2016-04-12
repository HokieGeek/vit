if exists("g:autoloaded_vit_log") || v:version < 700
    finish
endif
let g:autoloaded_vit_log = 1
scriptencoding utf-8

call vit#LoadContent("current", vit#ExecuteGit("log --graph --pretty=format:'\%h -\%d \%s (\%cr) <\%an>' -- ".b:vit_ref_file))
setlocal nolist cursorline nomodifiable nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif
    
" call cursor(line("."), 2)

function! GetRevFromLog()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

if exists("b:vit_is_standalone")
    if bufnr("$") > 1
        bdelete #
    endif

    if !exists("b:vit_log_lastline")
        let b:vit_log_lastline = 0
    endif

    " Create the new window to use for the git show output
    botright new
    " let b:vit_is_standalone = 1
    execute "resize ".string(&lines * 0.60)

    setlocal filetype=VitShow
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    wincmd t

    let g:vit_log_entry_cache = {}

    function! LoadLogEntry()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevFromLog()

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

    " nnoremap <buffer> <silent> o :call vit#OpenFilesInCommit(GetRevFromLog())<cr>
else
    resize 10

    function! CheckoutFromLog()
        let l:rev = GetRevFromLog()
        bdelete
        call vit#CheckoutCurrentFile(l:rev)
    endfunction
    function! ShowFromLog()
        let l:rev = GetRevFromLog()
        bdelete
        call vit#Show(l:rev)
    endfunction

    nnoremap <buffer> <silent> o :call CheckoutFromLog()<cr>
    nnoremap <buffer> <silent> <enter> :let g:vit_log_lastline=line(".") <bar> call ShowFromLog()<cr>

    nnoremap <buffer> <silent> v :let l:file = b:vit_ref_file <bar> bdelete <bar> call vit#PopGitDiff(vit#GetRevFromLog(), l:file)<cr>
endif
