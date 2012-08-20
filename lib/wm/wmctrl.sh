# This file is an incomplete and not tested.
# Any improvements is welcomed.

# Create a new window
#
# $0 [$name [$command]]
#
function wm_new_window {

  name=$1
  script=$2
  term=xterm
  bash=/bin/bash

  if [ -n "$name" ]; then
    $term -e $bash -c "echo -e '\033k$name\033\\' && $script"
  else
    $term -e $bash -c "$script"
  else
  fi

}

# Rename window at given address
#
# $0 $address [$name]
#
function wm_rename_window {

  address=$1
  name=$2

  wmctrl -r "$address" -T "$name"
}


# Select a window
#
# $0 $address
#
function wm_select_window {

  address=$1

  wmctrl -a "$address"
}

# Send keys
#
# $0 $keys
#
function wm_send_keys {
  
  keys=$1

  echo "TODO - also look into xdotool"
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

  session_address=$1

  echo "TODO make sure format is correct"
  wmctrl -l
}

# Echo address of current session
#
# $0
#
function wm_current_session_address {
  echo "TODO"
}

# Echo address of current window
#
# $0
#
function wm_current_window_address {
  echo "TODO"
}

# Echo address of current pane
#
# $0
#
function wm_current_pane_address {
  echo "XXX NO PANES"
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

  address=$1
  echo "XXX NO PANES"
}

# Echo content of pane
# 
# $0 $address
#
function wm_pane_content {

  address=$1

  echo "XXX NO PANES"
}
