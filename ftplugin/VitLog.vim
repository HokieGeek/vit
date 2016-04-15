if exists("b:autoloaded_vit_log") || v:version < 700
    finish
endif
let b:autoloaded_vit_log = 1
scriptencoding utf-8

let b:file = vit#GetFilenameRelativeToGit(b:vit_ref_file)
call vit#LoadContent(vit#ExecuteGit("log --graph --pretty=format:'\%h -\%d \%s (\%cr) <\%an>' -- ".b:file))
setlocal nolist cursorline nomodifiable nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

if !exists("b:vit_log_lastline")
    let b:vit_log_lastline = 0
endif

function! GetRevFromLog()
    return substitute(getline("."), '^[\* \\/\|]*\s*\([0-9a-f]\{7,}\) .*', '\1', '')
endfunction

if strlen(b:vit_ref_file) <= 0
    if bufnr("$") > 1
        bdelete #
    endif

    " Create the new window to use for the git show output
    botright new
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
else
    resize 30

    function! SkipNonCommits()
        if b:vit_log_lastline != line(".")
            let l:rev = GetRevFromLog()
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

    nnoremap <buffer> <silent> <enter> :call vit#Show(GetRevFromLog())<cr>
endif

nnoremap <buffer> <silent> o :call vit#OpenFilesInRevisionAsDiff(GetRevFromLog())<cr>

" Makes way more sense to make sure that gj/gk aren't used by default when wrapping
nnoremap <buffer> j j
nnoremap <buffer> k k
