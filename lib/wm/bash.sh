# Create a new window
#
# $0 [$name [$command]]
#
function wm_new_window {

  name=$1
  script=$2

  if [ -n "$name" ]; then
    tmux new-window -n "$name" "$script"
    tmux set-window-option allow-rename off
  else
    tmux new-window "$script"
  fi

}

# Rename window at given address
#
# $0 $address [$name]
#
function wm_rename_window {

  address=$1
  name=$2

  if [ -n "$name" ]; then
    tmux set-window-option -t $address allow-rename off
    tmux rename-window -t $address "$name"
  else
    tmux set-window-option -t $address allow-rename on
  fi
}


# Select a window
#
# $0 $address
#
function wm_select_window {

  address=$1

  tmux select-window -t $address
}

# Send keys
#
# $0 $keys
#
function wm_send_keys {

  keys=$1

  tmux send-keys "${keys}" C-m
}

# List windows
#
# $0 [$session_address]
#
# return:
# Echo each window in a line in this format:
#    window_a_index:window_a_name
#    window_b_index:window_b_name
#
# The list must be ordered by last selected time so the first item in the list
# is the previously selected window
#
function wm_list_windows {
  echo
}

# Run cmd
#
# $0 $name [$cmd]
#
function wm_run_command {
  name="$1"
  cmd="$2"

  $cmd
}

# Echo address of current session
#
# $0
#
function wm_current_session_address {
  echo
}

# Echo address of current window
#
# $0
#
function wm_current_window_address {
  echo
}

# Echo address of current pane
#
# $0
#
function wm_current_pane_address {
  echo
}

# List windows
#
# $0 [$address]
#
# return:
# Echo each window in a line in this format:
#    pane_a_index:pane_a_name
#    pane_b_index:pane_b_name
#
# The list must be ordered by last selected time so the first item in the list
# is the previously selected window
#
function wm_list_panes {
  echo
}

# Echo content of pane
#
# $0 $address
#
function wm_pane_content {
  echo
}
