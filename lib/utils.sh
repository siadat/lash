#!/usr/bin/env bash -e
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
Width=`tput co`
Height=`tput li`
prompt_color="$Yellow"
SEARCH_PANES=true
COMMAND_FILE="$ROOT/commands.list"
PID=$$
declare -a command_buffs
debug=false
line_counter=0
saved_query=
saved_mode=
same=
COLOR=1
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
  stty -echo
  tput clear
  tput civis
  matches=
  cursor=0
}

function clear_end_of_screen {
  tput cd || tput ed || true
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
  if [ $line_counter -lt $(( Height - 1 )) ]; then
    echo -en "$1"
    tput el
    echo
  fi
  line_counter=$(( line_counter + 1 ))
}

function prepare_q {
  q=$( echo "$1" |sed -e 's/\(.\)/.*\1/g' )
  echo "${q:2}"
}

function tick {
  query=${1,,}
  selected=$2
  mode_count=$3
  curr_sess=`wm_current_session_address`
  curr_win=`wm_current_window_address`
  counter=0

  if [ -z "$same" ]; then
    same=false
    matches=
  elif [ "$saved_query" = "$query" ] && [ "$saved_mode" = "$mode_count" ] ; then
    same=true
  else
    matches=
    same=false
  fi
  saved_query="$query"
  saved_mode="$mode_count"

  all_windows=$( wm_list_windows $curr_sess )
  nbr_of_windows=$( echo "$all_windows" |wc -l )

  if [ $nbr_of_windows = 1 -a $mode_count = 0 ]; then
    mode_count=1
  fi

  if $same; then
    true
  elif [ $mode_count = 1 ]; then

    i=1
    while read line; do
      if [ -n "$( echo "$line" | sed -e 's/\s*#.*//g' | sed -e 's/^ *//g' )" ]; then
        command_buffs[$i]="$line"
        i=$(( i + 1 ))
      fi
    done < "$COMMAND_FILE"

    #if [ -z "$command_buffs" ]; then
    #  command_buffs=$( cat "$COMMAND_FILE" | grep -v '\s*#' | sed -e 's/^ *//g' | grep -v '^$' || true )
    #fi

    prompt="${prompt_color}run >>> ${Color_Off}"

    _win_counter=1
    for line in "${command_buffs[@]}"; do
    # while read line ; do
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
    done <<< "$matches"

  elif [ $mode_count = 3 ]; then
    prompt="${prompt_color}rename this window >>> ${Color_Off}"

  elif [ $mode_count = 2 ]; then
    prompt="${prompt_color}new window >>> ${Color_Off}"

  else
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
  fi

  if $selected && [ $mode_count = 2 ] ; then
    wm_new_window "$query"
    quit 0
  elif $selected && [ $mode_count = 3 ] ; then
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

    if [ $mode_count = 0 ]; then
      window_name=${window_names[win_counter]}
      len=$(( ${#buffs[win_counter]} ))
      snippet_len=$(( $len > 50 ? 50 : $len ))
      snippet=${buffs[win_counter]:$len - $snippet_len}
    elif [ $mode_count = 1 ]; then
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
      if [[ $COLOR = 2 ]]; then
        line+=`echo -e "$snippet" | sed -e "s/\($q\)/$Yellow\1$Color_Off/g"`
      else
        line+="$snippet"
      fi
    fi

    lecho "$line"

    if $selected; then
      if [ "$counter" = "$cursor" ]; then
        if [ $mode_count = 0 ]; then
          wm_select_window $window_address
          quit 0
        elif [ $mode_count = 1 ]; then
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
