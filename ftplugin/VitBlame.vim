if exists("g:autoloaded_vit_blame") || v:version < 700
    finish
endif
let g:autoloaded_vit_blame = 1
scriptencoding utf-8

function! GetRevFromBlame()
    let l:rev = system("echo '".getline(".")."' | awk '{ print $1 }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! CheckoutFromBlame()
    let l:rev = GetRevFromBlame()
    bdelete
    call vit#CheckoutCurrentFile(l:rev)
endfunction
function! ShowFromBlame()
    let l:rev = GetRevFromBlame()
    bdelete
    call vit#Show(l:rev)
endfunction

nnoremap <buffer> <silent> <enter> :call DiffFromRev(GetRevFromBlame(), b:vit_ref_file)<cr>
nnoremap <buffer> <silent> o :call CheckoutFromBlame()<cr>
nnoremap <buffer> <silent> v :call ShowFromBlame()<cr>
