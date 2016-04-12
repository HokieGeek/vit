if exists("g:autoloaded_vit") || v:version < 700
    finish
endif
let g:autoloaded_vit = 1
scriptencoding utf-8

" Helpers {{{
function! vit#init()
    if exists("b:vit_initialized")
        return
    endif
    let b:vit_initialized = 0

    " Determine if we have a git executable
    if !executable("git")
        return
    endif
    
    " .... somehow determine we are in standalone mode ... ¯\_(ツ)_/¯
    if expand("%") ==# "" && argc() <= 0
        let b:vit_is_standalone = 0
    elseif strlen(bufname("%")) <= 0
        return
    endif
    
    call vit#GetGitConfig("%")

    " Add autocmds
    autocmd BufWritePost <buffer> call vit#RefreshStatus() "TODO: only do this autocmd when a VitStatus window is open
    command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :execute Git(<f-args>)
endfunction
function! vit#GetGitConfig(file)
    " Check if the *file* is inside a git directory
    silent! call system("cd ".expand(a:file.":p:h")."; git rev-parse --is-inside-work-tree >/dev/null 2>&1")
    if v:shell_error != 0
        return
    endif
    
    " Determine the git directories
    let b:vit_git_dir = substitute(system("git rev-parse --git-dir"), "\n*$", '', '')
    if b:vit_git_dir[0] != "/"
        let b:vit_git_dir = getcwd()."/".b:vit_git_dir
    endif
    let b:vit_root_dir = substitute(system("git rev-parse --show-toplevel"), "\n*$", '', '')
    let b:vit_git_cmd = "git --git-dir=".b:vit_git_dir." --work-tree=".b:vit_root_dir
    " echomsg "GIT DIR:".b:vit_git_dir
    " echomsg "ROOT DIR:".b:vit_root_dir
    
    " Determine the version of git
    let b:vit_git_version = split(substitute(substitute(system("git --version"), "\n*$", '', ''), "^git version ", '', ''), "\\.")
endfunction

function! vit#ExecuteGit(args)
    if exists("b:vit_git_cmd") && strlen(a:args) > 0
        return system(b:vit_git_cmd." ".a:args)
    endif
endfunction

function! vit#GetBranch()
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        let l:file = readfile(b:vit_git_dir."/HEAD")
        return substitute(l:file[0], 'ref: refs/heads/', '', '')
    else
        return ""
    endif
endfunction

function! vit#GetFilenameRelativeToGit(file)
    let l:file = substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', '')
    return l:file
endfunction
function! vit#GetFilenamesRelativeToGit(file_list)
    let l:files = []
    for f in a:file_list
        call add(l:files, vit#GetFilenameRelativeToGit(f))
    endfor
    return l:files
endfunction

function! vit#GitFileStatus(file)
    let l:file = fnamemodify(a:file, ":p")
    let l:status = vit#ExecuteGit("status --porcelain ".l:file)

    if match(l:status, '^fatal') > -1
        let l:status_val = 0 " Not a git repo
    elseif strlen(l:status) == 0
        let l:status_val = 1 " Clean
    elseif match(l:status, '^?') > -1
        let l:status_val = 2 " Untracked
    elseif match(l:status, '^.M') > -1
        let l:status_val = 3 " Modified
    elseif match(l:status, '^ ') < 0
        let l:status_val = 4 " Staged
    else
        let l:status_val = -1 " foobar
    endif
    return l:status_val
endfunction
function! vit#GitCurrentFileStatus()
    return vit#GitFileStatus(expand("%:p:h"))
endfunction

function! vit#LoadContent(location, content)
    if a:location ==? "left"
        topleft vnew
    elseif a:location ==? "right"
        botright vnew
    elseif a:location ==? "top"
        topleft new
    elseif a:location ==? "bottom"
        botright new
    elseif a:location ==? "current-new"
        enew
    elseif a:location ==? "current"
        " no-op
    endif
    set buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable
    silent! put =a:content
    0d_
    let b:vit_original_file = expand("%")
endfunction
" }}}

" Commands {{{
"" Diff {{{
function! vit#Diff(rev, file)
    if len(a:file) > 0
        let l:file = fnamemodify(a:file, ":p")
    else
        let l:file = vit#GetFilenameRelativeToGit(expand("%"))
        " let l:file = fnamemodify(expand("%"), ":p")
    endif

    if len(expand("%")) == 0
        mkview! 9
    endif
    topleft vnew
    let b:vit_ref_file = l:file
    let b:git_revision = a:rev
    setlocal filetype=VitDiff
    
    wincmd l
    diffthis
    0
    setlocal modifiable "syntax=off

    wincmd t
endfunction
function! vit#DiffPrompt()
    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#Diff(l:response, "")
endfunction
function! DiffFromRev(rev, file)
    bdelete
    call vit#Diff(a:rev, a:file)
endfunction
" }}}

"" Blame {{{
function! vit#Blame()
    if len(expand("%")) == 0
        mkview! 9
    endif
    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    let l:cline = getcurpos()[1]
    set nofoldenable

    "" Load blame file on left and confiugure the window
    topleft vnew
    let b:vit_ref_file = l:file
    set filetype=VitBlame
    
    " Doing a windo will set the focus back on the original window
    " windo setlocal scrollbind nomodifiable nonumber
    " if exists("&relativenumber")
    "    windo setlocal norelativenumber
    " endif
    " call cursor(l:cline, 0)
endfunction
" }}}

"" Log {{{
function! vit#Log(file)
    if !exists("b:vit_is_standalone")
        mkview! 9
    endif
    if len(a:file) > 0
        let l:file = vit#GetFilenameRelativeToGit(a:file)
    else
        let l:file = ""
    endif
    topleft vnew
    let b:vit_ref_file = l:file
    
    setlocal filetype=VitLog
endfunction
function! vit#RefreshLog()
    for win_num in range(1, winnr('$'))
        if getbufvar(winbufnr(win_num), '&filetype') == "VitLog"
            call vit#Log(getbufvar(winbufnr(win_num), "vit_ref_file"))
            break
        endif
    endfor
endfunction
" }}}

"" Show {{{
function! vit#Show(rev)
    if expand("%") !=? ""
        mkview! 9
    endif
    if exists("b:vit_ref_file")
        let l:vit_ref_file = b:vit_ref_file
    else
        let l:vit_ref_file = vit#GetFilenameRelativeToGit(expand("%"))
        let b:vit_ref_file = l:vit_ref_file
    endif
    topleft new
    let b:vit_ref_file = l:vit_ref_file
    let b:git_revision = a:rev
    setlocal filetype=VitShow
endfunction
" }}}

"" Status {{{
function! vit#Status()
    for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
        if getbufvar(b, "&filetype") ==? "VitStatus"
            execute "bdelete! ".b
            break
        endif
    endfor

    let l:is_panel=(expand("%") !=? "" ? 1 : 0)
    if l:is_panel
        mkview! 9
    endif

    let l:git_cmd = b:vit_git_cmd
    let l:git_version = b:vit_git_version
    botright vnew
    let b:vit_git_cmd = l:git_cmd
    let b:vit_git_version = l:git_version
    
    setlocal filetype=VitStatus
    
    wincmd t
endfunction
function! vit#RefreshStatus()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitStatus"
            execute "bdelete! ".l:buf_num
            call vit#Status()
            break
        endif
    endfor
endfunction
" }}}

"" Add {{{
function! vit#Add(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    call vit#ExecuteGit("add ".l:files)
    echo "Added ".a:files." to the stage"
    call vit#RefreshStatus()
endfunction
" }}}

"" Commit {{{
function! vit#Commit(args)
    " Maybe, if the current file is marked as unstaged in any way, ask to add it?
    " if &modified && confirm("Current file has changed. Save it?", "Y\nn", 1) == 1
        " write
        " if vit#GitCurrentFileStatus() != 4 && confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            " call vit#AddFilesToGit(expand("%"))
        " endif
    " endif
    if vit#GitCurrentFileStatus() != 4
        if confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            call vit#Add(expand("%"))
        endif
    endif

    " I really hate having to enter the author every freaking time
    let l:args = a:args
    if strlen(a:args) > 0 && match(a:args, "--author=") > -1
        let l:args_list = split(l:args)
        let l:author = l:args_list[match(l:args_list, "--author=")]
        if l:author == "--author=''"
            let l:args = substitute(l:args, "--author=''", "", "")
            unlet! b:vit_commit_author
        else
            let b:vit_commit_author = l:author
        endif
    elseif exists("b:vit_commit_author")
        let l:args .= " ".b:vit_commit_author
    endif

    " If a message was already entered, just commit
    if match(l:args, " *-m ") > -1 || match(l:args, " *--message=") > -1
        call vit#PerformCommit(l:args)
    else " otherwise, open a window to enter the message
        call vit#CreateCommitMessagePane(l:args)
    endif
endfunction
function! vit#CreateCommitMessagePane(args)
    " Pop up a small window with for commit message
    let l:commit_message_file = tempname()
    let l:vit_git_dir = b:vit_git_dir
    if strlen(a:args) > 0
        call system("echo '# ARGUMENTS: ".a:args."' > ".l:commit_message_file)
    endif
    call vit#ExecuteGit("status -sb | awk '{ print \"# \" $0 }' >> ".l:commit_message_file)
    if expand("%") != ""
        mkview! 9
    endif
    botright new
    let b:vit_git_dir = l:vit_git_dir
    let b:vit_commit_args = a:args
    resize 10
    execute "edit ".l:commit_message_file
    set filetype=gitcommit
    setlocal modifiable
    call append(0, "")
    " autocmd BufWinLeave <buffer> call vit#GitCommitFinish()
endfunction
function! vit#PerformCommit(args)
    call vit#ExecuteGit("commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction
function! vit#GitCommitFinish()
    let l:commit_message_file = expand("%")
    call system("sed -i -e '/^#/d' -e '/^\\s*$/d' ".l:commit_message_file)
    " Check the size of the file. If it's empty or blank, we don't commmit
    if len(readfile(l:commit_message_file)) > 0
        let l:file_args = "--file=".l:commit_message_file." ".b:vit_commit_args
        call vit#PerformCommit(l:file_args)
    else
        echohl WarningMsg
        echomsg "Cannot commit without a commit message"
        echohl None
    endif
    silent execute "bdelete! ".l:commit_message_file
    call delete(l:commit_message_file)
    unlet l:commit_message_file
endfunction
" }}}

"" Push && Pull {{{
function! vit#Push(remote, branch)
    let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetRemote()
    let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetBranch()
    " echomsg "REMOTE: ".l:remote
    " echomsg "BRANCH: ".l:branch

    call vit#ExecuteGit("push ".l:remote." ".l:branch)
    call vit#RefreshStatus()
endfunction
function! vit#Pull(remote, branch, rebase)
    let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetRemote()
    let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetBranch()
    let l:rebase = a:rebase ? "--rebase" : ""

    call vit#ExecuteGit("pull ".l:rebase." ".l:remote."/".l:branch)
    call vit#RefreshStatus()
endfunction
function! vit#GetRemote()
    let l:remote = ""
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        execute "cd ".b:vit_root_dir
        " TODO: grep out .gitconfig for this value?
        let l:remotes = split(system("git --git-dir=".b:vit_git_dir." remote -v | grep push | awk '{ print $1 }'"))
        cd -
        if len(l:remotes) == 0
            echohl WarningMsg
            echomsg "No remotes found!"
            echohl
        elseif len(l:remotes) > 1
            let l:choices = join(l:remotes, "\n")
            let l:remote = confirm("Choose remote: ", l:choices, 1)
        else
            let l:remote = l:remotes[0]
        endif
    endif
    return l:remote
endfunction
" }}}

"" Reset {{{
function! vit#Reset(args)
    call vit#ResetFilesInGitIndex(a:args)
endfunction
function! vit#ResetFilesInGitIndex(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    call vit#ExecuteGit("reset ".l:files)
    echomsg "Unstaged ".a:files
    call vit#RefreshStatus()
endfunction
" }}}

"" Checkout {{{
function! vit#Checkout(args)
    call vit#CheckoutCurrentFile(a:args)
endfunction
function! vit#CheckoutCurrentFile(rev)
    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    call vit#ExecuteGit("checkout ".a:rev." ".l:file)
    edit l:file
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction
function! vit#CheckoutFromBuffer()
    let l:rev = b:git_revision
    bdelete
    call vit#CheckoutCurrentFile(l:rev)
endfunction
" }}}
" }}}

" Other {{{
function! vit#OpenFilesInCommit(rev)
    let l:rel_dir = substitute(getcwd(), b:vit_root_dir."/", "", "")."/"
    let l:ret = system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ sub(\"".l:rel_dir."\", \"\", $2); print $2 }'")
    let l:files = split(l:ret)
    if len(l:files) > 0
        bdelete
        setlocal modifiable
        silent execute "argadd ".join(l:files, ' ')
        bdelete %
        if exists("b:vit_is_standalone")
            unlet! b:vit_is_standalone
        endif
    else
        echohl WarningMsg
        echomsg "There are no files related to this commit"
        echohl None
    endif
endfunction
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
