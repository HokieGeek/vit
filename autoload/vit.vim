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

    call vit#GetGitConfig("%")

    " Add autocmds
    command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call Git(<f-args>)
endfunction

function! vit#GetGitConfig(file)
    if len(a:file) <= 0
        if exists("b:vit_ref_file")
            let l:reffile = b:vit_ref_file
        else
            return
        endif
    else
        let l:reffile = a:file
    endif

    let l:currdir = getcwd()
    execute "cd ".fnamemodify(l:reffile, ":p:h")

    " Determine the git directories
    let b:vit_root_dir = substitute(system("git rev-parse --show-toplevel"), "\n*$", '', '')
    if v:shell_error == 0 && len(b:vit_root_dir) > 0
        if b:vit_root_dir[0] != "/"
            let b:vit_root_dir = getcwd()."/".b:vit_root_dir
        endif

        let b:vit_git_dir = substitute(system("git rev-parse --git-dir"), "\n*$", '', '')
        if b:vit_git_dir[0] != "/"
            let b:vit_git_dir = getcwd()."/".b:vit_git_dir
        endif

        let b:vit_git_cmd = "git --git-dir=".b:vit_git_dir." --work-tree=".b:vit_root_dir

        " Determine the version of git
        " let b:vit_git_version = split(substitute(substitute(system("git --version"), "\n*$", '', ''), "^git version ", '', ''), "\\.")

        " echomsg "ROOT DIR: ".b:vit_root_dir
        " echomsg " GIT DIR: ".b:vit_git_dir
    endif
    execute "cd ".l:currdir
endfunction

function! vit#GetBranch()
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        let l:file = readfile(b:vit_git_dir."/HEAD")
        return substitute(l:file[0], 'ref: refs/heads/', '', '')
    else
        return ""
    endif
endfunction
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
function! vit#GetAbsolutePath(file)
    return fnamemodify(b:vit_root_dir."/".vit#GetFilenameRelativeToGit(a:file), ":p")
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
        " echom b:vit_git_cmd." ".a:args
        return system(b:vit_git_cmd." ".a:args)
    endif
endfunction

function! vit#LoadContent(content)
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile modifiable
    silent! put =a:content
    0d_
endfunction

function! vit#GetUserInput(message)
    call inputsave()
    let l:response = input(a:message)
    call inputrestore()
    return l:response
endfunction " }}}
" }}}

" Commands {{{
"""" Loaded in windows
function! vit#Diff(rev, file) " {{{
    if isdirectory(a:file)
        echohl WarningMsg
        echomsg "Cannot perform a diff against a directory"
        echohl None
    else
        topleft vnew
        let b:vit_ref_file = a:file
        let b:vit_revision = a:rev
        setlocal filetype=VitDiff
    endif
endfunction " }}}

function! vit#Blame(file) " {{{
    topleft vnew
    let b:vit_ref_file = a:file
    set filetype=VitBlame

    wincmd p
endfunction " }}}

function! vit#Log(file) " {{{
    topleft new
    let b:vit_ref_file = a:file
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

    wincmd t " TODO: is there a better place for this? Or should it just go away?
endfunction
function! vit#RefreshStatus()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitStatus"
            call vit#Status("")
            break
        endif
    endfor
endfunction " }}}

""" External manipulators
function! vit#Add(files) " {{{
    if a:files == "."
        let l:files = a:files
    else
        let l:files = join(vit#GetFilenamesRelativeToGit(split(a:files)), ' ')
    endif
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
        let l:vit_git_dir = b:vit_git_dir

        botright new
        let b:vit_git_dir = l:vit_git_dir
        let b:vit_commit_args = a:args
        set filetype=VitCommit
    endif
endfunction
function! vit#PerformCommit(args)
    call vit#ExecuteGit("commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshStatus()
    call vit#RefreshLog()
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
    call vit#ExecuteGit("checkout ".a:args)
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction
function! vit#CheckoutCurrentFile(rev)
    let l:file = vit#GetAbsolutePath(expand("%"))
    call vit#Checkout(a:rev, l:file)
    edit l:file
endfunction " }}}

function! vit#Stash(args) " {{{
    call vit#ExecuteGit("stash ".a:args)
    " TODO: reload any loaded buffers which have now changed
    "       ask user if this is something they want
    " for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
    "     if buffer_name exists in list of stashed files
    "         call edit on that buffer
    "     endif
    " endfor
endfunction " }}}
" }}}

" Opening files {{{
function! vit#OpenFileAsDiff(file)
    execute "tabnew ".vit#GetAbsolutePath(a:file)
    call vit#Diff("", a:file)
endfunction
function! vit#OpenFilesInRevisionAsDiff(rev)
    let l:files = split(system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'"))

    let l:num_files_opened = 0
    let l:currtab = tabpagenr()
    for file in l:files
        if !isdirectory(file)
            let l:num_files_opened += 1
            call vit#OpenFileAsDiff(file)
        endif
    endfor

    if l:num_files_opened > 0
        execute "tabnext ".l:currtab
    else
        echohl WarningMsg
        echomsg "There are no files related to the selected revision"
        echohl None
    endif
endfunction
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
