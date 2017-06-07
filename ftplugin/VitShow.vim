if exists("b:autoloaded_vit_show") || v:version < 700
    finish
endif
let b:autoloaded_vit_show = 1
scriptencoding utf-8

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable nolist nocursorline nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

let b:vit.windows.show = bufnr("%")

if exists("b:git_revision")
    let b:vit_content = b:vit.execute("show ".b:git_revision." ".b:vit.path.relative)
else
    let b:vit_content = "No revision given"
endif
silent! put=b:vit_content
0d_

setlocal nomodifiable

function! GetFileFromDiffLine(line) " {{{
    if a:line =~ "--cc"
        let l:file = substitute(a:line, '^diff\s*--cc\s*', '', '')
    else
        let l:file = substitute(a:line, '.* b/\(.*\)$', '\1', '')
    endif
    return l:file
endfunction " }}}

function! GetFileUnderCursor() " {{{
    let l:currline = line(".")
    if getline(".") !~ "^diff"
        let l:last_wrapscan = &wrapscan
        setlocal nowrapscan
        execute "silent! normal! ?diff\<cr>"
        if l:last_wrapscan == 1
            setlocal wrapscan
        endif
    endif
    let l:file = GetFileFromDiffLine(getline("."))
    execute l:currline
    return l:file
endfunction " }}}

function! OpenFilesFromShow() " {{{
    let l:showfiles = map(filter(getline(1, "$"), 'v:val =~ "^diff"'), 'fnamemodify(GetFileFromDiffLine(v:val), ":p:.")')
    let l:showfiles = map(l:showfiles, 'v:val.":1:".substitute(split(b:vit.execute("show --stat '.b:git_revision.' -- ".v:val), "\n")[6], " *".v:val." *| *", "", "")')

    tabnew
    lexpr l:showfiles
    lwindow
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

nnoremap <buffer> <silent> d :call vit#OpenFileAsDiff(GetFileUnderCursor(), b:git_revision."~1", b:git_revision)<cr>
nnoremap <buffer> <silent> D :call vit#OpenFilesInRevisionAsDiff(b:git_revision)<cr>

nnoremap <buffer> <silent> o :execute "tabedit ".fnamemodify(GetFileUnderCursor(), ":p:.")<cr>
nnoremap <buffer> <silent> O :call OpenFilesFromShow()<cr>

" vim: set foldmethod=marker formatoptions-=tc:
