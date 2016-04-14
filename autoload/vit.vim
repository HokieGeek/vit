if exists("g:autoloaded_vit") || v:version < 700
    finish
endif
let g:autoloaded_vit = 1
scriptencoding utf-8

" Helpers {{{
"" Repo info {{{
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
    " if expand("%") ==# "" && argc() <= 0
    "     let b:vit_is_standalone = 0
    " elseif strlen(bufname("%")) <= 0
    "     return
    " endif

    call vit#GetGitConfig("%")

    " Add autocmds
    autocmd BufWritePost <buffer> call vit#RefreshStatus() "TODO: only do this autocmd when a VitStatus window is open
    command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call Git(<f-args>)
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

function! vit#GetBranch()
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        let l:file = readfile(b:vit_git_dir."/HEAD")
        return substitute(l:file[0], 'ref: refs/heads/', '', '')
    else
        return ""
    endif
endfunction

" function! vit#GetRemote()
"     let l:remote = ""
"     if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
"         execute "cd ".b:vit_root_dir
"         " TODO: grep out .gitconfig for this value?
"         let l:remotes = split(system("git --git-dir=".b:vit_git_dir." remote -v | grep push | awk '{ print $1 }'"))
"         cd -
"         if len(l:remotes) == 0
"             echohl WarningMsg
"             echomsg "No remotes found!"
"             echohl
"         elseif len(l:remotes) > 1
"             let l:choices = join(l:remotes, "\n")
"             let l:remote = confirm("Choose remote: ", l:choices, 1)
"         else
"             let l:remote = l:remotes[0]
"         endif
"     endif
"     return l:remote
" endfunction
" }}}

"" File info {{{
function! vit#GetFilenameRelativeToGit(file)
    return substitute(substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', ''), '/$', '', '')
endfunction
function! vit#GetFilenamesRelativeToGit(file_list)
    let l:files = []
    for f in a:file_list
        call add(l:files, vit#GetFilenameRelativeToGit(fnamemodify(f, ":p")))
    endfor
    return l:files
endfunction

function! vit#GitFileStatus(file)
    if strlen(a:file) > 0
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
    else
        return 2 " Untracked
    endif
endfunction
function! vit#GitCurrentFileStatus()
    return vit#GitFileStatus(expand("%:p:h"))
endfunction
" }}}

function! vit#ExecuteGit(args)
    if exists("b:vit_git_cmd") && strlen(a:args) > 0
        return system(b:vit_git_cmd." ".a:args)
    endif
endfunction

function! vit#LoadContent(content)
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable
    silent! put =a:content
    0d_
endfunction
" }}}

" Commands {{{
"""" Loaded in windows
function! vit#Diff(rev, file) " {{{
    let l:file = vit#GetFilenameRelativeToGit(a:file)

    topleft vnew
    let b:vit_ref_file = l:file
    let b:vit_revision = a:rev
    setlocal filetype=VitDiff
endfunction
function! vit#DiffPrompt()
    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#Diff(l:response, "")
endfunction " }}}

function! vit#Blame(file) " {{{
    let l:file = vit#GetFilenameRelativeToGit(a:file)

    topleft vnew
    let b:vit_ref_file = l:file
    set filetype=VitBlame

    wincmd p
endfunction " }}}

function! vit#Log(file) " {{{
    let l:file = vit#GetFilenameRelativeToGit(a:file)

    topleft new
    let b:vit_ref_file = l:file
    setlocal filetype=VitLog
endfunction
function! vit#RefreshLog()
    for win_num in range(1, winnr('$'))
        if getbufvar(winbufnr(win_num), '&filetype') == "VitLog"
            call vit#Log(getbufvar(winbufnr(win_num), "vit_ref_file"))
        endif
    endfor
endfunction " }}}

function! vit#Show(rev) " {{{
    botright new
    let b:git_revision = a:rev
    setlocal filetype=VitShow
endfunction " }}}

function! vit#Status(refdir) " {{{
    for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
        if getbufvar(b, "&filetype") ==? "VitStatus"
            execute "bdelete! ".b
            break
        endif
    endfor

    if len(a:refdir) <= 0
        let l:file = expand("%") " TODO: would be better if it got a directory as an argument
    endif
    botright vnew
    let b:vit_ref_file = l:file

    setlocal filetype=VitStatus

    wincmd t
endfunction
function! vit#RefreshStatus()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitStatus"
            " execute "bdelete! ".l:buf_num
            call vit#Status()
            break
        endif
    endfor
endfunction " }}}

""" External manipulators
function! vit#Add(files) " {{{
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    call vit#ExecuteGit("add ".l:files)
    echo "Added ".a:files." to the stage"
    call vit#RefreshStatus()
endfunction " }}}

function! vit#Commit(args) " {{{
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
    call vit#ExecuteGit("status -s | awk '{ print \"# \" $0 }' >> ".l:commit_message_file)
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
    " TODO autocmd BufWinLeave <buffer> call vit#GitCommitFinish()
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
endfunction " }}}

function! vit#Reset(args) " {{{
    call vit#ExecuteGit("reset ".a:args)
    call vit#RefreshStatus()
endfunction
function! vit#ResetFilesInGitIndex(opts, files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    call vit#Reset(a:opts." -- ".l:files)
endfunction
function! vit#Unstage(files)
    call vit#ResetFilesInGitIndex("HEAD", a:files)
    echomsg "Unstaged ".a:files
endfunction " }}}

function! vit#Checkout(args) " {{{
    call vit#CheckoutCurrentFile(a:args)
endfunction
function! vit#CheckoutCurrentFile(rev)
    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    call vit#ExecuteGit("checkout ".a:rev." ".l:file)
    edit l:file
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction " }}}

" function! vit#Push(remote, branch) " {{{
"     let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetRemote()
"     let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetBranch()
"     " echomsg "REMOTE: ".l:remote
"     " echomsg "BRANCH: ".l:branch

"     call vit#ExecuteGit("push ".l:remote." ".l:branch)
"     call vit#RefreshStatus()
" endfunction " }}}

" function! vit#Pull(remote, branch, rebase) " {{{
"     let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetRemote()
"     let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetBranch()
"     let l:rebase = a:rebase ? "--rebase" : ""

"     call vit#ExecuteGit("pull ".l:rebase." ".l:remote."/".l:branch)
"     call vit#RefreshStatus()
" endfunction " }}}
" }}}

" Opening files {{{
function! vit#OpenFileAsDiff(file)
    execute "tabnew ".fnamemodify(a:file, ":p")
    call vit#Diff("", "")
endfunction
function! vit#OpenFilesInRevisionAsDiff(rev)
    let l:files = split(system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'"))
    if len(l:files) > 0
        let l:currtab = tabpagenr()
        for file in l:files
            call vit#OpenFileAsDiff(file)
        endfor
        execute "tabnext ".l:currtab
    else
        echohl WarningMsg
        echomsg "There are no files related to the selected revision"
        echohl None
    endif
endfunction
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
