if exists("b:vit_reload")
    let b:lastline = line(".")
    setlocal modifiable
    silent! 1,$d
    unlet! b:vit_reload
    unlet! b:autoloaded_vit_status
endif

if exists("b:autoloaded_vit_status") || v:version < 700
    finish
endif
let b:autoloaded_vit_status = 1
scriptencoding utf-8

function! GetStatus() " {{{
    let l:status = vit#ExecuteGit("status --short") " Using short here because it displays files relative to the cwd
    if len(l:status) <= 0
        let l:status = "  Nothing"
    endif
    return l:status
endfunction " }}}

function! LoadStatus(ref_file) " {{{
    if !exists("b:vit_git_cmd")
        call vit#GetGitConfig(a:ref_file)
    endif
    call vit#LoadContent(GetStatus())
endfunction " }}}

call LoadStatus(b:vit_ref_file)

if exists("b:lastline")
    execute "normal ".b:lastline."gg"
    unlet! b:lastline
endif

" Set width of the window based on the widest text
setlocal winminwidth=20
let b:max_cols = max(map(getline(1, "$"), "len(v:val)"))
execute "vertical resize ".b:max_cols

setlocal nolist nomodifiable nonumber cursorline
if exists("&relativenumber")
    setlocal norelativenumber
endif

if getline(1) =~ "^##"
    autocmd CursorMoved <buffer> execute "if line('.') == 1|normal j|endif"
    normal 2gg
endif

augroup VitStatus
    autocmd!
    autocmd FocusGained,BufWritePost * call vit#RefreshStatus()
    autocmd BufDelete,BufWipeout <buffer> autocmd! VitStatus
augroup END

nnoremap <buffer> <silent> + :if getline(".") !~ "^##"<bar>call vit#Add(split(getline("."))[1])<bar>endif<cr>
nnoremap <buffer> <silent> - :if getline(".") !~ "^##"<bar>call vit#Unstage(split(getline("."))[1])<bar>endif<cr>

nnoremap <buffer> <silent> d :if getline(".") !~ "^##"<bar>call vit#OpenFileAsDiff(split(getline("."))[1])<bar>endif<cr>
" TODO nnoremap <buffer> <silent> D :call vit#OpenFilesInRevisionAsDiff(GetRevFromShow())<cr>

" vim: set foldmethod=marker formatoptions-=tc:
