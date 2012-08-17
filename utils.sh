Blue=`echo -e '\e[0;34m'`
On_Blue=`echo -e '\e[44m'`
Yellow=`echo -e '\e[1;32m'`
Color_Off=`echo -e '\e[0m'`

Width=`tput co`

function read_char {
  read -s -n 1 c
  printf '%d' "'$c'"
}

function quit {
  stty echo
  tput cnorm
  exit $1
}
