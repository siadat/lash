#!/usr/bin/env bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e "$DIR/wm/tmux.sh" ]; then
  source "$DIR/wm/tmux.sh"
else
  read -p "Could not find $DIR/wm/tmux.sh"
  exit 1
fi

if [ -e "$DIR/utils.sh" ]; then
  source "$DIR/utils.sh"
else
  read -p "Could not find $DIR/utils.sh"
  exit 1
fi


if [ $(( $( ps | grep -wv $PID | grep "$0" | wc -l ) )) -gt 2 ]; then
  exit 1
fi

init

mode_selected=false
mode_commands=false
redraw=false
mode_count=0

while true; do

  if $redraw || $mode_counter > 0 || $mode_selected || [ "$saved_query" != "$query" -o "$saved_cursor" != "$cursor" ]; then
    tput cup 0 0
    update "$query" $mode_selected $mode_count
    saved_query="$query"
    saved_cursor="$cursor"
  fi

  mode_selected=false
  IFS= read -s -n 1 c
  code=`printf '%d' "'$c'"`

  if [ "$code" = "127" ]; then # Backspace
    query=${query%?}

  elif [ "$code" = "39" ]; then # Enter
    mode_selected=true

  elif [ "$code" = "9" ]; then # Tab
    mode_count=$(( (mode_count + 1) % 4 ))

  elif [ "$code" = "27" ]; then # Escape
    code2=`read_char`

    if [ $code2 = 27 ]; then # Escape, again
      quit 0
    fi

    code3=`read_char`

    if [ "$code $code2 $code3" = "27 91 66" ]; then # Down
      nbr_of_matches=`echo "$matches" |wc -w`
      cursor=$(( cursor < nbr_of_matches - 1 ? cursor + 1 : nbr_of_matches - 1 ))

    elif [ "$code $code2 $code3" = "27 91 65" ]; then # Up
      cursor=$(( cursor > 0 ? cursor - 1 : 0 ))

    elif [ "$code $code2 $code3" = "27 91 90" ]; then # Shift-Tab
      mode_count=$(( (mode_count - 1) % 4 ))
      mode_count=$(( (mode_count < 0) ? (4 + mode_count) : mode_count ))

    else
      quit 0

    fi

  else
    query="${query}${c}"
    cursor=0

  fi
done
