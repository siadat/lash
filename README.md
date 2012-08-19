A __window__ and __pane__ finder for complex Tmux sessions, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).

![Screenshot](http://i.imgur.com/cv55F.png)

### Install
``` bash
    $ ./install.sh 'M-Tab'
```
* Change M-Tab to whatever key binding you prefer.
* The install script adds a line to your `~/.tmux.conf`.

### Usage
* __open__: Press M-Tab (or your preferred binding) to start fmux
* __search__: Type any part of the window title, e.g. type `pj` to find your `project` window
* __select__: Press the RETURN key
* __new window__: ` (two backquotes) to create a new window
* __rename window__: `` (backquote) to rename current window
* __close__: CTRL-c to close fmux
* You may run `f.sh` from a normal shell

### Contribute
* Feedbacks, bug reports, and patches are highly appreciated
* Tested with Tmux 1.6+, Bash 4.2.37, GNU Sed 4.2.1, BSD Sed (2005), BSD tr (2004), GNU tr from coreutils 8.17 and GNU Grep 2.5.1 on OSX and Gentoo

Copyrigh (c) 2012 Sina Siadat
