if exists("g:autoloaded_vit") || v:version < 700
    finish
endif
let g:autoloaded_vit = 1
scriptencoding utf-8

" Buffer object {{{
"" Repo info {{{
function! vit#init()
    if exists("b:vit_initialized")
        return
    endif
    let b:vit_initialized = 1

    " Determine if we have a git executable
    if !executable("git")
        return
    endif

    call vit#GetGitConfig(expand("%"))

    " Add autocmds
    if exists("b:vit")
        command! -bar -buffer -complete=customlist,vit#GitCompletion -nargs=* Git :call vit#Git(<f-args>)
    endif
endfunction

function! vit#GetGitConfig(file)
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
    let b:vit_root_dir = substitute(system("git rev-parse --show-toplevel"), "\n*$", '', '')
    if v:shell_error == 0 && len(b:vit_root_dir) > 0
        if !exists("b:vit")
            let b:vit = {}
            let b:vit["bufnr"] = bufnr(l:reffile)
        endif

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

        "" Git stuffs
        let b:vit["worktree"] = b:vit_root_dir
        let b:vit["gitdir"]   = b:vit_git_dir
        let b:vit["gitcmd"]   = b:vit_git_cmd
        " echomsg "ROOT DIR: ".b:vit_root_dir
        " echomsg " GIT DIR: ".b:vit_git_dir
        " echomsg "ROOT DIR: ".b:vit.worktree
        " echomsg " GIT DIR: ".b:vit.gitdir

        "" File paths
        let l:paths = {}
        let l:paths["relative"] = vit#GetFilenameRelativeToGit(l:reffile)
        let l:paths["absolute"] = fnamemodify(l:reffile, ":p")
        let b:vit["path"] = l:paths

        "" Vit window numbers placeholder
        let b:vit["windows"] = { "log": -1, "show": -1, "blame": -1, "status": -1 }

        "" Functions
        " echom "here"
        let b:vit["execute"]  = function("s:ExecuteGit")
        let b:vit["branch"]   = function("s:GetBranch")
        let b:vit["status"]   = function("s:GitStatus")
        let b:vit["revision"] = function("s:GetFileRevision")

    else
        echom "crap"
    endif
    execute "cd ".l:currdir
endfunction

function! s:GetBranch() dict " {{{
    " if len(b:vit_git_dir) > 0
    let l:file = readfile(self.gitdir."/HEAD")
    return substitute(l:file[0], 'ref: refs/heads/', '', '')
endfunction
" }}}
" }}}

"" File info {{{
function! vit#GetFilenameRelativeToGit(file)
    return substitute(substitute(fnamemodify(a:file, ":p"), b:vit_root_dir."/", '', ''), '/$', '', '')
endfunction
function! vit#GetFilenamesRelativeToGit(file_list)
    return map(l:file_list, 'vit#GetFilenameRelativeToGit(v:val)')
endfunction
function! vit#GetAbsolutePath(file)
    return fnamemodify(b:vit_root_dir."/".vit#GetFilenameRelativeToGit(a:file), ":p")
endfunction

function! s:GetFileRevision() dict
    return self.execute("--no-pager log --no-color -n 1 --pretty=format:%H -- ".self.paths.absolute)
endfunction

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
endfunction
" function! s:GitCurrentFileStatus() dict
    " return vit#GitFileStatus(expand("%:p:h"))
" endfunction " }}}
" }}}

" Misc " {{{
function! s:ExecuteGit(args) dict
    " if exists("b:vit_git_cmd") && strlen(a:args) > 0
    if strlen(a:args) > 0
        " echom self.gitcmd." ".a:args
        return system(self.gitcmd." ".a:args)
    endif
endfunction
" }}}

" }}}

"" Helpers " {{{
function! vit#UserGitCommand(args)
    " TODO: do something with the command output?
    call vit#ExecuteGit(a:args)
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
    if exists("b:vit_git_dir") && len(b:vit_git_dir) > 0
        let l:file = readfile(b:vit_git_dir."/HEAD")
        return substitute(l:file[0], 'ref: refs/heads/', '', '')
    else
        return ""
    endif
endfunction

function! vit#ExecuteGit(args)
    if exists("b:vit_git_cmd") && strlen(a:args) > 0
        " echom b:vit_git_cmd." ".a:args
        return system(b:vit_git_cmd." ".a:args)
    endif
endfunction

function! vit#GitFileStatus(file)
    if strlen(a:file) > 0
        let l:file = fnamemodify(a:file, ":p")
        let l:status = vit#ExecuteGit("status --porcelain ".l:file)

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
    else
        return 2 " Untracked
    endif
endfunction
function! vit#GitCurrentFileStatus()
    return vit#GitFileStatus(expand("%:p:h"))
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
        topleft vnew
        let b:vit_ref_file = a:file
        let b:vit_revision = a:rev
        setlocal filetype=VitDiff
    endif
endfunction
function! vit#OpenFileAsDiff(file)
    execute "tabnew ".vit#GetAbsolutePath(a:file)
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
    " echom "vit#Blame()"
    mkview! 9
    let l:currline = line(".")
    setlocal nofoldenable

    let l:bufnr = bufnr(a:file)
    topleft vnew
    let b:vit_ref_bufnr = l:bufnr
    " unlet! b:vit " Well this is a hack...

    autocmd BufWinLeave <buffer> silent loadview 9
    let b:vit_ref_file = a:file
    set filetype=VitBlame

    wincmd p
    execute "normal ".l:currline."gg"
    "setlocal scrollbind
endfunction " }}}

function! vit#Log(file) " {{{
    " let l:bufnr = bufnr("%")
    let l:bufnr = bufnr(a:file)
    " echom "vit#Log(".a:file."): ".l:bufnr
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
    " echom "vit#Show(".a:rev.")"
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
    for b in filter(range(0, bufnr('$')), 'bufloaded(v:val)')
        if getbufvar(b, "&filetype") ==? "VitStatus"
            execute "bdelete! ".b
            break
        endif
    endfor

    " if strlen(a:refdir) <= 0
    "     let l:file = expand("%")
    " else
    "     let l:file = a:refdir
    " endif
    let l:bufnr = bufnr("%")
    botright vnew
    let b:vit_ref_bufnr = l:bufnr
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
    call vit#ExecuteGit("add ".l:files)
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
    call vit#ExecuteGit("commit ".a:args)
    echomsg "Successfully committed"
    call vit#RefreshStatus()
    call vit#RefreshLog()
endfunction " }}}

function! vit#Reset(args) " {{{
    call vit#ExecuteGit("reset ".a:args)
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

" vim: set foldmethod=marker formatoptions-=tc:
