#!/usr/bin/env bash -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $dir/utils.sh

nbr_of_windows=
matches=
cursor=0

function update {
  matches=
  query=$1
  selected=$2
  curr_sess=`tmux display-message -p '#S'`
  curr_pane=`tmux display-message -p '#S:#I.#P'`
  curr_win=`tmux display-message -p '#S:#I'`
  windows=`tmux list-windows -F '#{window_index}'`
  counter=0
  win_counter=0

  all_windows=$( tmux list-windows -F "#{window_index}:#{window_name}" -t $curr_sess )
  nbr_of_windows=$( echo "$all_windows" |wc -l )

  if [ $(( $nbr_of_windows )) = 1 ]; then
    echo "$nbr_of_windows" 
    quit 0
  fi

  while read window_line ; do
    window_index=${window_line%:*}
    window_name=${window_line#*:}
    window_address=$curr_sess:$window_index
    
    if [ "$curr_win" != "$window_address" ]; then

      if [ -z "${window_names[win_counter]}" ]; then
        window_names[$win_counter]="${window_name}"
      fi

      if [ $(( $nbr_of_windows )) = 2 ]; then
        tmux select-window -t $window_address
        tmux select-pane -t $pane_address
        quit 0
      fi

      #echo "`tmux list-panes -F "#{pane_index}" -t $curr_sess:$window_index`"
      pane_counter=0
      if [ -z "${buffs[win_counter]}" ]; then
        for pane_index in `tmux list-panes -F "#{pane_index}" -t $curr_sess:$window_index`; do
          pane_address=$window_address.$pane_index
          tmux clear-history -t $pane_address
          tmux capture-pane -t $pane_address
          buff="`tmux show-buffer -b 0`"
          buffs[$win_counter]="${buffs[win_counter]} ${buff}"
          pane_counter=$(( pane_counter + 1 ))
        done

        x=$(
          echo "${buffs[win_counter]}" |sed -e ':a;N;$!ba;s/\n/ /g'  |sed -e 's/  */ /g'
        )
        #x=$(
        #  for word in ${buffs[win_counter]}; do
        #    echo "$word"
        #  done |sed -e 's/[^a-z0-9 ]\+/ /ig' |grep -Pvw '\w{1,2}' |sort |uniq -c |gsort -rn |sed 's/[ 0-9]*//g' |grep -v '^$' |sed ':a;N;$!ba;s/\n/ /g'
        #)

        buffs[$win_counter]="(${pane_counter}p) $x"
      fi

      found=
      matchness=0
      is_match=
      g1=false
      g2=false

      if [ -z "$query" ];
        then g1=true;
        is_match=true
      else
        if [ "`echo "$window_name" |grep -oPi "$query"`" ]; then g1=true; fi
        if [ "`echo "${buffs[win_counter]}" |grep -oPi "$query"`" ]; then g2=true; fi

        if $g1; then
          matchness=$(( matchness + 1000 ))
          is_match=true
        fi

        if $g2; then
          matchness=$(( matchness + 1 ))
          is_match=true
        fi
      fi

      if [ -n "$is_match" ]; then
        matches="$matches $matchness|$window_address|dummypane|$win_counter|$window_index"
      fi
      win_counter=$(( win_counter + 1 ))
    fi
  done <<< "$matches" < <( echo "$all_windows" )

  echo ">>> ${query}_"
  readarray -t sorted < <(for a in $matches; do echo "$a"; done | sort -rn)
  for counter in "${!sorted[@]}"; do
    IFS='|' read -a arr <<< "${sorted[counter]}"
    matchness=${arr[0]}
    window_address=${arr[1]}
    pane_address=${arr[2]}
    win_counter=${arr[3]}
    window_index=${arr[4]}
    window_name=${window_names[win_counter]}

    if [ "$counter" = "$cursor" ]; then
      caret="> "
      color="$On_Blue"
    else
      caret="  "
      color="$Blue"
    fi

    len=$(( ${#buffs[win_counter]} ))
    snippet_len=$(( $len > 50 ? 50 : $len ))
    snippet=${buffs[win_counter]:$len - $snippet_len}

    echo -ne "${color}"
    echo -ne "${caret}${window_index}:${window_name}" |sed -e "s/\($query\)/$Yellow\1$Color_Off${color}/gi"
    echo -ne "${Color_Off}"
    echo -e  " $snippet" |sed -e "s/\($query\)/$Yellow\1$Color_Off/gi"

    if [ -n "$selected" ]; then
      if [ "$counter" = "$cursor" ]; then
        tmux select-window -t $window_address
        # tmux select-pane -t $pane_address
        quit 0
      fi
    fi
  done
}

stty -echo
tput civis
while [ -z '' ]; do

  if [ -n "$selected" -o "$saved_query" != "$query" -o "$saved_cursor" != "$cursor" ]; then
    clear
    #echo "$selected | $cursor, $saved_cursor, $query, $saved_query"
    update "$query" "$selected"
    saved_query="$query"
    saved_cursor="$cursor"
  fi

  selected=
  read -s -n 1 c
  code=`printf '%d' "'$c'"`

  if [ "$code" = "127" ]; then
    query=${query%?}
  elif [ "$code" = "39" ]; then
    selected=true
  elif [ "$code" = "27" ]; then
    code2=`read_char`
    code3=`read_char`
    if [ "$code $code2 $code3" = "27 91 66" ]; then
      # Down key
      nbr_of_matches=`echo "$matches" |wc -w`
      cursor=$(( cursor < nbr_of_matches - 1 ? cursor + 1 : nbr_of_matches - 1 ))
    elif [ "$code $code2 $code3" = "27 91 65" ]; then
      # Up key
      cursor=$(( cursor > 0 ? cursor - 1 : 0 ))
    else
      quit 0
    fi
  else
    query="${query}${c}"
    cursor=0
  fi
done
