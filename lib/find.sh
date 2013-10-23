function find_window() {
    q=$( prepare_q "$query" )
    prompt="${prompt_color}find:${Color_Off} "
    win_counter=0

    while read window_line ; do
      window_index=${window_line%%:*}
      window_name=${window_line#*:}
      window_address=$curr_sess:$window_index

      if [ "$curr_win" = "$window_address" ]; then
        prompt="${prompt_color}[${window_name}] find:${Color_Off} "
        continue
      fi

      if [ -z "${window_names[win_counter]}" ]; then
        window_names[$win_counter]="${window_name}"
      fi

      pane_counter=0
      if $SEARCH_PANES; then
        if [ -z "${buffs[win_counter]}" ]; then
          for line in `wm_list_panes $curr_sess:$window_index`; do
            pane_index=${line%:*}
            pane_address=$window_address.$pane_index
            buff="`wm_pane_content $pane_address`"

            buffs[$win_counter]="${buffs[win_counter]} ${buff}"
            pane_counter=$(( pane_counter + 1 ))
          done

          x=$(
            echo "${buffs[win_counter]}" |tr -d '[\r\n]' |sed -e 's/  */ /g'
          )
          # To lower case
          [ ${BASH_VERSINFO[0]} -gt 3 ] && x=${x,,}
          buffs[$win_counter]="x ${pane_counter} $x"
        fi
      else
        buffs=
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
        matches="$matches $matchness|$window_address|dummypane|$win_counter|"
      fi
      win_counter=$(( win_counter + 1 ))
    done <<< "$matches" < <( echo "$all_windows" )
}
