if exists("b:autoloaded_vit_show") || v:version < 700
    finish
endif
let b:autoloaded_vit_show = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

if exists("b:git_revision")
    silent! put =vit#ExecuteGit("show ".b:git_revision)
    0d_
elseif exists("b:vit_ref_file")
    let s:ref_file_last_rev = vit#ExecuteGit("--no-pager log --no-color -n 1 --pretty=format:%H -- ".b:vit_ref_file)
    silent! put =vit#ExecuteGit("show ".s:ref_file_last_rev)
    0d_
endif

setlocal nolist nocursorline nomodifiable nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! GetRevFromShow() " {{{
    return substitute(getline(1), '^commit \([0-9a-f].*\)$', '\1', '')
endfunction " }}}

function! GetFileUnderCursor() " {{{
    let l:currline = line(".")
    if getline(".") !~ "^diff"
        let l:last_wrapscan = &wrapscan
        setlocal nowrapscan
        execute "silent! normal! ?diff\<cr>"
        setlocal wrapscan = l:last_wrapscan
    endif
    let l:file = substitute(getline("."), '.* b/\(.*\)$', '\1', '')
    execute "normal ".l:currline."gg"

    call vit#OpenFileAsDiff(l:file)
endfunction " }}}

function! VitShow#Git(...) " {{{
    " echomsg "VitShow#Git(".string(a:000).")"
    if a:0 > 0
        if a:1 ==# "reset"
            call vit#Reset(join(a:000[1:], ' '). " ".GetRevFromBlame())
        else
            call vit#Git(join(a:000, ' '))
        endif
    else
        call vit#Git()
    endif
endfunction
command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call VitShow#Git(<f-args>)
" }}}

nnoremap <buffer> <silent> d :call GetFileUnderCursor()<cr>
nnoremap <buffer> <silent> D :call vit#OpenFilesInRevisionAsDiff(GetRevFromShow())<cr>

" vim: set foldmethod=marker formatoptions-=tc:
