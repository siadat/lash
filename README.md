A shell launcher and window finder for Tmux, inspired by [ctrlp](https://github.com/kien/ctrlp.vim/).

![Screenshot](http://i.imgur.com/cv55F.png)

### Install
``` bash
$ ./install.sh tmux M-Tab
```

#### Notes

* The installation script appends a keyboard binding to your `~/.tmux.conf`
* Change M-Tab to your prefered key binding
* How to enable Meta key in OSX Terminal: `Settings > Keyboard > Use option as meta key`
* How to enable Meta key in iTerm: `Your profile > Keys > Left option key acts as __+Esc__`

### Usage
Press Meta-Tab to open. Press Tab to cycle through modes (search, run, new, and rename).

### Contribute
* Feedbacks, bug reports, and patches are highly appreciated
* Tested with Tmux 1.6+, Bash 4.2 and 3.2, GNU Sed 4.2.1, BSD Sed (2005), BSD tr (2004), GNU tr from coreutils 8.17 and GNU Grep 2.5.1 on OSX, Gentoo and RedHat 5.
