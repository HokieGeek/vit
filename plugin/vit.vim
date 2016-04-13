if exists("g:loaded_vit") || v:version < 700
    finish
endif
let g:loaded_vit = 1

let g:vit_commands = ["log", "add", "reset", "checkout", "diff", "blame", "commit", "status", "push", "pull", "show"]

function! vit#GitCompletion(arg_lead, cmd_line, cursor_pos) " {{{
    if a:cmd_line =~# "^Git add "
        let l:files = split(glob(b:vit_root_dir."/".a:arg_lead."*"))
        let l:files = map(l:files, 'v:val.(isdirectory(v:val)?"/":"")')
        let l:files = map(l:files, 'substitute(v:val, b:vit_root_dir."/", "", "")')
        return l:files
    elseif len(split(a:cmd_line)) <= 2
        if a:arg_lead ==? ''
            return g:vit_commands
        else
            return filter(g:vit_commands, 'v:val[0:strlen(a:arg_lead)-1] ==? a:arg_lead')
        endif
    endif
endfunction " }}}

function! Git(...) " {{{
    if exists("b:vit_git_dir")
        if a:0 > 0
            " echomsg "Git(".string(a:000).")"
            let l:command = a:1
            let l:cmd_args = join(a:000[1:], ' ')

            if l:command ==# "diff"
                if len(l:cmd_args) <= 0
                    call vit#DiffPrompt()
                else
                    call vit#Diff(l:cmd_args, "")
                endif
            elseif l:command ==# "blame"
                call vit#Blame()
            elseif l:command ==# "log" || l:command ==# "lg"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#Log(l:cmd_args)
            elseif l:command ==# "show"
                call vit#Show(l:cmd_args)
            elseif l:command ==# "status" || l:command ==# "st"
                call vit#Status()

            elseif l:command ==# "add"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                call vit#Add(l:cmd_args)
            elseif l:command ==# "commit"
                call vit#Commit(l:cmd_args)
            elseif l:command ==# "push"
                if len(l:cmd_args) <= 0
                    call vit#Push("", "")
                " elseif a:0 == 2
                    " call vit#Push(a:000[1], "")
                elseif a:0 > 2
                    call vit#Push(a:000[1], a:000[2])
                endif
            elseif l:command ==# "pull"
                echoerr "TODO"
                " if len(l:cmd_args) <= 0
                    " call vit#Pull("", "", 0)
                " else
                    " call vit#Pull(a:000[2], a:000[3], 0)
                " endif
                " call vit#GitPull("TODO", "TODO", 0)
            elseif l:command ==# "reset"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = expand("%")
                endif
                " call vit#Reset(l:cmd_args)
                call vit#ResetFilesInGitIndex("", l:cmd_args)
            elseif l:command ==# "checkout" || l:command ==# "co"
                if len(l:cmd_args) <= 0
                    let l:cmd_args = "HEAD"
                endif
                call vit#Checkout(l:cmd_args)
            else
                echohl WarningMsg
                echomsg "Unrecognized git command: ".l:command
                echohl None
            endif
        else
            call vit#Status()
        endif
    else
        echomsg "Not in a git repository"
    endif
endfunction " }}}

autocmd BufWinEnter * call vit#init() | call vit#RefreshStatus()

" vim: set foldmethod=marker formatoptions-=tc:
