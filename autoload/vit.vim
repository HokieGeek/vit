if exists("g:autoloaded_vit") || v:version < 700
    finish
endif
let g:autoloaded_vit = 1

" Helpers {{{
function! vit#init()
    " echomsg "init: ".getcwd()
    " Determine if we have a git executable
    if !executable("git")
        return
    endif

    if expand("%") ==# "" && argc() <= 0
        let b:vit_is_standalone = 0
    elseif strlen(bufname("%")) <= 0
        return
    endif

    " Determine the git dir
    let l:path = exists("b:vit_is_standalone") ?  getcwd() : expand("%:p:h")
    while(l:path != "/" && l:path != "C:\\" && len(l:path) > 0)
        if filereadable(l:path."/.git")
            execute "cd ".l:path
            let l:file = readfile(l:path."/.git")
            let b:vit_git_dir = substitute(l:file[0], 'gitdir: ', '', '')
            let b:vit_git_dir = fnamemodify(b:vit_git_dir, ":p")
            let b:vit_root_dir = l:path
            cd -
            break
        elseif isdirectory(l:path."/.git")
            let b:vit_root_dir = l:path
            let b:vit_git_dir = b:vit_root_dir."/.git"
            break
        endif
        let l:path = fnamemodify(l:path, ":h")
    endwhile
    " echomsg "ROOT DIR: ".b:vit_root_dir

    " Add autocmds
    autocmd BufWritePost * call vit#RefreshGitStatus()
    command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :execute Git(<f-args>)
endfunction

function! vit#GetFilenameRelativeToGit(file)
    " echomsg "a:file = ".a:file
    " echomsg "a:file (m) = ".fnamemodify(a:file, ":p")
    " echomsg "b:vit_root_dir = ".b:vit_root_dir."/"
    let l:file = substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', '')
    " echomsg "l:file = ".l:file
    return l:file
    " return substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', '')
endfunction

function! vit#GetFilenamesRelativeToGit(file_list)
    " return a:file_list
    let l:files = []
    for f in a:file_list
        call add(l:files, vit#GetFilenameRelativeToGit(f))
    endfor
    return l:files
endfunction

function! vit#GetGitRemote()
    let l:remote = ""
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        execute "cd ".b:vit_root_dir
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
function! vit#GetGitBranch()
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        let l:file = readfile(b:vit_git_dir."/HEAD")
        let l:branch = substitute(l:file[0], 'ref: refs/heads/', '', '')
        return l:branch
    else
        return ""
    endif
endfunction

function! vit#GitFileStatus(file)
    " let l:status = system("git status --porcelain | grep '\<".a:file."\>$'")
    let l:file = vit#GetFilenameRelativeToGit(a:file)
    execute "cd ".b:vit_root_dir
    let l:status = system("git --git-dir=".b:vit_git_dir." status --porcelain | egrep '[/\s]\?".l:file."$'")
    cd -
    " let l:status = vit#ExecuteGit("status --porcelain | egrep '[/\s]\?".l:file."$'")
    " echomsg "GitFileStatus(".a:file."[".l:file."]): ".l:status

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
    return vit#GitFileStatus(vit#GetFilenameRelativeToGit(expand("%:t")))
endfunction

function! vit#ExecuteGit(args)
    if exists("b:vit_root_dir") && exists("b:vit_git_dir") && strlen(a:args) > 0
        echomsg "ExecuteGit(".a:args.")"
        execute "cd ".b:vit_root_dir
        let l:ret = system("git --git-dir=".b:vit_git_dir." ".a:args)
        cd -
        echomsg "ExecuteGit(): ".l:ret
        return l:ret
    endif
endfunction
" }}}

" Load Content {{{
function! vit#LoadContent(location, command)
    let l:command = "!cd ".b:vit_root_dir."; ".a:command
    " echomsg "cmd: ".l:command
    let l:file_path = expand("%")
    if a:location == "left"
        topleft vnew
    elseif a:location == "right"
        botright vnew
    elseif a:location == "top"
        topleft new
    elseif a:location == "bottom"
        botright new
    endif
    set buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable
    execute "silent read ".l:command
    0d_
    let b:vit_original_file = l:file_path
endfunction
function! vit#PopDiff(command)
    if expand("%") != ""
        mkview! 9
    endif
    call vit#LoadContent("left", a:command)
    setlocal filetype=VitDiff nomodifiable
    diffthis
    autocmd BufDelete,BufWipeout <buffer> windo diffoff
    "|windo silent loadview 9
    wincmd l
    diffthis
    0
    setlocal modifiable "syntax=off
endfunction
function! vit#PopSynched(command)
    if expand("%") != ""
        mkview! 9
    endif
    let l:cline = line(".")
    set nofoldenable
    0
    call vit#LoadContent("left", a:command)
    windo setlocal scrollbind nomodifiable nonumber
    if exists("&relativenumber")
        windo set norelativenumber
    endif
    execute l:cline
    setlocal modifiable
endfunction
" }}}

" Loaded in windows {{{
function! vit#PopGitDiff(rev, file)
    if len(a:file) > 0
        let l:file = a:file
    else
        let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    endif
    if !exists("b:vit_git_dir")
        let l:vit_git_dir = getbufvar(l:file, "vit_git_dir")
    else
        let l:vit_git_dir = b:vit_git_dir
    endif
    call vit#PopDiff("git --git-dir=".l:vit_git_dir." show ".a:rev.":".l:file)
    " call vit#PopDiff(vit#ExecuteGit("show ".a:rev.":".l:file))
    " call vit#PopDiff("show ".a:rev.":".l:file)
    wincmd t
    let b:git_revision = a:rev
    " wincmd l
endfunction
function! vit#PopGitDiffPrompt()
    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#PopGitDiff(l:response, "")
endfunction
function! vit#PopGitBlame()
    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    call vit#PopSynched("git --git-dir=".b:vit_git_dir." blame --date=short ".l:file)
    wincmd p
    let b:vit_ref_file = l:file
    set filetype=VitBlame cursorline
    normal f)
    execute "vertical resize ".col(".")
    normal 0
    wincmd p
endfunction
function! vit#GetRevFromGitBlame()
    let l:rev = system("echo '".getline(".")."' | awk '{ print $1 }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    " echomsg "Blame rev: ".l:rev
    return l:rev
endfunction
function! vit#PopGitFileLog(file)
    if exists("b:vit_is_standalone")
        let l:file = ""
    else
        mkview! 9
        let l:file = vit#GetFilenameRelativeToGit(a:file)
    endif
    call vit#LoadContent("top", "git --git-dir=".b:vit_git_dir." log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' -- ".l:file)
    set filetype=VitLog nolist cursorline
    if exists("b:vit_is_standalone")
        if bufnr("$") > 1
            bdelete #
        endif
        resize
    else
        resize 10
    endif
    setlocal nomodifiable nonumber
    if exists("&relativenumber")
        set norelativenumber
    endif
    call cursor(line("."), 2)
    let b:vit_ref_file = a:file
endfunction
function! vit#RefreshGitFileLog()
    for win_num in range(1, winnr('$'))
        if getbufvar(winbufnr(win_num), '&filetype') == "VitLog"
            call vit#PopGitFileLog(getbufvar(winbufnr(win_num), "vit_ref_file"))
            break
        endif
    endfor
endfunction
function! vit#GetRevFromGitLog()
    let l:rev = system("echo '".getline(".")."' | cut -d '(' -f1 | awk '{ print $NF }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! vit#PopGitShow(rev)
    if expand("%") != ""
        mkview! 9
    endif
    " let b:vit_ref_file = vit#GetFilenameRelativeToGit(expand("%"))
    if exists("b:vit_ref_file")
        let l:vit_ref_file = b:vit_ref_file
    else
        let l:vit_ref_file = vit#GetFilenameRelativeToGit(expand("%"))
        let b:vit_ref_file = l:vit_ref_file
    endif
    call vit#LoadContent("top", "git --git-dir=".b:vit_git_dir." show ".a:rev)
    let b:vit_ref_file = l:vit_ref_file
    set filetype=VitShow nolist nocursorline
    if exists("b:vit_is_standalone")
        bdelete #
        resize
    else
        resize 25
    endif
    setlocal nomodifiable nonumber
    if exists("&relativenumber")
        set norelativenumber
    endif
    let b:git_revision = a:rev
endfunction
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
function! vit#HandleRevisionSelection()
    let l:rev = vit#GetRevFromGitLog()
    if exists("b:vit_is_standalone")
        call vit#OpenFilesInCommit(l:rev)
    else
        let l:file = b:vit_ref_file
        bdelete
        call vit#PopGitDiff(l:rev, l:file)
    endif
endfunction
function! vit#PopGitDiffFromShow()
    let l:rev = b:git_revision
    let l:file = b:vit_ref_file
    bdelete
    call vit#PopGitDiff(l:rev, l:file)
endfunction
function! vit#PopGitDiffFromBlame()
    let l:rev = vit#GetRevFromGitBlame()
    let l:file = b:vit_ref_file
    bdelete
    call vit#PopGitDiff(l:rev, l:file)
endfunction
function! vit#ShowFromLog()
    let l:rev = vit#GetRevFromGitLog()
    bdelete
    call vit#PopGitShow(l:rev)
endfunction
function! vit#ShowFromDiff()
    let l:rev = b:git_revision
    bdelete
    call vit#PopGitShow(l:rev)
endfunction
function! vit#ShowFromBlame()
    let l:rev = vit#GetRevFromGitBlame()
    bdelete
    call vit#PopGitShow(l:rev)
endfunction
function! vit#GitStatus()
    for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
        if getbufvar(b, "&filetype") ==? "VitStatus"
            execute "bdelete! ".b
            break
        endif
    endfor

    let l:is_panel=(expand("%") != "" ? 1 : 0)
    if l:is_panel
        mkview! 9
    endif

    let l:git_dir = b:vit_git_dir
    let l:root_dir = b:vit_root_dir
    " echomsg "git1: ".l:git_dir
    " echomsg "root1: ".l:root_dir
    execute "cd ".b:vit_root_dir
    call vit#LoadContent("right", "git --git-dir=".b:vit_git_dir." status -sb")
    cd -

    " Set width of the window based on the widest text
    set winminwidth=1
    let l:max_cols = max(map(getline(1, "$"), "len(v:val)")) + 1
    execute "vertical resize ".l:max_cols

    set filetype=VitStatus
    setlocal nolist nomodifiable nonumber "cursorline
    if exists("&relativenumber")
        set norelativenumber
    endif
    " echomsg "git2: ".l:git_dir
    " echomsg "root2: ".l:root_dir
    let b:vit_git_dir = l:git_dir
    let b:vit_root_dir = l:root_dir

    if l:is_panel
        wincmd t
    else
        only
    endif
endfunction
function! vit#LoadFileFromStatus(line)
    " let l:file = vit#GetFilenameRelativeToGit(split(a:line)[1])
    let l:file = b:vit_root_dir."/".split(a:line)[1]
    " echomsg "l:file = ".l:file
    execute bufwinnr(l:file)."wincmd w"
    if bufloaded(l:file)
        call vit#PopGitDiff('', '')
    else
        execute "edit ".l:file
    endif
endfunction
function! vit#RefreshGitStatus()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitStatus"
            execute "bdelete! ".l:buf_num
            call vit#GitStatus()
            break
        endif
    endfor
endfunction
" }}}

" External manipulators {{{
function! vit#CheckoutFromLog()
    let l:rev = vit#GetRevFromGitLog()
    bdelete
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! vit#CheckoutFromBlame()
    let l:rev = vit#GetRevFromGitBlame()
    bdelete
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! vit#CheckoutFromBuffer()
    let l:rev = b:git_revision
    bdelete
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! vit#AddFilesToGit(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    " echomsg l:files
    execute "cd ".b:vit_root_dir
    call system("git --git-dir=".b:vit_git_dir." add ".l:files)
    cd -
    echo "Added ".a:files." to the stage"
    call vit#RefreshGitStatus()
endfunction
function! vit#ResetFilesInGitIndex(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    call system("git --git-dir=".b:vit_git_dir." reset ".l:files)
    echomsg "Unstaged ".a:files
    call vit#RefreshGitStatus()
endfunction
function! vit#GitCommit(args)
    " Maybe, if the current file is marked as unstaged in any way, ask to add it?
    " if &modified && confirm("Current file has changed. Save it?", "Y\nn", 1) == 1
        " write
        " if vit#GitCurrentFileStatus() != 4 && confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            " call vit#AddFilesToGit(expand("%"))
        " endif
    " endif
    if vit#GitCurrentFileStatus() != 4
        if confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            call vit#AddFilesToGit(expand("%"))
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
    call system("git --git-dir=".l:vit_git_dir." status -sb | awk '{ print \"# \" $0 }' >> ".l:commit_message_file)
    if expand("%") != ""
        mkview! 9
    endif
    botright new
    execute "edit ".l:commit_message_file
    let b:vit_git_dir = l:vit_git_dir
    let b:vit_commit_args = a:args
    resize 10
    set filetype=gitcommit
    setlocal modifiable
    call append(0, "")
    autocmd BufWinLeave <buffer> call vit#GitCommitFinish()
endfunction
function! vit#PerformCommit(args)
    call system("git --git-dir=".b:vit_git_dir." commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshGitStatus()
    call vit#RefreshGitFileLog()
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
function! vit#GitCheckoutCurrentFile(rev)
    " let l:file = expand("%")
    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    call system("git --git-dir=".b:vit_git_dir." checkout ".a:rev." ".l:file)
    edit l:file
    call vit#RefreshGitStatus()
    call vit#RefreshGitFileLog()
endfunction
function! vit#GitPush(remote, branch)
    let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetGitRemote()
    let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetGitBranch()
    " echomsg "REMOTE: ".l:remote
    " echomsg "BRANCH: ".l:branch

    execute "cd ".b:vit_root_dir
    " echomsg "git --git-dir=".b:vit_git_dir." push ".l:remote." ".l:branch
    call system("git --git-dir=".b:vit_git_dir." push ".l:remote." ".l:branch)
    cd -
endfunction
function! vit#GitPull(remote, branch, rebase)
    let l:remote = (strlen(a:remote) > 0) ? a:remote : vit#GetGitRemote()
    let l:branch = (strlen(a:branch) > 0) ? a:branch : vit#GetGitBranch()
    let l:rebase = a:rebase ? "--rebase" : ""

    execute "cd ".b:vit_root_dir
    call system("git --git-dir=".b:vit_git_dir." ".l:rebase." pull ".l:remote."/".l:branch)
    cd -
endfunction
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
