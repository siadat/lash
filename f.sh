#!/usr/bin/env bash -e
Height=`tput lines`

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB="${ROOT}/lib"

wm_flag=$1
debug_flag=$2

if [ -z "$debug_flag" ]; then
  debug=false
else
  debug=true
fi

if [ -z "$wm_flag" ]; then
  wm_flag='bash'
fi

if [ -e "$LIB/colors.sh" ]; then
  source "$LIB/colors.sh"
else
  read -p "> Could not find $LIB/colors.sh"
  exit 1
fi

if [ -e "$LIB/wm/$wm_flag.sh" ]; then
  source "$LIB/wm/$wm_flag.sh"
else
  read -p "> Could not find $LIB/wm/$wm_flag.sh"
  exit 1
fi

if [ -e "$LIB/utils.sh" ]; then
  source "$LIB/utils.sh"
else
  read -p "> Could not find $LIB/utils.sh"
  exit 1
fi


if [ $(( $( ps | grep -wv $PID | grep "$0" | wc -l ) )) -gt 2 ]; then
  read -p "> Already running?"
  exit 1
fi

init

mode_selected=false
redraw=false

while true; do

  if $redraw || $mode_counter > 0 || $mode_selected || [ "$saved_query" != "$query" -o "$saved_cursor" != "$cursor" ]; then
    tick "$query" $mode_selected $mode_count
    saved_query="$query"
    saved_cursor="$cursor"
  fi

  mode_count=
  mode_selected=false
  IFS= read -s -n 1 c
  code=`printf '%d' "'$c'"`

  if [ "$code" = "127" ]; then # Backspace
    query=${query%?}

  elif [ "$code" = "39" ]; then # Enter
    mode_selected=true

  elif [ "$code" = "9" ]; then # Tab
    mode_count='+'

  elif [ "$code" = "27" ]; then # Escape
    code2=`read_char`

    if [ $code2 = 27 ]; then # Escape, again
      quit 0
    fi

    code3=`read_char`

    if [ "$code $code2 $code3" = "27 91 66" ]; then # Down
      nbr_of_matches=`echo "$matches" |wc -w`
      cursor=$(( cursor + 2 > nbr_of_matches ? nbr_of_matches - 1 : cursor + 1 ))
      cursor=$(( cursor + 3 > Height ? Height - 2 : cursor ))

    elif [ "$code $code2 $code3" = "27 91 65" ]; then # Up
      cursor=$(( cursor > 0 ? cursor - 1 : 0 ))

    elif [ "$code $code2 $code3" = "27 91 90" ]; then # Shift-Tab
      mode_count='-'

    else
      quit 0

    fi

  else
    query="${query}${c}"
    cursor=0

  fi
done
