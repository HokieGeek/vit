Vit
===

What became of the little helper functions I made that would tie Git into Vim. Now they're all grown up and needed to move out into their own plugin.

Vit integrates git into vim by providing a number of interactive windows that allow the user to view git information about the file they are currently looking at as well as modify that file's git status.

## Features

### Commands

Only one command is provided: `Git`

### Interactive windows
![](http://i.imgur.com/ne6BgPk.gif)

### vitk
The vitk functionality starts vim with a gitk-like feature set allowing the user to traverse through each commit and view their contents.
![](http://i.imgur.com/ITQCVBk.png)

### Stash viewer
Similar to the vitk functionality, this provides a quick way to view the contents of the stash.
![](http://i.imgur.com/vbPd1Vt.png)

## Would you like to know more?
You can view the manual by typing `:help vit` or going to [doc/vit.txt](doc/vit.txt).

## Installation

I recommend installing [pathogen.vim](https://github.com/tpope/vim-pathogen) and then executing the following steps in a shell:

    cd ~/.vim/bundle
    git clone https://HokieGeek@gitlab.com/HokieGeek/vit.git
