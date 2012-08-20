#!/usr/bin/env bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Blue=`echo -e '\e[0;34m'`
On_Blue=`echo -e '\e[44m'`
Yellow=`echo -e '\e[1;32m'`
Color_Off=`echo -e '\e[0m'`
Width=`tput co`
Height=`tput li`
prompt_color="$Yellow"
SEARCH_PANES=true
COMMAND_FILE="$DIR/commands.list"
PID=$$
command_buffs=
debug=false

function read_char {
  read -s -n 1 c
  printf '%d' "'$c'"
}

function new_window {
  name="$1"
  script="$2"
  if [ -n "$name" ]; then
    tmux new-window -n "$name" "$2"
    tmux set-window-option allow-rename off
  else
    tmux new-window "$2"
  fi
}

function init {
  stty -echo
  tput clear
  tput civis
  matches=
  cursor=0
}

function ac_lines {
  query="$1"
  # given an array of lines, return the ones that match $1
  echo
}

function quit {
  stty echo
  tput cnorm
  exit $1
}

function oops {
  read -p "$1"
  quit 1
}

function cho {
  echo -en "$1"
  tput el
  echo
}

function prepare_q {
  q=$( echo "$1" |sed -e 's/\(.\)/.*\1/g' )
  echo "${q:2}"
}

function update {
  matches=
  query=${1,,}
  selected=$2
  mode_count=$3
  curr_sess=`tmux display-message -p '#S'`
  curr_pane=`tmux display-message -p '#S:#I.#P'`
  curr_win=`tmux display-message -p '#S:#I'`
  windows=`tmux list-windows -F '#{window_index}'`
  counter=0

  all_windows=$( tmux list-windows -F "#{window_index}:#{window_name}" -t $curr_sess )
  nbr_of_windows=$( echo "$all_windows" |wc -l )

  if [ $nbr_of_windows = 1 -a $mode_count = 0 ]; then
    mode_count=1
  fi

  if [ $mode_count = 3 ]; then

    if [ -z "$command_buffs" ]; then
      command_buffs=$( cat "$COMMAND_FILE" | sed -e 's/^ *//g' | grep -v '^$' || true )
    fi

    prompt="${prompt_color}commands >>> ${Color_Off}"

    _win_counter=1
    while read line ; do
      q=$( prepare_q "$query" )
      name=${line%:*}
      cmd=${line#*:}
      matchness=0

      if [[ $name =~ $q ]]; then
        matchness=$(( matchness + 1000 ))
      fi

      if [[ $cmd =~ $q ]]; then
        matchness=$(( matchness + 1 ))
      fi

      if [ $matchness -gt 0 -o "$q" = "" ]; then
        window_address=$_win_counter
        window_index=' '
        matches="$matches $matchness|$window_address|dummypane|$_win_counter|$window_index"
      fi
      _win_counter=$(( _win_counter + 1 ))
    done <<< "$matches" < <( echo "$command_buffs" )


  elif [ $mode_count = 2 ]; then
    prompt="${prompt_color}set title >>> ${Color_Off}"

  elif [ $mode_count = 1 ]; then
    prompt="${prompt_color}new window >>> ${Color_Off}"

  else
    prompt="${prompt_color}goto >>> ${Color_Off}"
    win_counter=0

    while read window_line ; do
      window_index=${window_line%:*}
      window_name=${window_line#*:}
      window_address=$curr_sess:$window_index

      if [ "$curr_win" != "$window_address" ]; then

        if [ -z "${window_names[win_counter]}" ]; then
          window_names[$win_counter]="${window_name}"
        fi

        pane_counter=0
        if [ -z "${buffs[win_counter]}" ]; then
          for pane_index in `tmux list-panes -F "#{pane_index}" -t $curr_sess:$window_index`; do
            pane_address=$window_address.$pane_index

            if $SEARCH_PANES; then
              tmux clear-history -t $pane_address
              tmux capture-pane -t $pane_address
              buff="`tmux show-buffer -b 0`"
            else
              buff=
            fi

            buffs[$win_counter]="${buffs[win_counter]} ${buff}"
            pane_counter=$(( pane_counter + 1 ))
          done

          x=$(
            echo "${buffs[win_counter]}" |tr -d '[\r\n]' |sed -e 's/  */ /g'
          )
          # To lower case
          x=${x,,} || true
          buffs[$win_counter]="x ${pane_counter} $x"
        fi

        found=
        matchness=0
        is_match=false
        g1=false
        g2=false

        if [ -z "$query" ]; then
          g1=true;
          is_match=true
        else
          q=$( prepare_q "$query" )
          g1=$( echo "$window_name" |grep -oPi "$q" || true )
          if $SEARCH_PANES; then
            g2=$( echo "${buffs[win_counter]}" |grep -oPi "$query" || true )
          else
            g2=""
          fi

          matchness=$(( ${#g1} * 10000 + ${#g2} ))
          if [ $matchness -gt 0 ]; then
            is_match=true
          fi
        fi

        if $is_match; then
          matches="$matches $matchness|$window_address|dummypane|$win_counter|$window_index"
        fi
        win_counter=$(( win_counter + 1 ))
      fi
    done <<< "$matches" < <( echo "$all_windows" )
  fi

  if $selected && [ $mode_count = 1 ] ; then
    new_window "$query"
    quit 0
  elif $selected && [ $mode_count = 2 ] ; then
    if [ -n "$query" ]; then
      tmux set-window-option -t $curr_win allow-rename off
      tmux rename-window -t $curr_win "$query"
    else
      tmux set-window-option -t $curr_win allow-rename on
    fi
    quit 0
  fi

  line="${prompt}${query}_"

  cho "$line"

  if [ -n "$query" ] ; then
    readarray -t sorted < <(for a in $matches; do echo "$a"; done | sort -rn )
  else
    # assumes that list-windows is ordered by last focus
    readarray -t sorted < <(for a in $matches; do echo "$a"; done )
  fi

  for counter in "${!sorted[@]}"; do
    IFS='|' read -a arr <<< "${sorted[counter]}"
    matchness=${arr[0]}
    window_address=${arr[1]}
    pane_address=${arr[2]}
    win_counter=${arr[3]}
    window_index=${arr[4]}
    if [ -n "$window_index" ]; then
      window_index="${window_index}:"
    fi

    if [ "$counter" = "$cursor" ]; then
      caret="- "
      color="$On_Blue"
    else
      caret="  "
      color="$Blue"
    fi

    if [ $mode_count = 0 ]; then
      window_name=${window_names[win_counter]}
      len=$(( ${#buffs[win_counter]} ))
      snippet_len=$(( $len > 50 ? 50 : $len ))
      snippet=${buffs[win_counter]:$len - $snippet_len}
    elif [ $mode_count = 3 ]; then
      line=$( echo "$command_buffs" | sed -n "${win_counter}p" )
      window_name=${line%:*}
      snippet=" \$${line#*:}"
      # len=$(( ${#buffs[win_counter]} ))
      # snippet_len=$(( $len > 50 ? 50 : $len ))
      # snippet=${buffs[win_counter]:$len - $snippet_len}
    fi

    line=
    line+="${color}"
    q=$( prepare_q "$query" )
    $debug && debug_msg=" (debug: ${matchness}) "
    line+=`echo -e "${caret}${debug_msg}${window_index}${window_name}" |sed -e "s/\($q\)/$Yellow\1$Color_Off${color}/g" || true`
    line+="${Color_Off}"

    if [ $mode_count = 0 ]; then

      if $SEARCH_PANES; then
        if [ $matchness = 0 ]; then
          line+=`echo -e " "`
        elif [ $matchness -gt 1000 ]; then
          line+=`echo -e " "`
        else
          line+=`echo -e " - pane content"`
        fi
      else
        line+=`echo -e " "`
      fi
    else
      line+=`echo -e "$snippet" | sed -e "s/\($q\)/$Yellow\1$Color_Off/g"`
    fi

    cho "$line"

    if $selected; then
      if [ "$counter" = "$cursor" ]; then
        if [ $mode_count = 0 ]; then
          tmux select-window -t $window_address
          quit 0
        elif [ $mode_count = 3 ]; then
          echo $window_address
          line=$( echo "$command_buffs" | sed -n "${window_address}p" )
          name=${line%:*}
          cmd=$( echo ${line#*:} | sed -e 's/^ *//g' || true )
          new_window "$name" "$cmd"
          #sleep 2
          #tmux send-keys "${cmd}" C-m
          quit 0
        fi
      fi
    fi
  done
  tput cd || tput ed || true
}
