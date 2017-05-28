#!/bin/bash
set -eu

# NAME="Library.sh"
# BLURB="A library of functions for bash shell scripts"

# Place in local directory and call its functions by adding to script ...
#
# . ./Library.sh

# ANSI escape codes
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # no colour


L_echo_red() {
echo -e "${RED}$1${NC}"
}


L_echo_green() {
echo -e "${GREEN}$1${NC}"
}


L_echo_yellow() {
echo -e "${YELLOW}$1${NC}"
}


L_banner_begin() {
L_echo_yellow "\n\t\t*** $1 BEGIN ***\n"
}


L_banner_end() {
L_echo_green "\n\t\t*** $1 END ***\n"
}


L_sig_ok() {
L_echo_green "--> [ OK ]"
}


L_sig_fail() {
L_echo_red "--> [ FAIL ]"
}


L_invalid_reply() {
L_echo_red "\n'${REPLY}' is invalid input..."
}


L_invalid_reply_yn() {
L_echo_red "\n'${REPLY}' is invalid input. Please select 'Y(es)' or 'N(o)'..."
}


L_penguin() {
cat << _EOF_
(O<
(/)_
_EOF_
}


L_greeting() {
local SCRIPT_NAME
    SCRIPT_NAME="debian-stable-setup"
local SCRIPT_GIT
    SCRIPT_GIT="https://github.com/vonbrownie"
local SCRIPT_SOURCE
    SCRIPT_SOURCE="$SCRIPT_GIT/linux-post-install/tree/master/scripts"
local HTTP0
    HTTP0="http://www.circuidipity.com/minimal-debian.html"
local HTTP1
    HTTP1="http://www.circuidipity.com/i3-tiling-window-manager.html"
echo -e "\n$( L_penguin ) .: Howdy!"
cat << _EOF_
NAME
    $SCRIPT_NAME
SYNOPSIS
    setup.sh [ options ] USERNAME
OPTIONS
    -h  print details
    -b  basic setup (no desktop)
EXAMPLE
    Post-install setup a machine running Debian _stable_ for username 'foo':
        # ./setup.sh foo
DESCRIPTION
    Script 'setup.sh' is ideally run immediately following the first successful
    boot into your new Debian installation.

    Building on a minimal install [0] the system will be configured to track
    Debian's _stable_ branch, and the i3 tiling window manager [1] plus a
    collection of packages suitable for a workstation will be installed.

    [0] "Minimal Debian" <$HTTP0>
    [1] "i3 wm" <$HTTP1>

    See the README before first use.
DEPENDS
    bash
SOURCE
    $SCRIPT_SOURCE

_EOF_
}


L_all_done() {
local AU_REVOIR
    AU_REVOIR="All done!"
if [[ -x "/usr/games/cowsay" ]]; then
    /usr/games/cowsay "$AU_REVOIR"
else
    echo -e "$( L_penguin ) .: $AU_REVOIR"
fi
}


L_run_options() {
while getopts ":hb" OPT
do
    case $OPT in
        h)
            L_greeting
            exit
            ;;
        b)
            echo "base install" #TEST
            exit
            ;;
        ?)
            L_echo_red "\n$( L_penguin ) .: ERROR: Invalid option '-$OPTARG'"
            exit 1
            ;;
    esac
done
}


L_run_script() {
while :
do
    read -n 1 -p "Run script now? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo -e "\nLet's roll then ..."
        sleep 2
        if [[ -x "/usr/games/sl" ]]; then
            /usr/games/sl
        fi
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        echo -e "\n$( L_penguin )"
        exit
    else
        L_invalid_reply_yn
    fi
done
}


L_bak_file() {
for f in "$@"; do cp "$f" "$f.$(date +%FT%H%M%S).bak"; done
}


