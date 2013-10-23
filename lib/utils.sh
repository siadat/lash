#!/usr/bin/env bash -e
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
Width=`tput cols`
Height=`tput lines`
SEARCH_PANES=false
SEARCH_HISTORY=false
COMMAND_FILE1="$ROOT/lashrc"
COMMAND_FILE2=~/.lashrc
PID=$$

MODE_FIND=0
MODE_NEW=1
MODE_RENAME=2
MODE_RUN=3
MODE_COUNT=4

declare -a command_buffs
line_counter=0
saved_query=
saved_mode=
same=
if [ -t 1 ]; then
  COLOR=2
  prompt_color="$Yellow"
else
  COLOR=0
  prompt_color=
  Color_Off=
fi

curr_mode=$MODE_FIND
do_not_clear=false
tput sc

function read_char {
  read -s -n 1 c
  printf '%d' "'$c'"
}

function init {
  if ! $debug; then
    stty -echo
    if ! $do_not_clear; then
      tput clear
      tput civis
    fi
  fi
  matches=
  cursor=0
}

function clear_end_of_screen {
  if $debug; then
    echo
  else
    tput cd 2> /dev/null || tput ed
  fi
}

function ac_lines {
  query="$1"
  # given an array of lines, return the ones that match $1
  echo
}

function return_to_normal {
  tput rc
  clear_end_of_screen
  stty echo
  tput cnorm
}

function quit {
  echo "quit($1) at $(date)" >> /tmp/sina.lash.log
  return_to_normal
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
    if [ $line_counter -lt $(( Height - 0 )) ]; then
      echo -en "$1"
      tput el
    fi
    if [ $line_counter -lt $(( Height - 1 )) ]; then
      echo
    fi
    line_counter=$(( line_counter + 1 ))
  fi
}

function prepare_q {
  # TODO escape regular expression
  q="${1//+/}"
  q="${q//!/}"
  q=$( echo "$q" |sed -e 's/\(.\)/[^\1]*\1/g' )
  echo "${q:5}"
}

function tick {
  if ! $debug; then
    if $do_not_clear; then
      tput rc
    else
      tput cup 0 0
    fi
  fi


  if [ ${BASH_VERSINFO[0]} -gt 3 ]; then
    query=${1,,}
  else
    query=$1
  fi
  selected=$2
  mode_count=$3
  counter=0

  if [ -z "$curr_sess" -o -z "$curr_win" -o -z "$all_windows" -o -z "$nbr_of_windows" ]; then
    curr_win=`wm_current_window_address`
    curr_sess=${curr_win%:*}
    #curr_sess=`wm_current_session_address`
    all_windows=$( wm_list_windows $curr_sess )
    nbr_of_windows=$( echo "$all_windows" |wc -l )
  fi

  if [ "$mode_count" = "+" ]; then
    curr_mode=$(( (curr_mode + 1) % MODE_COUNT ))
    cursor=0
  elif [ "$mode_count" = "-" ]; then
    curr_mode=$(( (curr_mode - 1) % MODE_COUNT ))
    curr_mode=$(( (curr_mode < 0) ? (MODE_COUNT + curr_mode) : curr_mode ))
    cursor=0
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

  if [ $nbr_of_windows -eq 1 -a $curr_mode -eq $MODE_FIND ]; then
    curr_mode=$MODE_NEW
    cursor=0
  fi

  if ! $same && [ $curr_mode = $MODE_FIND ]; then
    source "$LIB/find.sh"
    find_window
  fi

  if ! $same && [ $curr_mode -eq $MODE_RUN ] ; then
    source "$LIB/run.sh"
    run_command
  fi

  if ! $same && [ $curr_mode = $MODE_NEW ]; then
    prompt="${prompt_color}new:${Color_Off} "
  fi

  if ! $same && [ $curr_mode = $MODE_RENAME ]; then
    prompt="${prompt_color}rename:${Color_Off} "
  fi

  if $selected && [ $curr_mode = $MODE_NEW ] ; then
    wm_new_window "$query"
    quit 0
  elif $selected && [ $curr_mode = $MODE_RENAME ] ; then
    wm_rename_window "$curr_win" "$query"
    quit 0
  fi

  line="${prompt}${query}_"

  lecho "$line"

  if [ -n "$query" ] ; then
    filter="sort -rn"
  else
    filter="cat"
  fi

  unset sorted
  while IFS= read -r; do
    sorted+=("$REPLY")
  done < <(for a in $matches; do echo "$a"; done | $filter )

  for counter in "${!sorted[@]}"; do
    if [ $counter -gt $(( Height - 2 )) ] ; then
      continue
    fi
    if $same && [ $(( counter < cursor - 1 || counter > cursor + 1 )) -eq 1 ]; then
      if ! [ $(( counter > Height - 3 )) -eq 1 ]; then
        echo
        line_counter=$(( line_counter + 1 ))
      fi
      continue
    fi
    IFS='|' read -a arr <<< "${sorted[counter]}"
    matchness="${arr[0]}"
    window_address="${arr[1]}"
    pane_address="${arr[2]}"
    win_counter="${arr[3]}"
    window_index="${arr[4]}"

    if [ "$counter" = "$cursor" ]; then
      caret=" -"
      color="$On_Blue"
    else
      caret="  "
      color="$Blue"
    fi

    if [ $curr_mode = $MODE_FIND ]; then
      window_name=${window_names[win_counter]}
      len=$(( ${#buffs[win_counter]} ))
      snippet_len=$(( $len > 50 ? 50 : $len ))
      snippet=${buffs[win_counter]:$len - $snippet_len}
    elif [ $curr_mode = $MODE_RUN ]; then
      line="${command_buffs[win_counter]}"
      window_name=${line/:*/:}
      snippet=" \$${line#*:}"
      # len=$(( ${#buffs[win_counter]} ))
      # snippet_len=$(( $len > 50 ? 50 : $len ))
      # snippet=${buffs[win_counter]:$len - $snippet_len}
    fi

    $debug && debug_msg=" (debug: ${matchness}) "

    if [[ -z "$query" || $COLOR = 1 ]]; then
      line="${color}${caret}${debug_msg}${window_index} ${window_name} ${Color_Off}"
    elif [[ $COLOR = 2 ]]; then
      line="${color}${caret}"`echo -e "${debug_msg}${window_index} ${window_name} " | sed -e "s/\($q\)/$Yellow\1$Color_Off${color}/g" || true`"${Color_Off}"
    else
      line="${caret}${debug_msg}${window_index} ${window_name} "
    fi

    if [ $curr_mode = $MODE_FIND ]; then

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
      if [[ -n "$query" && $COLOR = 2 ]]; then
        line+=`echo -e "$snippet" | sed -e "s/\($q\)/$Yellow\1$Color_Off/g"`
      else
        line+="$snippet"
      fi
    fi

    lecho "$line"

    if $selected; then
      if [ "$counter" = "$cursor" ]; then
        if [ $curr_mode = $MODE_FIND ]; then
          wm_select_window $window_address
          quit 0
          # if [ -n "${window_address#*:}" ]; then
          #   tmux join-pane -t :${window_address#*:}
          # fi
        elif [ $curr_mode = $MODE_RUN ]; then
          line="${command_buffs[win_counter]}"
          name=${line%:*}
          cmd=$( echo ${line#*:} | sed -e 's/^ *//g' || true )
          wm_run_command "$name" "$cmd"
          quit 0
        fi
      fi
    fi
  done

  if $selected && [[ ${#sorted} = 0 ]]; then
    echo 'hi'
    wm_run_command "$query" "${query/!/}"
    quit 0
  fi

  line_counter=0
  if ! $same; then
    clear_end_of_screen
  fi
}
