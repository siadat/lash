A shell launcher and window finder for Tmux, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).

![Screenshot](http://i.imgur.com/cv55F.png)

### Install
``` bash
$ ./install.sh tmux M-Tab
```

#### Notes

* The installation script appends a keyboard binding to your `~/.tmux.conf`
* Change M-Tab to your prefered key binding
* __How to enable Meta key in OSX Terminal__: `Settings > Keyboard > Use option as meta key`
* __How to enable Meta key in iTerm__: `Your profile > Keys > Left option key acts as __+Esc__`

### Usage
* __open__: Press Meta-Tab (or your preferred binding)
* __search__: Type any part of the window title, e.g. type `pj` to find your `project` window
* __select__: Press the RETURN key
* __new window__: Press Tab to create a new window
* __command mode__: Press Tab-Tab to go to command mode
* __rename window__: Press Tab-Tab-Tab to rename current window
* __close__: CTRL-c or double-ESC to close

### Contribute
* Feedbacks, bug reports, and patches are highly appreciated
* Tested with Tmux 1.6+, Bash 4.2 and 3.2, GNU Sed 4.2.1, BSD Sed (2005), BSD tr (2004), GNU tr from coreutils 8.17 and GNU Grep 2.5.1 on OSX, Gentoo and RedHat 5.
