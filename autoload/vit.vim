" Helpers {{{
function! vit#GetGitBranch()
    if exists("b:GitDir") && len(b:GitDir) > 0
        let l:file = readfile(b:GitDir."/HEAD")
        let l:branch = substitute(l:file[0], 'ref: refs/heads/', '', '')
        return l:branch
    else
        return ""
    endif
endfunction
function! vit#GitFileStatus(file)
    " let l:status = system("git status --porcelain | grep '\<".a:file."\>$'")
    let l:status = system("git status --porcelain | egrep '[/\s]\?".a:file."$'")
    " echomsg "GitFileStatus(".a:file."): ".l:status

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

    " echomsg "STATUS: ".l:status_val
    return l:status_val
endfunction
function! vit#GitCurrentFileStatus()
    return vit#GitFileStatus(expand("%:t"))
endfunction
function! vit#ExitVitWindow()
    if &filetype == "VitStatus" || &filetype == "VitLog" || &filetype == "VitShow" || &filetype == "VitDiff"
        call vit#ContentClear()
    endif
endfunction
" }}}

" Load Content {{{
function! vit#ContentClear()
    if exists("g:vit_loaded_output")
        set modifiable
        bdelete vit_content
        diffoff
        silent loadview 9
        unlet! g:vit_loaded_output
    endif
endfunction
function! vit#LoadContent(location, command)
    let g:vit_loaded_output = 1
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
    set buftype=nofile bufhidden=wipe
    execute "silent read ".a:command
    execute "silent file vit_content_".a:location
    0d_
    let b:vit_original_file = l:file_path
endfunction
function! vit#PopDiff(command)
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("left", a:command)
    set filetype=VitDiff
    wincmd l
    silent windo diffthis
    windo set nomodifiable
    0
    set modifiable syntax=off
endfunction
function! vit#PopSynched(command)
    call vit#ContentClear()

    mkview! 9
    let l:cline = line(".")
    set nofoldenable
    0
    call vit#LoadContent("left", a:command)
    windo set scrollbind nomodifiable
    execute l:cline
    set modifiable
endfunction
" }}}

" Loaded in windows {{{
function! vit#PopGitDiff(rev)
    call vit#PopDiff("!git show ".a:rev.":./#")
    " call vit#PopDiff("!git show ".a:rev.":".b:vit_original_file)
    wincmd t
    let b:git_revision = a:rev
    " wincmd l
endfunction
function! vit#PopGitDiffPrompt()
    call vit#ContentClear()

    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#PopGitDiff(l:response)
endfunction
function! vit#PopGitBlame()
    call vit#ContentClear()

    call vit#PopSynched("!git blame --date=short ".expand("%"))
    wincmd p
    set filetype=VitBlame cursorline
    normal f)
    execute "vertical resize ".col(".")
    normal 0
    wincmd p
endfunction
function! vit#GetRevFromGitBlame()
    let l:rev = system("echo '".getline(".")."' | awk '{ print $1 }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    echomsg "Blame rev: ".l:rev
    return l:rev
endfunction
function! vit#PopGitLog(file)
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("top", "!git log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' ".a:file)
    set filetype=VitLog nolist cursorline
    resize 10
    set nomodifiable
    call cursor(line("."), 2)
endfunction
function! vit#PopGitLogCurrentFile()
    call vit#PopGitLog("#")
    " b:vit_original_file
endfunction
function! vit#GetRevFromGitLog()
    let l:rev = system("echo '".getline(".")."' | cut -d '(' -f1 | awk '{ print $NF }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! vit#PopGitShow(rev)
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("top", "!git show ".a:rev)
    set filetype=VitShow nolist
    resize 25
    set nomodifiable
    let b:git_revision = a:rev
endfunction
function! vit#PopGitDiffFromLog()
    call vit#PopGitDiff(vit#GetRevFromGitLog())
endfunction
function! vit#PopGitDiffFromShow()
    echomsg "Rev: ".b:git_revision
    call vit#PopGitDiff(b:git_revision)
endfunction
function! vit#PopGitDiffFromBlame()
    call vit#PopGitDiff(vit#GetRevFromGitBlame())
endfunction
function! vit#ShowFromLog()
    call vit#PopGitShow(vit#GetRevFromGitLog())
endfunction
function! vit#ShowFromDiff()
    call vit#PopGitShow(b:git_revision)
endfunction
function! vit#ShowFromBlame()
    call vit#PopGitShow(vit#GetRevFromGitBlame())
endfunction
function! vit#GitStatus()
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("right", "!git status -sb")
    set filetype=VitStatus

    " Set width of the window based on the widest text
    let l:num_lines = line("$")
    let l:i = 0
    let l:max_cols = 0
    while (l:i <= l:num_lines)
        let l:curr_line_cols = len(getline(l:i))
        if (l:curr_line_cols > l:max_cols)
            let l:max_cols = l:curr_line_cols
        endif
        let l:i += 1
    endwhile
    let l:max_cols += 1
    set winwidth=5
    execute "vertical resize ".l:max_cols

    set nolist nomodifiable
    wincmd t
endfunction
" }}}

" External manipulators {{{
function! vit#CheckoutFromLog()
    let l:rev = vit#GetRevFromGitLog()
    call vit#ContentClear()
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! vit#CheckoutFromBlame()
    let l:rev = vit#GetRevFromGitBlame()
    call vit#ContentClear()
    call vit#GitCheckoutCurrentFile(l:rev)
endfunction
function! vit#CheckoutFromBuffer()
    call vit#ContentClear()
    call vit#GitCheckoutCurrentFile(b:git_revision)
endfunction
function! vit#AddFilesToGit(files, display_status)
    call system("git add ".a:files)
    echomsg "Added ".a:files." to the stage"
    " if a:display_status == 1
        " call vit#GitStatus()
    " endif
endfunction
function! vit#ResetFilesInGitIndex(files, display_status)
    call system("git reset ".a:files)
    echomsg "Unstaged ".a:files
    " if a:display_status == 1
        " call vit#GitStatus()
    " endif
endfunction
function! vit#AddCurrentFileToGit(display_status)
    call vit#AddFilesToGit(expand("%"), a:display_status)
endfunction
function! vit#ResetCurrentFileInGitIndex(display_status)
    call vit#ResetFilesInGitIndex(expand("%"), a:display_status)
endfunction
function! vit#GitCommit(args)
    " Maybe, if the current file is marked as unstaged in any way, ask to add it?
    " let l:tmp = vit#GitCurrentFileStatus()
    " echomsg "Git file status: ".l:tmp
    " if l:tmp != 4
    if vit#GitCurrentFileStatus() != 4
        " let l:response = confirm("Current file not staged. Add it?", "Y\nn", 1)
        " if l:response == 1
        if confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            call vit#AddCurrentFileToGit(0)
        endif
    endif
    " If a message was already entered, just commit
    if match(a:args, " *-m ") > -1 || match(a:args, " *--message=") > -1
        call vit#PerformCommit(a:args)
    else " otherwise, open a window to enter the message
        call vit#CreateCommitMessagePane(a:args)
    endif
endfunction
function! vit#CreateCommitMessagePane(args)
    " Pop up a small window with for commit message
    let l:commit_message_file = tempname().".vitcommitmsg"
    call system("git status -sb | awk '{ print \"# \" $0 }' > ".l:commit_message_file)
    mkview! 9
    botright new
    execute "edit ".l:commit_message_file
    let b:vit_commit_args = a:args
    resize 10
    set filetype=gitcommit
    normal ggO
endfunction
function! vit#PerformCommit(args)
    call system("git commit ".a:args)
    echomsg "Successfully committed"
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
    let l:file = expand("%")
    call system("git checkout ".a:rev." ".l:file)
    edit l:file
endfunction
" }}}

" Status line {{{
function! vit#StatusLine(win_num)
    let l:branch=vit#GetGitBranch()
    " echomsg "HERE: ".l:branch
    " let l:branch=b:GitBranch
    if len(l:branch) > 0
        let l:filename = bufname(winbufnr(a:win_num))
        let l:status=vit#GitFileStatus(l:filename)
        " echomsg "Updating: ".localtime()." [".l:status."]"

        if l:status == 3 " Modified
            let l:hl="%#SL_HL_GitModified#"
        elseif l:status == 4 " Staged and not modified
            let l:hl="%#SL_HL_GitStaged#"
        elseif l:status == 2 " Untracked
            let l:hl="%#SL_HL_GitUntracked#"
        else
            let l:hl="%#SL_HL_GitBranch#"
        endif

        return l:hl."\ ".l:branch."\ "
    else
        return ""
    endif
endfunction
" }}}

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
