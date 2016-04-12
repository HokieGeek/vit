if exists("g:autoloaded_vit_show") || v:version < 700
    finish
endif
let g:autoloaded_vit_show = 1
scriptencoding utf-8

call vit#LoadContent("current", vit#ExecuteGit("show ".b:git_revision))

setlocal nolist nocursorline nomodifiable nonumber
if exists("&relativenumber")
    setlocal norelativenumber
endif

function! GetRevFromShow()
    return substitute(getline(1), '^commit \([0-9a-f].*\)$', '\1', '')
endfunction

if !exists("b:vit_is_standalone")
if exists("b:vit_is_standalone")
    bdelete #
else
    resize 25
    " nnoremap <buffer> <silent> <esc> :Git log<bar>execute g:vit_log_lastline<cr>
" else
    nnoremap <buffer> <silent> <enter> :call DiffFromRev(b:git_revision, b:vit_ref_file)<cr>
    " nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
endif
nnoremap <buffer> <silent> o :call vit#OpenFilesInCommit(GetRevFromShow())<cr>
