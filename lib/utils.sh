#!/usr/bin/env bash -e
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
debug=false
Width=`tput co`
Height=`tput li`
SEARCH_PANES=true
COMMAND_FILE="$ROOT/commands.list"
PID=$$
declare -a command_buffs
line_counter=0
saved_query=
saved_mode=
same=
COLOR=1
try_other=false
curr_mode=0
prompt_color="$Yellow"
#declare -A escaped_queries
#if [ -n "${escaped_queries["q$query"]}" ]; then
#  q="${escaped_queries["q$query"]}"
#else
#  q=$( prepare_q "$query" )
#  escaped_queries["q$query"]="${q}"
#fi

function read_char {
  read -s -n 1 c
  printf '%d' "'$c'"
}

function init {
  if ! $debug; then
    stty -echo
    tput clear
    tput civis
  fi
  matches=
  cursor=0
}

function clear_end_of_screen {
  if $debug; then
    echo
  else
    tput cd || tput ed || true
  fi
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

function lecho {
  if $debug; then
    echo -e "$1"
  else
    if [ $line_counter -lt $(( Height - 1 )) ]; then
      echo -en "$1"
      tput el
      echo
    fi
    line_counter=$(( line_counter + 1 ))
  fi
}

function prepare_q {
  q=$( echo "$1" |sed -e 's/\(.\)/.*\1/g' )
  echo "${q:2}"
}

function tick {
  if ! $debug; then
    tput cup 0 0
  fi

  query=${1,,}
  selected=$2
  mode_count=$3
  counter=0

  if [ -z "$curr_sess" -o -z "$curr_win" -o -z "$all_windows" -o -z "$nbr_of_windows" ]; then
    curr_sess=`wm_current_session_address`
    curr_win=`wm_current_window_address`
    all_windows=$( wm_list_windows $curr_sess )
    nbr_of_windows=$( echo "$all_windows" |wc -l )
  fi

  if [ "$mode_count" = "+" ]; then
    curr_mode=$(( (curr_mode + 1) % 4 ))
  elif [ "$mode_count" = "-" ]; then
    curr_mode=$(( (curr_mode - 1) % 4 ))
    curr_mode=$(( (curr_mode < 0) ? (4 + curr_mode) : curr_mode ))
  fi

  if [ -z "$same" ]; then
    same=false
    matches=
  elif [ "$saved_query" = "$query" ] && [ "$saved_mode" = "$curr_mode" ] ; then
    same=true
  else
    matches=
    same=false
  fi

  saved_query="$query"
  saved_mode="$curr_mode"


  if [ $nbr_of_windows -eq 1 -a $curr_mode -eq 0 ]; then
    curr_mode=1
  #elif $try_other && [ -z "$query" -a $curr_mode -eq 1 ]; then
  #  try_other=false
  #  curr_mode=0
  fi

  if ! $same && [ $curr_mode = 0 ]; then
    prompt="${prompt_color}find >>> ${Color_Off}"
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
          for line in `wm_list_panes $curr_sess:$window_index`; do
            pane_index=${line%:*}
            pane_address=$window_address.$pane_index

            if $SEARCH_PANES; then
              buff="`wm_pane_content $pane_address`"
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
    if [ ${#matches} -eq 0 ]; then
      curr_mode=1
      try_other=true
    else
      try_other=false
    fi
  fi

  if ! $same && [ $curr_mode -eq 1 ] ; then
    i=0

    if [ ${#command_buffs} -eq 0 ]; then
      while read line; do
        if [ -n "$( echo "$line" | sed -e 's/\s*#.*//g' | sed -e 's/^ *//g' )" ]; then
          command_buffs[$i]="$line"
          i=$(( i + 1 ))
        fi
      done < "$COMMAND_FILE"
    fi

    prompt="${prompt_color}run command >>> ${Color_Off}"

    for _win_counter in "${!command_buffs[@]}"; do
      line=${command_buffs[_win_counter]}
      q=$( prepare_q "$query" )
      name=${line%:*}
      cmd=${line#*:}
      matchness=0

      q=$( prepare_q "$query" )
      g1=$( echo "$name" |grep -oPi "$q" || true )
      if [[ $cmd =~ $q ]]; then g2="m"; else g2=""; fi

      matchness=$(( ${#g1} * 10000 + ${#g2} ))

      if [ $matchness -gt 0 -o "$q" = "" ]; then
        window_address=$_win_counter
        window_index=' '
        matches="$matches $matchness|$window_address|dummypane|$_win_counter|$window_index"
      fi
    done <<< "$matches"
  fi

  if ! $same && [ $curr_mode = 2 ]; then
    prompt="${prompt_color}new window >>> ${Color_Off}"
  fi

  if ! $same && [ $curr_mode = 3 ]; then
    prompt="${prompt_color}rename this window >>> ${Color_Off}"
  fi

  if $selected && [ $curr_mode = 2 ] ; then
    wm_new_window "$query"
    quit 0
  elif $selected && [ $curr_mode = 3 ] ; then
    wm_rename_window "$curr_win" "$query"
    quit 0
  fi

  line="${prompt}${query}_"

  lecho "$line"

  if [ -n "$query" ] ; then
    readarray -t sorted < <(for a in $matches; do echo "$a"; done | sort -rn )
  else
    readarray -t sorted < <(for a in $matches; do echo "$a"; done )
  fi

  for counter in "${!sorted[@]}"; do
    if [ $counter -gt $(( Height - 3 )) ] ; then
      continue
    fi
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

    if [ $curr_mode  = 0 ]; then
      window_name=${window_names[win_counter]}
      len=$(( ${#buffs[win_counter]} ))
      snippet_len=$(( $len > 50 ? 50 : $len ))
      snippet=${buffs[win_counter]:$len - $snippet_len}
    elif [ $curr_mode = 1 ]; then
      line="${command_buffs[win_counter]}"
      window_name=${line%:*}
      snippet=" \$${line#*:}"
      # len=$(( ${#buffs[win_counter]} ))
      # snippet_len=$(( $len > 50 ? 50 : $len ))
      # snippet=${buffs[win_counter]:$len - $snippet_len}
    fi

    $debug && debug_msg=" (debug: ${matchness}) "
    if [[ $COLOR = 2 ]]; then
      q=$( prepare_q "$query" )
      line="${color}${caret}"`echo -e "${debug_msg}${window_index}${window_name}" | sed -e "s/\($q\)/$Yellow\1$Color_Off${color}/g" || true`"${Color_Off}"
    elif [[ $COLOR = 1 ]]; then
      line="${color}${caret}${debug_msg}${window_index}${window_name}${Color_Off}"
    else
      line="${caret}${debug_msg}${window_index}${window_name}"
    fi

    if [ $curr_mode = 0 ]; then

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
      if [[ $COLOR = 2 ]]; then
        line+=`echo -e "$snippet" | sed -e "s/\($q\)/$Yellow\1$Color_Off/g"`
      else
        line+="$snippet"
      fi
    fi

    lecho "$line"

    if $selected; then
      if [ "$counter" = "$cursor" ]; then
        if [ $curr_mode  = 0 ]; then
          wm_select_window $window_address
          quit 0
        elif [ $curr_mode  = 1 ]; then
          line="${command_buffs[win_counter]}"
          name=${line%:*}
          cmd=$( echo ${line#*:} | sed -e 's/^ *//g' || true )
          wm_new_window "$name" "$cmd"
          quit 0
        fi
      fi
    fi
  done
  line_counter=0
  clear_end_of_screen
}
