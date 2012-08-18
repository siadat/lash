#!/usr/bin/env bash -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e "$dir/utils.sh" ]; then
  source "$dir/utils.sh"
else
  echo "Could not find $dir/utils.sh"
  exit 1
fi

init

mode_rename=false
mode_selected=false

while true; do

  if $mode_rename || $mode_selected || [ "$saved_query" != "$query" -o "$saved_cursor" != "$cursor" ]; then
    clear
    update "$query" $mode_selected $mode_rename
    saved_query="$query"
    saved_cursor="$cursor"
  fi

  mode_selected=false
  #mode_rename=$( false || mode_rename )
  read -s -n 1 c
  code=`printf '%d' "'$c'"`

  if [ "$code" = "127" ]; then
    query=${query%?}

  elif [ "$code" = "39" ]; then
    mode_selected=true

  elif [ "$code" = "96" ]; then
    mode_rename=true

  elif [ "$code" = "27" ]; then
    code2=`read_char`
    code3=`read_char`
    if [ "$code $code2 $code3" = "27 91 66" ]; then
      # Down
      nbr_of_matches=`echo "$matches" |wc -w`
      cursor=$(( cursor < nbr_of_matches - 1 ? cursor + 1 : nbr_of_matches - 1 ))
    elif [ "$code $code2 $code3" = "27 91 65" ]; then
      # Up
      cursor=$(( cursor > 0 ? cursor - 1 : 0 ))
    else
      quit 0
    fi

  else
    query="${query}${c}"
    cursor=0

  fi
done
