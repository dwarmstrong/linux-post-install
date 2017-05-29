#!/bin/bash
# NAME="Library.sh"
# BLURB="A library of functions for bash shell scripts"
# SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts"
set -eu

# Place in local directory and call its functions by adding to script ...
#   . ./Library.sh

OPT_HELP="Run with '-h' for details."
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
L_echo_yellow "\n--------[  $1  ]--------\n"
}


L_banner_end() {
L_echo_green "\n--------[  $1 END  ]--------\n"
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
local SCRIPT_NAME="debian-stable-setup"
local SCRIPT_GIT="https://github.com/vonbrownie"
local SCRIPT_SOURCE="$SCRIPT_GIT/linux-post-install/tree/master/scripts"
local HTTP0="http://www.circuidipity.com/minimal-debian.html"
local HTTP1="http://www.circuidipity.com/i3-tiling-window-manager.html"
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
    Post-install setup a machine for the (existing) username 'foo':
        # ./setup.sh foo
DESCRIPTION
    Script 'setup.sh' is ideally run immediately following the first
    successful boot into your new Debian installation.

    Building on a minimal install [0] the system will be configured to
    track Debian's _stable_ release, and (or disable with '-b') the i3
    tiling window manager [1] plus a packages collection suitable for
    a workstation will be installed.

    [0] "Minimal Debian" <$HTTP0>
    [1] "Tiling window manager" <$HTTP1>
DEPENDS
    bash
SOURCE
    $SCRIPT_SOURCE

_EOF_
}


L_test_root() {
local ERR="ERROR: script must be run with root privileges. $OPT_HELP"
if (( EUID != 0 )); then
    L_echo_red "\n$( L_penguin ) .: $ERR"
    exit 1
fi
}


L_test_homedir() {
# $1 is $USER
local ERR="ERROR: no USERNAME provided. $OPT_HELP"
if [[ "$#" -eq 0 ]]; then
    L_echo_red "\n$( L_penguin ) .: $ERR"
    exit 1
elif [[ ! -d "/home/$1" ]]; then
    local ERR1="ERROR: a home directory for '$1' not found. $OPT_HELP"
    L_echo_red "\n$( L_penguin ) .: $ERR1"
    exit 1
fi
}


L_test_internet() {
local ERR="ERROR: script requires internet access to do its job."
local UP=$( nc -z 8.8.8.8 53; echo $? ) # Google DNS is listening?
if [[ $UP -ne 0 ]]; then
    L_echo_red "\n$( L_penguin ) .: $ERR"
    exit 1
fi
}


L_test_datetime() {
L_banner_begin "Confirm date + timezone"
if [[ -x "/usr/bin/timedatectl" ]]; then
    timedatectl
else
    echo -e "Current date is $( date -I'minutes' )"
fi
while :
do
    read -n 1 -p "Modify? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo -e "\n\n$( L_penguin ) .: Check out datetime in the Arch Wiki "`
        `"<https://wiki.archlinux.org/index.php/time>\n"`
        `"plus 'dpkg-reconfigure tzdata' for setting default timezone."
        exit
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        clear
        break
    else
        L_invalid_reply_yn
    fi
done
}


L_test_systemd_fail() {
L_banner_begin "List 'systemctl --failed' units"
sleep 5
systemctl --failed
while :
do
    read -n 1 -p "Continue script? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        clear
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
         echo ""
         L_penguin
         exit
     else
         L_invalid_reply_yn
     fi
 done
}


L_test_priority_err() {
L_banner_begin "Identify high priority errors with 'journalctl -p 0..3 -xn'"
sleep 5
journalctl -p 0..3 -xn
while :
do
    read -n 1 -p "Continue script? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        clear
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        echo ""
        L_penguin
        exit
    else
        L_invalid_reply_yn
    fi
done
}


L_bak_file() {
for f in "$@"; do cp "$f" "$f.$(date +%FT%H%M%S).bak"; done
}


L_apt_update_upgrade() {
L_echo_yellow "\nUpdate packages and upgrade $HOSTNAME ..."
apt update && apt -y full-upgrade
L_sig_ok
}


L_conf_apt_src_stable() {
# $1 is debian RELEASE
local FILE="/etc/apt/sources.list"
local MIRROR="http://deb.debian.org/debian/"
local MIRROR1="http://security.debian.org/debian-security"
local COMP="main contrib non-free"
L_echo_yellow "\nBackup $FILE ..."
L_bak_file $FILE
L_sig_ok
L_echo_yellow "\nConfigure sources.list for '$1' ..."
echo "deb $MIRROR $1 $COMP" > $FILE
echo -e "deb-src $MIRROR $1 $COMP\n" >> $FILE
echo "deb $MIRROR1 $1/updates $COMP" >> $FILE
echo -e "deb-src $MIRROR1 $1/updates $COMP\n" >> $FILE
L_sig_ok
L_apt_update_upgrade
}


L_all_done() {
local AU_REVOIR="All done!"
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
            echo "Basic setup (no desktop)" #TEST
            BASIC=y
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


