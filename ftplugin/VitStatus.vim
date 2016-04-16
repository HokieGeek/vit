if exists("b:autoloaded_vit_status") || v:version < 700
    finish
endif
let b:autoloaded_vit_status = 1
scriptencoding utf-8

call vit#GetGitConfig(b:vit_ref_file)
" if exists("b:vit_git_version") && (b:vit_git_version[0] > 1 || b:vit_git_version[1] > 7 || (b:vit_git_version[1] == 7 && b:vit_git_version[2] > 2))
"     call vit#LoadContent(vit#ExecuteGit("status --short --branch"))
" else
    " GET CHANGED (must be in root dir) let l:changedfiles = call vit#ExecuteGit("ls-files --exclude-from='".b:vit_root_dir."/.gitignore" -t --modified --deleted --others")
    " GET STAGED  let l:stagedfiles = call vit#ExecuteGit("diff-index --cached HEAD --")
    call vit#LoadContent(vit#ExecuteGit("status --short"))
" endif

" Set width of the window based on the widest text
set winminwidth=1
let b:max_cols = max(map(getline(1, "$"), "len(v:val)")) + 5
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
    autocmd BufWritePost * call vit#RefreshStatus() "TODO: only do this autocmd when a VitStatus window is open
    autocmd BufDelete,BufWipeout <buffer> autocmd! VitStatus
augroup END

nnoremap <buffer> <silent> + :if getline(".") !~ "^##"<bar>call vit#Add(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>
nnoremap <buffer> <silent> - :if getline(".") !~ "^##"<bar>call vit#Unstage(split(getline("."))[1])<bar>wincmd p<bar>endif<cr>

nnoremap <buffer> <silent> o :if getline(".") !~ "^##"<bar>call vit#OpenFileAsDiff(split(getline("."))[1])<bar>endif<cr>
" TODO nnoremap <buffer> <silent> O :call vit#OpenFilesInRevisionAsDiff(GetRevFromShow())<cr>
