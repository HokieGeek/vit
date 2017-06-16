if exists("g:autoloaded_vit_config") || v:version < 700
    finish
endif
let g:autoloaded_vit_config = 1

let s:vit_commands = ["log", "status", "blame", "diff", "show", "add", "reset", "checkout", "commit", "stash", "mv", "rm", "revert", "k"]

function! vit#config#gitcompletion(arg_lead, cmd_line, cursor_pos) " {{{
    if a:cmd_line =~# "^Git add "
        let l:files = split(glob(b:vit_root_dir."/".a:arg_lead."*"))
        let l:files = map(l:files, 'v:val.(isdirectory(v:val)?"/":"")')
        let l:files = map(l:files, 'substitute(v:val, b:vit_root_dir."/", "", "")')
        return l:files
    elseif len(split(a:cmd_line)) <= 2
        if a:arg_lead ==? ''
            return s:vit_commands
        else
            return filter(s:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}

function! vit#config#git(...) " {{{
    if exists("b:vit")
        if a:0 > 0
            if a:1 ==# "diff"
                if a:0 < 2
                    let l:rev = vit#utils#getUserInput('Commit, tag or branch: ')
                else
                    let l:rev = a:2
                endif
                call vit#windows#Diff(b:vit.path.relative, l:rev)
            elseif a:1 ==# "blame"
                call vit#windows#Blame(b:vit.path.relative)
            elseif a:1 ==# "log" || a:1 ==# "lg"
                call vit#windows#Log(b:vit.path.relative, a:0 == 2 && a:2 == "--all" ? a:2 : "")
            elseif a:1 ==# "show"
                call vit#windows#ShowWindow(a:2)
            elseif a:1 ==# "status" || a:1 ==# "st"
                call vit#windows#Status()
            elseif a:1 ==# "add"
                call vit#commands#Add(b:vit.path.relative)
            elseif a:1 ==# "commit"
                call vit#commands#Commit(join(a:000[1:], ' '))
            elseif a:1 ==# "reset"
                call vit#commands#Reset(" -- ".b:vit.path.relative)
            elseif a:1 ==# "checkout" || a:1 ==# "co"
                call vit#commands#CheckoutCurrentFile("HEAD")
            elseif a:1 ==# "stash"
                if a:0 == 2 && a:2 == "view"
                    call vit#commands#StashViewer()
                else
                    call vit#commands#Stash(join(a:000[1:], ' '))
                endif
            elseif a:1 ==# "mv"
                call vit#commands#Move(a:000[1])
            elseif a:1 ==# "rm"
                call vit#commands#Remove()
            elseif a:1 ==# "revert"
                if a:0 < 2
                    let l:rev = vit#utils#getUserInput('Revision to revert to: ')
                else
                    let l:rev = a:2
                endif
                call vit#commands#RevertFile(l:rev, b:vit.path.relative)
            elseif a:1 ==# "k"
                let l:vit = b:vit
                tabnew
                let b:vit = l:vit
                let t:vit_log_k=1
                call vit#config#git("log", a:0 == 2 ? a:2 : "")
                call vit#config#git("status")
                wincmd t
            else
                echohl WarningMsg
                echomsg "Unrecognized command. See :help vit"
                echohl None
            endif
        else
            call vit#windows#Status()
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

function! s:GetRepoInfo(file) " {{{
    let l:reffile_dir = fnamemodify(a:file, ":p:h")

    let l:dirs = split(system("cd ".l:reffile_dir."; git rev-parse --show-toplevel --git-dir 2>/dev/null"), "\n")
    if v:shell_error != 0 || len(l:dirs) < 2
        return ""
    endif
    if !exists("g:vit_repos") || !has_key(g:vit_repos, l:dirs[0])
        if !exists("g:vit_repos")
            let g:vit_repos = {}
        endif

        call map(l:dirs, 'v:val[0] != "/" ? "'.l:reffile_dir.'/".v:val : v:val') " TODO: is this still necessary?

        let l:repo = {}
        let l:repo["worktree"] = l:dirs[0]
        let l:repo["gitdir"]   = l:dirs[1]

        function! l:repo.branch() dict
            let l:file = readfile(self.gitdir."/HEAD")
            return substitute(l:file[0], 'ref: refs/heads/', '', '')
        endfunction

        let g:vit_repos[l:dirs[0]] = l:repo
    endif
    return l:dirs[0]
endfunction " }}}

function! vit#config#buffer(file) " {{{
    let l:repo_key = s:GetRepoInfo(a:file)

    if len(l:repo_key) > 0
        if !exists("b:vit")
            let b:vit = {}
        endif
        let b:vit["repo"] = g:vit_repos[l:repo_key]

        "" Vit window numbers placeholder
        let b:vit["windows"] = { "log": -1, "show": -1, "blame": -1, "status": -1, "diff": -1 }

        "" Functions " {{{
        function! b:vit.revision() dict
            return self.execute("--no-pager log --no-color -n 1 --pretty=format:%H -- ".self.paths.absolute)
        endfunction

        function! b:vit.status() dict
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
        endfunction

        function! b:vit.execute(args) dict
            if strlen(a:args) > 0
                " echom "git --git-dir=".self.repo.gitdir." --work-tree=".self.repo.worktree." ".a:args
                return system("git --git-dir=".self.repo.gitdir." --work-tree=".self.repo.worktree." ".a:args)
            endif
        endfunction

        function! b:vit.winnr() dict "
            return bufwinnr(self.bufnr)
        endfunction
        " }}}

        "" File paths
        let b:vit["reffile"]  = a:file
        let b:vit["path"] = {}
        let b:vit.path["relative"] = substitute(substitute(fnamemodify(b:vit.reffile, ":p"), b:vit.repo.worktree."/", '', ''), '/$', '', '')
        let b:vit.path["absolute"] = fnamemodify(b:vit.reffile, ":p")

        let b:vit["bufnr"] = bufnr(b:vit.reffile)

        "" Command
        command! -bar -buffer -complete=customlist,vit#config#gitcompletion -nargs=* Git :call vit#config#git(<f-args>)

        "" Special features
        if !exists("g:vit_gutter_disable")
            call vit#gutter#config()
        endif
    endif
endfunction
" }}}
