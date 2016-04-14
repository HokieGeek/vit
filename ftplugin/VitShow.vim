if exists("b:autoloaded_vit_show") || v:version < 700
    finish
endif
let b:autoloaded_vit_show = 1
scriptencoding utf-8

if exists("b:git_revision")
    call vit#LoadContent(vit#ExecuteGit("show ".b:git_revision))
endif

setlocal nolist nocursorline nomodifiable nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! GetRevFromShow()
    return substitute(getline(1), '^commit \([0-9a-f].*\)$', '\1', '')
endfunction

function! GetFileUnderCursor()
    let l:currline = line(".")
    if getline(".") !~ "^diff"
        execute "silent! normal! ?diff\<cr>"
    endif
    let l:file = substitute(getline("."), '.* b/\(.*\)$', '\1', '')
    execute "normal ".l:currline."gg"

    call vit#OpenFileAsDiff(l:file)
endfunction

nnoremap <buffer> <silent> o :call GetFileUnderCursor()<cr>
nnoremap <buffer> <silent> O :call vit#OpenFilesInRevisionAsDiff(GetRevFromShow())<cr>
