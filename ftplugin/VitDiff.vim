if exists("b:autoloaded_vit_diff") || v:version < 700
    finish
endif
let b:autoloaded_vit_diff = 1
scriptencoding utf-8

wincmd h
wincmd x

setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable

if !exists("b:git_revision")
    finish
endif

let b:vit.windows.diff = bufnr("%")

let b:content = b:vit.execute("show ".b:git_revision.":".b:vit.path.relative)
silent! put =b:content
0d_
setlocal nomodifiable

autocmd BufDelete,BufWipeout <buffer> setlocal buftype= | windo diffoff | filetype detect

execute "silent! file ".fnamemodify(b:vit.path.absolute, ":t").":".b:git_revision
execute "setlocal statusline=%=".b:git_revision
autocmd WinEnter,WinLeave,BufEnter <buffer> execute "setlocal statusline=%=".b:git_revision

windo diffthis
