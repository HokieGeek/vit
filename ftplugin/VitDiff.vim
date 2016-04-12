if exists("g:autoloaded_vit_diff") || v:version < 700
    finish
endif
let g:autoloaded_vit_diff = 1
scriptencoding utf-8

unlet b:vit_git_dir
call vit#LoadContent("current", vit#ExecuteGit("show ".b:git_revision.":".b:vit_ref_file))
setlocal nomodifiable

diffthis
autocmd BufDelete,BufWipeout <buffer> windo diffoff

function! ShowFromDiff()
    let l:rev = b:git_revision
    bdelete
    call vit#Show(l:rev)
endfunction

nnoremap <buffer> <silent> v :call ShowFromDiff()<cr>

nnoremap <buffer> <silent> o :call vit#CheckoutFromBuffer()<cr>
