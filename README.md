A __window__ and __pane__ finder for Tmux, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).  The goal is to make navigation between many Tmux windows efficient and fast, without having to remember the window number or position in tmux status line.

### Installation
``` bash
    $ echo 'bind-key -n C-` split-window -l 10 ~/path/to/fmux/f.sh' >> ~/.tmux.conf
```
And reload your config:
``` bash
    $ tmux source-file ~/.tmux.conf
```

#### Notes:
* Replace ~/path/to/fmux/f.sh with the actual path to fmux.
* Replace C-` with anything you prefer. I suggest M-p.

### Usage
* __open__: Press C-` (ctrl-backquote or your preferred binding) to start fmux
* __search__: Type any part of the window title, e.g. type `pj` to find your `project` window
* __select__: Press the RETURN key
* __rename window__: ` (backquote) to rename current window
* __new window__: `` (two backquotes) to create a new window
* __close__: CTRL-c to close fmux
* You may run `f.sh` from a normal shell

### Contributions
* Feedbacks, bug reports, and patches are highly appreciated
* Tested with Tmux 1.6+, Bash 4.2.37, GNU Sed 4.2.1, BSD Sed (2005), BSD tr (2004), GNU tr from coreutils 8.17 and GNU Grep 2.5.1 on OSX and Gentoo

Copyrigh (c) 2012 Sina Siadat
