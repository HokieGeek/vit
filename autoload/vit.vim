if exists("g:autoloaded_vit") || v:version < 700
    finish
endif
let g:autoloaded_vit = 1
scriptencoding utf-8

function! vit#init() " {{{
    if exists("b:vit_initialized")
        return
    endif
    let b:vit_initialized = 1

    " Determine if we have a git executable
    if !executable("git")
        return
    endif

    call s:GetGitConfig(expand("%"))

    " Add autocmds
    if exists("b:vit")
        command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call vit#Git(<f-args>)
    endif
endfunction " }}}

" Buffer object {{{
function! s:GetGitConfig(file) " {{{
    let l:reffile = a:file
    let l:reffile_dir = fnamemodify(l:reffile, ":p:h")

    " Determine the git directories
    let l:vit_root_dir = substitute(system("cd ".l:reffile_dir."; git rev-parse --show-toplevel"), "\n*$", '', '')
    if v:shell_error == 0 && len(l:vit_root_dir) > 0
        if !exists("b:vit")
            let b:vit = {}
            let b:vit["bufnr"] = bufnr(l:reffile)
        endif

        if l:vit_root_dir[0] != "/"
            let l:vit_root_dir = l:reffile_dir."/".l:vit_root_dir
        endif

        let l:vit_git_dir = substitute(system("cd ".l:reffile_dir."; git rev-parse --git-dir"), "\n*$", '', '')
        if l:vit_git_dir[0] != "/"
            let l:vit_git_dir = l:reffile_dir."/".l:vit_git_dir
        endif

        "" Git stuffs
        let b:vit["worktree"] = l:vit_root_dir
        let b:vit["gitdir"]   = l:vit_git_dir
        let b:vit["reffile"]  = l:reffile

        "" File paths
        let l:paths = {}
        let l:paths["relative"] = vit#GetFilenameRelativeToGit(l:reffile)
        let l:paths["absolute"] = fnamemodify(l:reffile, ":p")
        let b:vit["path"] = l:paths

        "" Vit window numbers placeholder
        let b:vit["windows"] = { "log": -1, "show": -1, "blame": -1, "status": -1, "diff": -1 }

        "" Functions
        let b:vit["name"]     = function("s:BufferName")
        let b:vit["execute"]  = function("s:ExecuteGit")
        let b:vit["branch"]   = function("s:GetBranch")
        let b:vit["status"]   = function("s:GitStatus")
        let b:vit["revision"] = function("s:GetFileRevision")
    endif
endfunction " }}}

function! s:GetBranch() dict " {{{
    let l:file = readfile(self.gitdir."/HEAD")
    return substitute(l:file[0], 'ref: refs/heads/', '', '')
endfunction
" }}}

function! s:GetFileRevision() dict " {{{
    return self.execute("--no-pager log --no-color -n 1 --pretty=format:%H -- ".self.paths.absolute)
endfunction " }}}

function! s:GitStatus() dict " {{{
    let l:status = self.execute("status --porcelain -- ".self.path.absolute)

    if strlen(l:status) == 0
        return 1 " Clean
    elseif l:status[0] == '?'
        return 2 " Untracked
    elseif l:status[1] ==# 'M'
        return 3 " Modified
    elseif l:status[0] != ' '
        return 4 " Staged
    elseif l:status =~ '^fatal'
        return 0 " Not a git repo
    else
        return -1 " foobar
    endif
endfunction " }}}

function! s:ExecuteGit(args) dict " {{{
    if strlen(a:args) > 0
        " echom "git --git-dir=".self.gitdir." --work-tree=".self.worktree." ".a:args
        return system("git --git-dir=".self.gitdir." --work-tree=".self.worktree." ".a:args)
    endif
endfunction " }}}

function! s:BufferName() dict " {{{
    return bufname(self.bufnr)
endfunction " }}}
" }}}

" Helpers " {{{
function! vit#GetFilenameRelativeToGit(file)
    " TODO: first check map of bufnrs keyed by absolute file names
    return substitute(substitute(fnamemodify(a:file, ":p"), b:vit.worktree."/", '', ''), '/$', '', '')
endfunction
function! vit#GetFilenamesRelativeToGit(file_list)
    return map(a:file_list, 'vit#GetFilenameRelativeToGit(v:val)')
endfunction

function! vit#UserGitCommand(args)
    " TODO: do something with the command output?
    call b:vit.execute(a:args)
endfunction

function! vit#GetUserInput(message)
    call inputsave()
    let l:response = input(a:message)
    call inputrestore()
    return l:response
endfunction
" }}}

" Statusline " {{{
function! s:AssignHL(name,bg,fg,weight)
    let l:gui = "guibg=".a:bg[0]." guifg=".a:fg[0]
    let l:term = "ctermbg=".a:bg[1]." ctermfg=".a:fg[1]." cterm=".a:weight
    execute "highlight SL_HL_".a:name." ".l:gui." ".l:term
endfunction
function! s:StatuslineHighlights()
    let l:git_bg     = ["#f4d224", "178"]
    let l:red_bright = ["#ce0000", "196"]
    let l:green      = ["#0c8f0c", "22"]
    let l:white      = ["#ffffff", "7"]
    let l:black      = ["#000000", "232"]

    call s:AssignHL("VitBranch",                l:git_bg,     l:black,      "none")
    call s:AssignHL("VitModified",              l:git_bg,     l:red_bright, "bold")
    call s:AssignHL("VitStaged",                l:git_bg,     l:green,      "bold")
    call s:AssignHL("VitUntracked",             l:git_bg,     l:white,      "bold")

    let b:vit_defined_statusline_highlights=0
endfunction

function! vit#Statusline()
    let l:status=""
    if exists("b:vit")
        if !exists("b:vit_defined_statusline_highlights")
            call s:StatuslineHighlights()
        endif
        let l:branch = b:vit.branch()
        " echomsg "HERE: ".l:branch
        if len(l:branch) > 0
            let l:status = b:vit.status()
            " echomsg "Updating: ".localtime()." [".l:status."]"

            if l:status == 3 " Modified
                let l:hl = "%#SL_HL_VitModified#"
            elseif l:status == 4 " Staged and not modified
                let l:hl = "%#SL_HL_VitStaged#"
            elseif l:status == 2 " Untracked
                let l:hl = "%#SL_HL_VitUntracked#"
            else
                let l:hl = "%#SL_HL_VitBranch#"
            endif

            let l:status = l:hl."\ ".l:branch."\ "
        endif
    endif
    return l:status
endfunction
" }}}

" Commands {{{
"""" Loaded in windows
function! vit#Diff(file, rev) " {{{
    if isdirectory(a:file)
        echohl WarningMsg
        echomsg "Cannot perform a diff against a directory"
        echohl None
    else
        topleft vnew
        let b:vit = getbufvar(bufnr(a:file), "vit")
        let b:vit_revision = a:rev
        setlocal filetype=VitDiff
    endif
endfunction
function! vit#OpenFileAsDiff(file, ...)
    if a:0 > 0
        " End revision
        execute "tabnew ".fnamemodify(a:file, ":p:.")
        if a:0 > 1
            let b:vit_revision = a:2
            setlocal filetype=VitDiff
        endif

        " Start revision
        call vit#Diff(a:file, a:1)
    else
        echohl WarningMsg
        echomsg "No revision specified. Cannot diff file"
        echohl None
    endif
endfunction
function! vit#OpenFilesInRevisionAsDiff(rev)
    let l:first_tab = tabpagenr() + 1

    let l:files = split(system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'"))
    let l:files = filter(l:files, '!isdirectory(v:val)')

    if len(l:files) > 0
        call map(l:files, 'vit#OpenFileAsDiff(v:val, "'.a:rev.'~1", "'.a:rev.'")')
        execute "tabnext ".l:first_tab
    else
        echohl WarningMsg
        echomsg "There are no files related to the selected revision"
        echohl None
    endif
endfunction " }}}

function! vit#Blame(file) " {{{
    if exists("b:vit") && b:vit.windows.blame < 0
        topleft vnew
        let b:vit = getbufvar(bufnr(a:file), "vit")
        set filetype=VitBlame

        wincmd p
        windo setlocal scrollbind
    endif
endfunction " }}}

function! vit#Log(file) " {{{
    if exists("b:vit")
        if b:vit.windows.log < 0
            topleft new
            let l:bufn = bufnr(a:file)
            if l:bufn >= 0
                let b:vit = getbufvar(l:bufn, "vit")
            endif
            setlocal filetype=VitLog
        else
            call vit#RefreshLog(b:vit.windows.log)
        endif
    endif
endfunction
function! vit#RefreshLog(buf_num)
    call setbufvar(a:buf_num, 'vit_reload', 1)
    call setbufvar(a:buf_num, '&filetype', 'VitLog')
endfunction
function! vit#RefreshLogs()
    let l:windows = filter(range(1, winnr('$')), 'getbufvar(winbufnr(v:val), "&filetype") == "VitLog"')
    call map(l:windows, 'vit#RefreshLog(winbufnr(v:val))')
endfunction " }}}

function! vit#Show(rev) " {{{
    if len(a:rev) > 0
        let l:rev = a:rev
    else
        let l:rev = b:vit.revision()
    endif

    let l:bufnr = bufnr("%")
    if &lines > 20
        botright new
    else
        botright vnew
    endif
    let b:vit = getbufvar(l:bufnr, "vit")
    let b:git_revision = l:rev
    setlocal filetype=VitShow
endfunction " }}}

function! vit#Status() " {{{
    if exists("b:vit")
        if b:vit.windows.status < 0
            let l:winnr = winnr()
            let l:bufnr = bufnr("%")
            botright vnew
            let b:vit_parent_win = l:winnr
            let b:vit = getbufvar(l:bufnr, "vit")
            setlocal filetype=VitStatus
        else
            call vit#RefreshStatus(b:vit.windows.status)
        endif
    endif
endfunction
function! vit#RefreshStatus(buf_num)
    call setbufvar(a:buf_num, 'vit_reload', 1)
    call setbufvar(a:buf_num, '&filetype', 'VitStatus')
endfunction
function! vit#RefreshStatuses()
    let l:windows = filter(range(1, winnr('$')), 'getbufvar(winbufnr(v:val), "&filetype") == "VitStatus"')
    call map(l:windows, 'vit#RefreshStatus(winbufnr(v:val))')
endfunction " }}}

""" External manipulators
function! vit#Add(files) " {{{
    let l:files = join(split(a:files), ' ')
    call b:vit.execute("add ".l:files)
    if v:shell_error == 0
        echo "Added ".a:files." to the stage"
        call vit#RefreshStatuses()
    else
        echo "Unable to add ".a:files." to the stage"
    endif
endfunction " }}}

function! vit#Commit(args) " {{{
    let l:currFileStatus = b:vit.status()
    if l:currFileStatus == 2 || l:currFileStatus == 3
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
        botright new
        let b:vit_commit_args = a:args
        set filetype=VitCommit
    endif
endfunction
function! vit#PerformCommit(args)
    " echom "vit#PerformCommit(".a:args.")"
    call b:vit.execute("commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshStatuses()
    " call vit#RefreshLogs()
endfunction " }}}

function! vit#Reset(args) " {{{
    call b:vit.execute("reset ".a:args)
    call vit#RefreshStatuses()
    " call vit#RefreshLogs() " FIXME: this is problematic
endfunction
function! vit#ResetFilesInGitIndex(opts, files)
    let l:files = join(split(a:files), ' ')
    call vit#Reset(a:opts." -- ".l:files)
endfunction
function! vit#Unstage(files)
    call vit#ResetFilesInGitIndex("HEAD", a:files)
    echomsg "Unstaged ".a:files
endfunction " }}}

function! vit#Checkout(args) " {{{
    call b:vit.execute("checkout ".a:args)
    call vit#RefreshStatuses()
    " call vit#RefreshLogs()
endfunction
function! vit#CheckoutCurrentFile(rev)
    let l:file = expand("%:p")
    call vit#Checkout(a:rev, l:file)
    edit l:file
endfunction " }}}


function! vit#Stash(args) " {{{
    let l:out = b:vit.execute("stash ".a:args)
    call vit#RefreshStatuses()
    call vit#RefreshLogs()
    return l:out
endfunction
function! vit#StashViewer()
    if !exists("g:vit_standalone")
        tabnew
    endif
    set filetype=VitStash
endfunction " }}}

function! vit#Move(newpath) " {{{
    if exists("b:vit")
        let l:bufn = bufnr("%")
        let l:newpath = substitute(getcwd()."/".a:newpath, b:vit.worktree."/", '', '')
        call b:vit.execute("mv ".b:vit.path.relative." ".l:newpath)
        if v:shell_error == 0
          execute "edit ".l:newpath
          execute "bdelete ".l:bufn
          call vit#RefreshStatuses()
        else
            echo "Unable to move file"
        endif
    endif
endfunction " }}}

function! vit#Remove() " {{{
    if exists("b:vit")
        call b:vit.execute("rm ".b:vit.path.relative)
        if v:shell_error == 0
            bdelete
            call vit#RefreshStatuses()
        else
            echo "Unable to remove file(s)"
        endif
    endif
endfunction " }}}

function! vit#RevertFile(rev, file) " {{{
    if confirm("Are you sure you want to git revert this file?", "y\nN", 0) == 1 && exists("b:vit")
        call vit#Checkout(a:rev." -- ".a:file)
        let l:msg = b:vit.execute("cat-file commit ".a:rev)
        call vit#PerformCommit("-m 'Reverted ".a:file." to ".a:rev." \"".split(l:msg, '\n')[5]."\"'")
    endif
endfunction " }}}

" vim: set foldmethod=marker formatoptions-=tc:
