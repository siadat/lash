# meta-p

A __window__ and __pane__ finder for Tmux, inspired by ([ctrlp](https://github.com/kien/ctrlp.vim/)).  The goal is to make navigation between many Tmux windows more efficient.

### Usage

Append this line to your `~/.tmux.conf`:

```
    bind-key -n M-p split-window -l 10 ~/.tmux/meta-t
```

You could also run meta-p from any shell:

``` bash
    $ ~/.tmux/meta-t
```

Replace `M-p` with anything you would like. If you are on a Mac and you want to use the meta key make sure you enable "Use option as meta key" in Termianl preferences.

Tested with Bash 4.2.37, GNU Sed 4.2.1 and GNU Grep 2.5.1.

Copyrigh (c) 2012 Sina Siadat
