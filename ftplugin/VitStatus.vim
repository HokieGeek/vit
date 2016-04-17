if exists("b:autoloaded_vit_status") || v:version < 700
    finish
endif
let b:autoloaded_vit_status = 1
scriptencoding utf-8

function! GetStatus() " {{{
    " GET CHANGED (must be in root dir) let l:changedfiles = call vit#ExecuteGit("ls-files --exclude-from='".b:vit_root_dir."/.gitignore" -t --modified --deleted --others")
    " GET STAGED  let l:stagedfiles = call vit#ExecuteGit("diff-index --cached HEAD --")
    let l:status = vit#ExecuteGit("status --short")
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

function! ReloadStatus(ref_file) " {{{
    set modifiable
    silent! 1,$d
    call LoadStatus(a:ref_file)
    set nomodifiable
endfunction " }}}

call LoadStatus(b:vit_ref_file)

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
    autocmd BufWritePost * call vit#RefreshStatus()
    " execute "autocmd BufWritePost * ".winnr()."wincmd w | call ReloadStatus('".b:vit_ref_file."') | wincmd p"
    autocmd BufDelete,BufWipeout <buffer> autocmd! VitStatus
augroup END

nnoremap <buffer> <silent> + :if getline(".") !~ "^##"<bar>call vit#Add(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>
nnoremap <buffer> <silent> - :if getline(".") !~ "^##"<bar>call vit#Unstage(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>

nnoremap <buffer> <silent> o :if getline(".") !~ "^##"<bar>call vit#OpenFileAsDiff(split(getline("."))[1])<bar>endif<cr>
" TODO nnoremap <buffer> <silent> O :call vit#OpenFilesInRevisionAsDiff(GetRevFromShow())<cr>

" vim: set foldmethod=marker formatoptions-=tc:
