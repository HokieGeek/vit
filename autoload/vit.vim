" Helpers {{{
function! vit#init()
    let l:path = expand("%:p:h")
    while(l:path != "/" && l:path != "C:\\" && len(l:path) > 0)
        if filereadable(l:path."/.git")
            let l:file = readfile(l:path."/.git")
            let b:vit_git_dir = substitute(l:file[0], 'gitdir: ', '', '')
            let b:vit_root_dir = l:path
            break
        elseif isdirectory(l:path."/.git")
            let b:vit_root_dir = l:path
            let b:vit_git_dir = b:vit_root_dir."/.git"
            break
        endif
        let l:path = fnamemodify(l:path, ":h")
    endwhile
    return ""
endfunction

function! vit#GetFilenameRelativeToGit(file)
    return substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', '')
endfunction

function! vit#GetFilenamesRelativeToGit(file_list)
    " return a:file_list
    let l:files = []
    for f in a:file_list
        call add(l:files, vit#GetFilenameRelativeToGit(f))
    endfor
    return l:files
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
    " let l:file = vit#GetFilenameRelativeToGit(a:file)
    let l:status = system("git --git-dir=".b:vit_git_dir." status --porcelain | egrep '[/\s]\?".a:file."$'")
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
    return l:status_val
endfunction
function! vit#GitCurrentFileStatus()
    return vit#GitFileStatus(vit#GetFilenameRelativeToGit(expand("%:t")))
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
        if expand("%") != ""
            silent loadview 9
        endif
        unlet! g:vit_loaded_output
        if exists(":EnableGoldenViewAutoResize")
            EnableGoldenViewAutoResize
        endif
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
    if exists(":DisableGoldenViewAutoResize")
        DisableGoldenViewAutoResize
    endif
    " nnoremap <buffer> <silent> q :<c-u>bdelete<cr>
endfunction
function! vit#PopDiff(command)
    call vit#ContentClear()

    if expand("%") != ""
        mkview! 9
    endif
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

    if expand("%") != ""
        mkview! 9
    endif
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
function! vit#PopGitDiff(rev, file)
    if len(a:file) > 0
        let l:file = a:file
    else
        let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    endif
    call vit#PopDiff("!git --git-dir=".b:vit_git_dir." show ".a:rev.":".l:file)
    wincmd t
    let b:git_revision = a:rev
    " wincmd l
endfunction
function! vit#PopGitDiffPrompt()
    call vit#ContentClear()

    call inputsave()
    let l:response = input('Commit, tag or branch: ')
    call inputrestore()
    call vit#PopGitDiff(l:response, "")
endfunction
function! vit#PopGitBlame()
    call vit#ContentClear()

    let l:file = vit#GetFilenameRelativeToGit(expand("%"))
    call vit#PopSynched("!git --git-dir=".b:vit_git_dir." blame --date=short ".l:file)
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
    call vit#ContentClear()

    if expand("%") !=# ""
        mkview! 9
        let l:standalone = 1
    else
        let l:standalone = 0
    endif
    let l:file = vit#GetFilenameRelativeToGit(a:file)
    call vit#LoadContent("top", "!git --git-dir=".b:vit_git_dir." log --graph --pretty=format:'\\%h (\\%cr) <\\%an> -\\%d \\%s' ".l:file)
    set filetype=VitLog nolist cursorline
    if l:standalone == 0
        let b:vit_is_standalone = 0
        bdelete 1
        resize
    else
        resize 10
    endif
    set nomodifiable nonumber
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
" function! vit#PopGitLogCurrentFile()
    " call vit#PopGitFileLog("#")
    " b:vit_original_file
" endfunction
function! vit#GetRevFromGitLog()
    let l:rev = system("echo '".getline(".")."' | cut -d '(' -f1 | awk '{ print $NF }'")
    let l:rev = substitute(substitute(l:rev, '\s*\n*$', '', ''), '^\s*', '', '')
    return l:rev
endfunction
function! vit#PopGitShow(rev)
    call vit#ContentClear()
    if expand("%") != ""
        mkview! 9
    endif
    let b:vit_ref_file = vit#GetFilenameRelativeToGit(expand("%"))
    call vit#LoadContent("top", "!git --git-dir=".b:vit_git_dir." show ".a:rev)
    set filetype=VitShow nolist
    resize 25
    set nomodifiable nonumber
    if exists("&relativenumber")
        set norelativenumber
    endif
    let b:git_revision = a:rev
endfunction
function! vit#OpenFilesInCommit(rev)
    let l:ret = system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'")
    let l:files = split(l:ret)
    if len(l:files) > 0
        silent execute "argadd ".join(l:files, ' ')
        call vit#ContentClear()
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
        call vit#PopGitDiff(l:rev, b:vit_ref_file)
    endif
endfunction
function! vit#PopGitDiffFromShow()
    " echomsg "Rev: ".b:git_revision
    call vit#PopGitDiff(b:git_revision, b:vit_ref_file)
endfunction
function! vit#PopGitDiffFromBlame()
    call vit#PopGitDiff(vit#GetRevFromGitBlame(), b:vit_ref_file)
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

    let l:is_panel=(expand("%") != "" ? 1 : 0)
    if l:is_panel
        mkview! 9
    endif

    call vit#LoadContent("right", "!git --git-dir=".b:vit_git_dir." status -sb")

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
    set winminwidth=1
    execute "vertical resize ".l:max_cols

    set filetype=VitStatus
    set nolist nomodifiable nonumber "cursorline
    if exists("&relativenumber")
        set norelativenumber
    endif

    if l:is_panel
        wincmd t
    else
        only
    endif
endfunction
function! vit#RefreshGitStatus()
    for win_num in range(1, winnr('$'))
        if getbufvar(winbufnr(win_num), '&filetype') == "VitStatus"
            call vit#GitStatus()
            break
        endif
    endfor
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
function! vit#AddFilesToGit(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    " echomsg l:files
    " call system("git --git-dir=".b:vit_git_dir." add ".l:files)
    call system("git --git-dir=".b:vit_git_dir." add ".l:files)
    echomsg "Added ".a:files." to the stage"
    call vit#RefreshGitStatus()
endfunction
function! vit#ResetFilesInGitIndex(files)
    let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    " let l:files = vit#GetFilenamesRelativeToGit(a:files)
    call system("git --git-dir=".b:vit_git_dir." reset ".l:files)
    echomsg "Unstaged ".a:files
    call vit#RefreshGitStatus()
endfunction
" function! vit#AddCurrentFileToGit()
    " call vit#AddFilesToGit(expand("%"))
" endfunction
" function! vit#ResetCurrentFileInGitIndex()
    " call vit#ResetFilesInGitIndex(expand("%"))
" endfunction
function! vit#GitCommit(args)
    " echomsg "vit#GitCommit(".a:args.")"
    " Maybe, if the current file is marked as unstaged in any way, ask to add it?
    " let l:tmp = vit#GitCurrentFileStatus()
    " echomsg "Git file status: ".l:tmp
    " if l:tmp != 4
    if vit#GitCurrentFileStatus() != 4
        " let l:response = confirm("Current file not staged. Add it?", "Y\nn", 1)
        " if l:response == 1
        if confirm("Current file not staged. Add it?", "Y\nn", 1) == 1
            call vit#AddFilesToGit(expand("%"))
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
    let l:commit_message_file = tempname()
    call system("git --git-dir=".b:vit_git_dir." status -sb | awk '{ print \"# \" $0 }' > ".l:commit_message_file)
    if expand("%") != ""
        mkview! 9
    endif
    botright new
    execute "edit ".l:commit_message_file
    let b:vit_commit_args = a:args
    resize 10
    set filetype=gitcommit
    normal ggO
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
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
