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
local ERR="ERROR: script requires internet access to do its job. $OPT_HELP"
local UP
export UP
UP=$( nc -z 8.8.8.8 53; echo $? ) # Google DNS is listening?
if [[ $UP -ne 0 ]]; then
    L_echo_red "\n$( L_penguin ) .: $ERR"
    exit 1
fi
}


L_test_datetime() {
clear
L_banner_begin "Confirm date + timezone"
local LINK="<https://wiki.archlinux.org/index.php/time>"
if [[ -x "/usr/bin/timedatectl" ]]; then
    timedatectl
else
    echo -e "Current date is $( date -I'minutes' )"
fi
while :
do
    read -n 1 -p "Modify? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo -e "\n\n$( L_penguin ) .: Check out datetime in Arch Wiki $LINK" 
        echo "plus 'dpkg-reconfigure tzdata' for setting default timezone."
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
clear
L_banner_begin "List 'systemctl --failed' units"
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
clear
L_banner_begin "Identify high priority errors with 'journalctl -p 0..3 -xn'"
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
cat << _EOL_ > $FILE
deb $MIRROR $1 $COMP
deb-src $MIRROR $1 $COMP

deb $MIRROR1 $1/updates $COMP
deb-src $MIRROR1 $1/updates $COMP
_EOL_
L_sig_ok
L_apt_update_upgrade
}


L_all_done() {
local AU_REVOIR="All done!"
if [[ -x "/usr/games/cowsay" ]]; then
    L_echo_green "$( /usr/games/cowsay $AU_REVOIR )"
else
    echo -e "$( L_penguin ) .: $AU_REVOIR"
fi
}


