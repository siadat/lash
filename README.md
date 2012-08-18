A __window__ and __pane__ finder for Tmux, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).  The goal is to make navigation between many Tmux windows efficient and fast.

### Installation
``` bash
    $ echo 'bind-key -n M-p split-window -l 10 ~/path/to/fmux/f.sh' >> ~/.tmux.conf
```
And reload your config:
``` bash
    $ tmux source-file ~/.tmux.conf
```

#### Notes:
* Replace ~/path/to/fmux/f.sh with the actual path to fmux.
* Replace `M-p` with anything you prefer.

### Usage
* Press `M-p` (meta-p, alt-p or your preferred binding) to start fmux
* Start typing part of the window title or current content of the pane
* Up/Down arrow keys to navigate the list
* ` (backquote) to rename current window
* `` (two backquotes) to create a new window
* CTRL-c to close fmux
* You may run `f.sh` from a normal shell

### Contributions
* All sorts of feedback, contribution and bug reports are highly appreciated
* Tested with Tmux 1.6+, Bash 4.2.37, GNU Sed 4.2.1 and GNU Grep 2.5.1 on OSX and Gentoo

Copyrigh (c) 2012 Sina Siadat
