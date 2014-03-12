" Helpers {{{
function! vit#GetGitBranch()
    if len(g:GitDir) > 0
        let l:file = readfile(g:GitDir."/HEAD")
        let l:branch = substitute(l:file[0], 'ref: refs/heads/', '', '')
        return l:branch
    else
        return ""
    endif
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
    " set buftype=nofile "bufhidden=wipe nobuflisted
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
    call vit#PopSynched("!git blame --date=short ".expand("%"))
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
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("top", "!git log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' #")
    " call vit#LoadContent("top", "!git log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' ".b:vit_original_file)
    set filetype=VitLog nolist cursorline
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
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("top", "!git show ".a:rev)
    set filetype=VitShow nolist
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
    call vit#PopGitShow(b:git_revision)
endfunction
function! vit#PopGitDiffFromBuffer()
    call vit#PopGitDiff(b:git_revision)
endfunction
" }}}

" Status line {{{
highlight SL_HL_GitBranch ctermbg=25 ctermfg=232 cterm=bold
highlight SL_HL_GitModified ctermbg=25 ctermfg=88 cterm=bold
highlight SL_HL_GitStaged ctermbg=25 ctermfg=40 cterm=bold
highlight SL_HL_GitUntracked ctermbg=25 ctermfg=7 cterm=bold

function! vit#StatusLine()
    "FIXME 
    let l:branch=vit#GetGitBranch()
    " let l:branch=g:GitBranch
    if len(l:branch) > 0
        " TODO: only update the file status when the file is saved?
        let l:status=vit#GitFileStatus()
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

" External manipulators {{{
function! vit#CheckoutFromGitLog()
    let l:rev = vit#GetRevFromGitLog()
    call vit#ContentClear()
    call vit#GitCheckout(l:rev)
endfunction
function! vit#AddFileToGit(file, display_status)
    call system("git add ".a:file)
    echomsg "Added ".a:file." to the stage"
    if a:display_status == 1
        call vit#GitStatus()
        " silent execute "3sleep"
        " call vit#ContentClear()
    endif
endfunction
function! vit#AddCurrentFileToGit(display_status)
    call vit#AddFileToGit(expand("%"), a:display_status)
endfunction
function! vit#ResetFileInGitIndex(display_status)
    call system("git reset ".expand("%"))
    echomsg "Unstaged ".expand("%")
    if a:display_status == 1
        call vit#GitStatus()
    endif
endfunction
function! vit#GitStatus()
    call vit#ContentClear()

    mkview! 9
    call vit#LoadContent("right", "!git status -sb")
    set filetype=VitStatus
    vertical resize 25
    set nolist nomodifiable
    wincmd t
endfunction
function! vit#GitCommit()
    " Maybe, if the current file is marked as unstaged in any way, ask to add it?
    if vit#GitFileStatus() != 4
        let l:response = confirm("Add the file?", "Y\nn", 1)
        if l:response == 1
            call vit#AddFileToGit(0)
        endif
    endif

    " Pop up a small window with for commit message
    let s:commit_message_file = "/tmp/".expand("%:t").".vitcommitmsg"
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
    " Check the size of the file. If it's empty or blank, we don't commmit
    if len(readfile(s:commit_message_file)) > 0
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
" }}}

" vim: set foldmethod=marker number relativenumber formatoptions-=tc:
