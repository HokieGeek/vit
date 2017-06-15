if exists("g:autoloaded_vit_statusline") || v:version < 700
    finish
endif
let g:autoloaded_vit_statusline = 1

function! s:AssignHL(name,bg,fg,weight) " {{{
    let l:gui = "guibg=".a:bg[0]." guifg=".a:fg[0]
    let l:term = "ctermbg=".a:bg[1]." ctermfg=".a:fg[1]." cterm=".a:weight
    execute "highlight SL_HL_".a:name." ".l:gui." ".l:term
endfunction " }}}

function! s:StatuslineHighlights() " {{{
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
endfunction " }}}

function! vit#statusline#get() " {{{
    let l:status=""
    if exists("b:vit")
        if !exists("b:vit_defined_statusline_highlights")
            call s:StatuslineHighlights()
        endif
        let l:branch = b:vit.repo.branch()
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
