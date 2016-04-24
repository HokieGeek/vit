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
    if len(a:file) <= 0
        if exists("b:vit_ref_file")
            let l:reffile = b:vit_ref_file
        else
            let l:reffile = getcwd()
        endif
    else
        let l:reffile = a:file
    endif

    let l:currdir = getcwd()
    execute "cd ".fnamemodify(l:reffile, ":p:h")

    " Determine the git directories
    let l:vit_root_dir = substitute(system("git rev-parse --show-toplevel"), "\n*$", '', '')
    if v:shell_error == 0 && len(l:vit_root_dir) > 0
        if !exists("b:vit")
            let b:vit = {}
            let b:vit["bufnr"] = bufnr(l:reffile)
        endif

        if l:vit_root_dir[0] != "/"
            let l:vit_root_dir = getcwd()."/".l:vit_root_dir
        endif

        let l:vit_git_dir = substitute(system("git rev-parse --git-dir"), "\n*$", '', '')
        if l:vit_git_dir[0] != "/"
            let l:vit_git_dir = getcwd()."/".l:vit_git_dir
        endif

        " let b:vit_git_cmd = "git --git-dir=".l:vit_git_dir." --work-tree=".l:vit_root_dir

        " Determine the version of git
        " let b:vit_git_version = split(substitute(substitute(system("git --version"), "\n*$", '', ''), "^git version ", '', ''), "\\.")

        "" Git stuffs
        let b:vit["worktree"] = l:vit_root_dir
        let b:vit["gitdir"]   = l:vit_git_dir
        " echomsg "ROOT DIR: ".b:vit.worktree
        " echomsg " GIT DIR: ".b:vit.gitdir

        "" File paths
        let l:paths = {}
        let l:paths["relative"] = vit#GetFilenameRelativeToGit(l:reffile)
        " let l:paths["relative"] = substitute(substitute(fnamemodify(l:reffile, ":p"), l:vit_root_dir."/", '', ''), '/$', '', '')
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

    else
        echom "crap"
    endif
    execute "cd ".l:currdir
endfunction " }}}

function! s:GetBranch() dict " {{{
    " if len(b:vit_git_dir) > 0
    let l:file = readfile(self.gitdir."/HEAD")
    return substitute(l:file[0], 'ref: refs/heads/', '', '')
endfunction
" }}}

function! s:GetFileRevision() dict " {{{
    return self.execute("--no-pager log --no-color -n 1 --pretty=format:%H -- ".self.paths.absolute)
endfunction " }}}

function! s:GitStatus() dict " {{{
    let l:status = self.execute("status --porcelain ".self.path.absolute)

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
        return system("git --git-dir=".self.gitdir." --work-tree=".self.worktree." ".a:args)
    endif
endfunction " }}}

function! s:BufferName() dict " {{{
    return bufname(self.bufnr)
endfunction " }}}
" }}}

"" Helpers " {{{
function! vit#GetFilenameRelativeToGit(file)
    return substitute(substitute(fnamemodify(a:file, ":p"), b:vit.worktree."/", '', ''), '/$', '', '')
    " return substitute(substitute(fnamemodify(a:file, ":p"), l:vit_root_dir."/", '', ''), '/$', '', '')
    " let l:vit = getbufvar(a:file, "vit")
    " return l:vit.path.relative()
endfunction
function! vit#GetFilenamesRelativeToGit(file_list)
    return map(l:file_list, 'vit#GetFilenameRelativeToGit(v:val)')
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
"" }}}

" TODO: On the way out " {{{
function! vit#GetBranch()
    return b:vit.branch()
endfunction
function! vit#GitFileStatus(file)
    let l:vit = getbufvar(a:file, "vit")
    return l:vit.status()
endfunction
function! vit#GitCurrentFileStatus()
    return b:vit.status()
endfunction
" }}}

" Commands {{{
"""" Loaded in windows
function! vit#Diff(rev, file) " {{{
    if isdirectory(a:file)
        echohl WarningMsg
        echomsg "Cannot perform a diff against a directory"
        echohl None
    else
        let l:bufnr = bufnr(a:file)
        topleft vnew
        let b:vit_ref_bufnr = l:bufnr
        let b:vit_revision = a:rev
        setlocal filetype=VitDiff
    endif
endfunction
function! vit#OpenFileAsDiff(file)
    let l:vit = getbufvar(a:file, "vit")
    execute "tabnew ".fnamemodify(a:file, ":p")
    call vit#Diff("", a:file)
endfunction
function! vit#OpenFilesInRevisionAsDiff(rev)
    let l:files = split(system("git diff-tree --no-commit-id --name-status --root -r ".a:rev." | awk '$1 !~ /^D/{ print $2 }'"))

    let l:num_files_opened = 0
    let l:first_tab = tabpagenr() + 1
    for file in l:files
        if !isdirectory(file)
            let l:num_files_opened += 1
            call vit#OpenFileAsDiff(file)
        endif
    endfor

    if l:num_files_opened > 0
        execute "tabnext ".l:first_tab
    else
        echohl WarningMsg
        echomsg "There are no files related to the selected revision"
        echohl None
    endif
endfunction " }}}

function! vit#Blame(file) " {{{
    mkview! 9
    let l:currline = line(".")
    setlocal nofoldenable

    let l:bufnr = bufnr(a:file)
    topleft vnew
    let b:vit_ref_bufnr = l:bufnr

    autocmd BufWinLeave <buffer> silent loadview 9
    " let b:vit_ref_file = a:file
    set filetype=VitBlame

    wincmd p
    execute "normal ".l:currline."gg"
    "setlocal scrollbind
endfunction " }}}

function! vit#Log(file) " {{{
    let l:bufnr = bufnr(a:file)
    topleft new
    let b:vit_ref_bufnr = l:bufnr
    setlocal filetype=VitLog
endfunction
function! vit#RefreshLog()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitLog"
            call setbufvar(l:buf_num, 'vit_reload', 1)
            call setbufvar(l:buf_num, '&filetype', 'VitLog')
        endif
    endfor
endfunction " }}}

function! vit#Show(rev) " {{{
    if len(a:rev) > 0
        let l:rev = a:rev
    else
        let l:rev = b:vit.revision()
    endif

    let l:bufnr = bufnr("%")
    botright new
    let b:git_revision = l:rev
    let b:vit_ref_bufnr = l:bufnr
    setlocal filetype=VitShow
endfunction " }}}

function! vit#Status(refdir) " {{{
    " TODO: Replace this with a single line to check for an entry in b:vit
    " for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
    "     if getbufvar(b, "&filetype") ==? "VitStatus"
    "         execute "bdelete! ".b
    "         break
    "     endif
    " endfor

    " echom "vit#Status(".refdir.")"

    " if strlen(a:refdir) <= 0
        " let l:file = expand("%")
    " else
        " let l:file = a:refdir
    " endif
    " let l:bufnr = bufnr("%")
    " let l:bufnr = bufnr(l:file)
    " echom "l:bufnr = ".l:bufnr
    botright vnew
    " let b:vit_ref_bufnr = l:bufnr
    " let b:vit_ref_file = l:file

    setlocal filetype=VitStatus
endfunction
function! vit#RefreshStatus()
    for win_num in range(1, winnr('$'))
        let l:buf_num = winbufnr(win_num)
        if getbufvar(l:buf_num, '&filetype') == "VitStatus"
            call setbufvar(l:buf_num, 'vit_reload', 1)
            call setbufvar(l:buf_num, '&filetype', 'VitStatus')
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
    " TODO
    call b:vit.execute("add ".l:files)
    echo "Added ".a:files." to the stage"
    call vit#RefreshStatus()
endfunction " }}}

function! vit#Commit(args) " {{{
    let l:currFileStatus = vit#GitCurrentFileStatus()
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
        let l:vit_git_dir = b:vit_git_dir

        botright new
        let b:vit_git_dir = l:vit_git_dir
        let b:vit_commit_args = a:args
        set filetype=VitCommit
    endif
endfunction
function! vit#PerformCommit(args)
    " echom "vit#PerformCommit(".a:args.")"
    call b:vit.execute("commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction " }}}

function! vit#Reset(args) " {{{
    call b:vit.execute("reset ".a:args)
    call vit#RefreshStatus()
    " call vit#RefreshLog() " FIXME: this is problematic
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
    call b:vit.execute("checkout ".a:args)
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction
function! vit#CheckoutCurrentFile(rev)
    let l:file = expand("%:p")
    call vit#Checkout(a:rev, l:file)
    edit l:file
endfunction " }}}

function! vit#Stash(args) " {{{
    call b:vit.execute("stash ".a:args)
    " TODO: reload any loaded buffers which have now changed
    "       ask user if this is something they want
    " for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
    "     if buffer_name exists in list of stashed files
    "         call edit on that buffer
    "     endif
    " endfor
endfunction " }}}
" }}}

" vim: set foldmethod=marker formatoptions-=tc:
