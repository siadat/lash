Blue=`echo -e '\e[0;34m'`
On_Blue=`echo -e '\e[44m'`
Yellow=`echo -e '\e[1;32m'`
Color_Off=`echo -e '\e[0m'`
Width=`tput co`
Height=`tput li`
prompt_color="$Yellow"
SEARCH_PANES=true
PID=$$

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

function update {
  matches=
  query=${1,,}
  selected=$2
  mode_rename=$3
  mode_new_win=$4
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

  if $mode_rename; then
    prompt="${prompt_color}set title >>> ${Color_Off}"

  elif $mode_new_win; then
    prompt="${prompt_color}new window >>> ${Color_Off}"

  else
    prompt="${prompt_color}goto >>> ${Color_Off}"

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
          q=$( echo "$query" |sed -e 's/\(.\)/.*\1/g' )
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

  if $selected && $mode_new_win; then
    if [ -n "$query" ]; then
      tmux new-window -n "$query"
      tmux set-window-option allow-rename off
    else
      tmux new-window
    fi
    quit 0
  elif $selected && $mode_rename; then
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

    line=
    line+="${color}"
    line+=`echo -e "${caret}${window_index}:${window_name}" |sed -e "s/\($query\)/$Yellow\1$Color_Off${color}/g" || true`
    line+="${Color_Off}"
    if $SEARCH_PANES; then
      if [ $matchness -eq 0 ]; then
        line+=`echo -e " "`
      elif [ $matchness -gt 1000 ]; then
        line+=`echo -e " "`
      else
        line+=`echo -e " - pane content"`
      fi
    else
      line+=`echo -e " "`
    fi
    cho "$line"


    if $selected; then
      if [ "$counter" = "$cursor" ]; then
        tmux select-window -t $window_address
        # tmux select-pane -t $pane_address
        quit 0
      fi
    fi
  done
  tput cd || tput ed || true
}
