#!/usr/bin/env bash -e
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
height=10

if [ -z "$1" ]; then
  wm='tmux'
else
  wm="$1"
fi

if [ -z "$2" ]; then
  binding='M-Tab'
else
  binding="$2"
fi

if [ "$wm" = "tmux" ]; then
  echo "bind-key -n $binding split-window -l 10 '$dir/f.sh ${wm}'" >> ~/.tmux.conf
  tmux source-file ~/.tmux.conf
else
  echo "Only tmux is supported at the moment."
  echo "But you could extend the supported window managers. To do that you would"
  echo "need to create a file like ./lib/tmux.sh for your window manager."
  echo "Send me a pull request and I will merge it upstream. Thank you!"
fi

