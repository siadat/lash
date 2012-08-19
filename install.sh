#!/usr/bin/env bash -e
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$1" ]; then
  binding='M-Tab'
else
  binding="$1"
fi

height=10

echo "bind-key -n $binding split-window -l 10 $dir/f.sh" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
