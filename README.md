A __window__ and __pane__ finder for Tmux, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).  The goal is to make navigation between many Tmux windows efficient and fast.

### Installation
``` bash
    echo 'bind-key -n M-f split-window -l 10 ~/path/to/fmux/f.sh' >> ~/.tmux.conf
    tmux source-file ~/.tmux.conf
```
* Replace `~/path/to/fmux/f.sh` with the actual path to fmux.
* Replace `M-f` with anything you prefer. I suggest `M-p`.

### Usage
* Press `M-f` to start the window finder.  Press CTRL-c to close.  You could also run `f.sh` from a normal shell.
* Once fmux is open, you can press ` (backquote) to rename a window, or : (colon) to create a new window.

Tested with Bash 4.2.37, GNU Sed 4.2.1 and GNU Grep 2.5.1.

Copyrigh (c) 2012 Sina Siadat
