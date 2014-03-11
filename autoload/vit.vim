" Load Content {{{
function! vit#ContentClear()
    set modifiable
    bdelete vit_content
    diffoff
    silent loadview 9
    unlet! g:vit_loaded_output
endfunction
function! vit#LoadContent(location, command)
    let g:vit_loaded_output = 1
    if a:location == "left"
        topleft vnew
    elseif a:location == "right"
        botright vnew
    elseif a:location == "top"
        topleft new
    elseif a:location == "bottom"
        botright new
    endif
    set buftype=nofile
    execute "silent read ".a:command
    execute "silent file vit_content_".a:location
    0d_
endfunction
function! vit#PopDiff(command)
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    mkview! 9
    call vit#LoadContent("left", a:command)
    wincmd l
    silent windo diffthis
    windo set nomodifiable
    0
    set modifiable syntax=off
endfunction
function! vit#PopSynched(command)
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    mkview! 9
    let l:cline = line(".")
    set foldenable!
    0
    call vit#LoadContent("left", a:command)
    windo set scrollbind nomodifiable
    execute l:cline
    set modifiable
endfunction
" }}}

function! vit#GetGitBranch()
    if len(g:GitDir) > 0
        let l:file = readfile(g:GitDir."/HEAD")
        let l:branch = substitute(l:file[0], 'ref: refs/heads/', '', '')
        return l:branch
    else
        return ""
    endif

    " FIXME: This is really expensive how about we just read the file?
    " let l:branch = system("git branch | grep '^*' | sed 's/^\*\s*//'")
    " let l:branch = substitute(substitute(l:branch, '\s*\n*$', '', ''), '^\s*', '', '')
    " if match(l:branch, '^fatal') > -1
        " return ""
    " else
        " return l:branch
    " endif
endfunction
function! vit#GitFileStatus()
    let l:status = system("git status --porcelain | grep ".expand("%:t"))
    " FIXME: This fails a tad with similar files

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

function! vit#PopGitDiff(rev)
    call vit#PopDiff("!git show ".a:rev.":./#")
    let b:git_revision = a:rev
    " set filetype=GitDiff
endfunction
function! vit#PopGitDiffPrompt()
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#PopDiff(l:response)
endfunction
function! vit#PopGitBlame()
    call vit#PopSynched("!git blame --date=short #")
    wincmd p
    normal f)
    execute "vertical resize ".col(".")
    normal 0
    wincmd p
endfunction
function! vit#GetRevFromGitBlame()
    let l:rev = system("echo '".getline(".")."' | awk '{ print $1 }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! vit#PopGitLog()
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    mkview! 9
    call vit#LoadContent("top", "!git log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' #")
    set filetype=VitLog
    set nolist cursorline
    resize 10
    set nomodifiable
    call cursor(line("."), 2)
endfunction
function! vit#GetRevFromGitLog()
    let l:rev = system("echo '".getline(".")."' | cut -d '(' -f1 | awk '{ print $NF }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! vit#PopGitShow(rev)
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    mkview! 9
    call vit#LoadContent("top", "!git show ".a:rev)
    set filetype=VitShow
    set nolist
    resize 25
    set nomodifiable
    let b:git_revision = a:rev
endfunction
function! vit#PopGitDiffFromLog()
    let l:rev = vit#GetRevFromGitLog()
    call vit#PopGitDiff(l:rev)
endfunction
function! vit#ShowFromGitLog()
    call vit#PopGitShow(vit#GetRevFromGitLog())
endfunction
function! vit#ShowFromGitBuffer()
    call vit#PopGitShow(b:git_buffer)
endfunction
function! vit#CheckoutFromGitLog()
    " call system("git checkout `echo '".getline(".")."' | cut -d '(' -f1 | awk '{ print $NF }'` ./#")
    let l:rev = vit#GetRevFromGitLog()
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif
    vit#GitCheckout(l:rev)
    " call system("git checkout ".vit#GetRevFromGitLog()."./#")
    " if exists("g:vit_loaded_output")
        " call VitContentClear()
    " endif
endfunction
function! vit#PopGitDiffFromBuffer()
    call vit#PopGitDiff(b:git_revision)
endfunction
function! vit#AddFileToGit(display_status)
    call system("git add ".expand("%"))
    echomsg "Added ".expand("%")." to the stage"
    if a:display_status == 1
        call vit#GitStatus()
        " silent execute "3sleep"
        " call vit#ContentClear()
    endif
endfunction
function! vit#ResetFileInGitIndex(display_status)
    call system("git reset ".expand("%"))
    echomsg "Unstaged ".expand("%")
    if a:display_status == 1
        call vit#GitStatus()
    endif
endfunction
function! vit#GitStatus()
    if exists("g:vit_loaded_output")
        call vit#ContentClear()
    endif

    mkview! 9
    call vit#LoadContent("right", "!git status -sb")
    set filetype=VitStatus
    vertical resize 25
    set nolist nomodifiable
    wincmd t
endfunction
function! vit#GitCommit()
    " TODO: 1. (maybe) Display Git Status and ask for confirmation
    " call GitStatus()

    " 1a. Maybe, if the current file is marked as unstaged in any way, ask to add it?
    if vit#GitFileStatus() != 4
        let l:response = confirm("Add the file?", "Y\nn", 1)
        if l:response == 1
            call vit#AddFileToGit(0)
        endif
    endif

    " 2. Pop up a small window with for commit message
    let s:commit_message_file = "/tmp/".expand("%").".vitcommitmsg"
    call system("git status -sb | awk '{ print \"# \" $0 }' > ".s:commit_message_file)
    mkview! 9
    botright new
    execute "edit ".s:commit_message_file
    resize 10
    set filetype=gitcommit
    normal ggO
endfunction
function! vit#GitCommitFinish()
    call system("sed -i -e '/^#/d' -e '/^\\s*$/d' ".s:commit_message_file)
    if len(readfile(s:commit_message_file)) > 0
        " Check the size of the file. If it's empty or blank, we don't commmit
        call system("git commit --file=".s:commit_message_file)
        echomsg "Successfully committed this file"
        call delete(s:commit_message_file)
        silent execute "bdelete ".s:commit_message_file
        unlet s:commit_message_file
        redraw
    else
        echoerr "Cannot commit without a commit message"
    endif
endfunction
function! vit#GitCheckout(rev)
    call system("git checkout ".a:rev." ".expand("%"))
    " TODO: update buffer
endfunction

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
