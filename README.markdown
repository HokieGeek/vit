Vit
===
![Vit Logo](http://i.imgur.com/H2O7Sqd.png)

What became of the little helper functions I made that would tie Git into Vim. Now they're all grown up and needed to move out into their own plugin.

Vit integrates git into vim by providing a number of interactive windows that allow the user to view git information about the file they are currently looking at as well as modify that file's git status.

## Features

### Commands

Only one command is provided: `Git`

### Interactive windows
![](http://i.imgur.com/ne6BgPk.gif)

### vit
![](http://i.imgur.com/ITQCVBk.png)

### Stash viewer
![](http://i.imgur.com/vbPd1Vt.png)

## Would you like to know more?
You can view the manual by typing `:help vit` or going to [doc/vit.txt](doc/vit.txt).

## Installation

I recommend installing [pathogen.vim](https://github.com/tpope/vim-pathogen) and then executing the following steps in a shell:

    cd ~/.vim/bundle
    git clone git://github.com/HokieGeek/vit.git