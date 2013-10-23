function run_command() {
    i=0

    if [ ${#command_buffs} -eq 0 ]; then

      while read line; do
        if [ -n "$( echo "$line" | sed -e 's/\s*#.*//g' | sed -e 's/^ *//g' )" ]; then
          command_buffs[$i]="$line"
          i=$(( i + 1 ))
        fi
      done < <( cat "$COMMAND_FILE1" "$COMMAND_FILE2" 2> /dev/null ; if $SEARCH_HISTORY; then cat ~/.bash_history ~/.fish_history ~/.zsh_history 2> /dev/null | tail -50 | sed -e 's///g' | sed -e 's/[ 0-9:;]*/hist: /'; fi )
    fi

    prompt="${prompt_color}run:${Color_Off} "

    q=$( prepare_q "$query" )
    for _win_counter in "${!command_buffs[@]}"; do
      line=${command_buffs[_win_counter]}
      name=${line/:*/}
      cmd=${line#*:}

      if [[ "$name" =~ $q ]]; then
        g1="${#BASH_REMATCH[0]}"
        g1=$(( 10000 - (g1 - ${#query}) ))
      else
        g1=0
      fi

      if [[ "$cmd" =~ $q ]]; then
        g2="${#BASH_REMATCH[0]}"
        g2=$(( 1000 - (g2 - ${#query}) ))
      else
        g2=0
      fi

      matchness=$(( g1 + g2 ))

      if [ $matchness -gt 0 -o "$q" = "" ]; then
        window_address=$_win_counter
        window_index=' '
        matches="$matches $matchness|$window_address|dummypane|$_win_counter|$window_index"
      fi
    done <<< "$matches"
}
