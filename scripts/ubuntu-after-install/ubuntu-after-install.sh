#!/bin/bash
NAME="ubuntu-after-install.sh"
BLURB="Configure a device after a fresh install of Ubuntu"
SRC_DIR="https://github.com/vonbrownie/linux-post-install"
SOURCE="${SRC_DIR}/tree/master/scripts/ubuntu-after-install"
set -eu

# Copyright (c) 2019 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

RELEASE="18.04 LTS"         # Ubuntu release to track
DOTFILES="https://github.com/vonbrownie/dotfiles"
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # Setup machine for USERNAME
SLEEP="8"                   # Pause for X seconds
# ANSI escape codes
RED="\\033[1;31m"
GREEN="\\033[1;32m"
YELLOW="\\033[1;33m"
PURPLE="\\033[1;35m"
NC="\\033[0m" # no colour

L_echo_red() {
echo -e "${RED}$1${NC}"
}

L_echo_green() {
echo -e "${GREEN}$1${NC}"
}

L_echo_yellow() {
echo -e "${YELLOW}$1${NC}"
}

L_echo_purple() {
echo -e "${PURPLE}$1${NC}"
}

L_banner_begin() {
L_echo_yellow "\\n--------[  $1  ]--------\\n"
}

L_banner_end() {
L_echo_green "\\n--------[  $1 END  ]--------\\n"
}

L_sig_ok() {
L_echo_green "\\n--> [ OK ]"
}

L_sig_fail() {
L_echo_red "\\n--> [ FAIL ]"
}

L_invalid_reply() {
L_echo_red "\\n'${REPLY}' is invalid input..."
}

L_invalid_reply_yn() {
L_echo_red "\\n'${REPLY}' is invalid input. Please select 'Y(es)' or 'N(o)'..."
}

L_penguin() {
cat << _EOF_
(O<
(/)_
_EOF_
}

L_test_announce() {
    L_echo_yellow "\\n$( L_penguin ) .: Let's first run a few tests ..."
}

L_test_root() {
local ERR="ERROR: script must be run with root privileges."
if (( EUID != 0 )); then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
    exit 1
fi
}

L_test_internet() {
local ERR="ERROR: script requires internet access to do its job."
local UP
export UP
UP=$( nc -z 8.8.8.8 53; echo $? ) # Google DNS is listening?
if [[ "$UP" -ne 0 ]]; then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
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
    echo ""; read -r -n 1 -p "Modify? [yN] > "
    if [[ "$REPLY" == [yY] ]]; then
        echo -e "\\n\\n$( L_penguin ) .: Check out datetime in Arch Wiki $LINK" 
        echo "plus 'dpkg-reconfigure tzdata' for setting default timezone."
        exit
    elif [[ "$REPLY" == [nN] || "$REPLY" == "" ]]; then
        clear
        break
    else
        L_invalid_reply_yn
    fi
done
}

L_test_required_file() {
local FILE=$1
local ERR="ERROR: file '$FILE' not found."
if [[ ! -f "$FILE" ]]; then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
    exit 1
fi
}

L_test_homedir() {
# $1 is $USER
local ERR="ERROR: no USERNAME provided."
if [[ "$#" -eq 0 ]]; then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
    exit 1
elif [[ ! -d "/home/$1" ]]; then
    local ERR1="ERROR: a home directory for '$1' not found."
    L_echo_red "\\n$( L_penguin ) .: $ERR1"
    exit 1
fi
}

L_bak_file() {
for f in "$@"; do cp "$f" "$f.$(date +%FT%H%M%S).bak"; done
}

L_run_script() {
while :
do
    read -r -n 1 -p "Run script now? [yN] > "
    if [[ "$REPLY" == [yY] ]]; then
        echo -e "\\nLet's roll then ..."
        sleep 4
        break
    elif [[ "$REPLY" == [nN] || "$REPLY" == "" ]]; then
        L_echo_purple "\\n$( L_penguin )"
        exit
    else
        L_invalid_reply_yn
    fi
done
}

L_all_done() {
local MSG="All done!"
if [[ -x "/usr/games/cowsay" ]]; then
    L_echo_green "$( /usr/games/cowsay "$MSG" )"
else
    echo -e "$( L_penguin ) .: $MSG"
fi
}


Hello_you() {
L_echo_yellow "\\n$( L_penguin ) .: Howdy!"
local LINK="https://www.circuidipity.com"
cat << _EOF_
NAME
    $NAME
        $BLURB $RELEASE
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' is ideally run after the first successful
    boot into a desktop install of Ubuntu's _${RELEASE}_ release.

    A few tweaks will be made here and there, and a range of applications will
    be installed.

    Alternately, in lieu of a pre-defined list of Ubuntu packages, the user may
    specify their own custom list of packages to be installed.
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST
EXAMPLES
    Run script (requires superuser privileges) ...
        # ./$NAME
    Install the list of packages specified in 'my-pkg-list' ...
        # ./$NAME -p my-pkg-list
AUTHOR
    Daniel Wayne Armstrong
        $LINK
SOURCE
    $SOURCE
LICENSE
    GPLv2. See LICENSE for more details.
        https://github.com/vonbrownie/linux-post-install/blob/master/LICENSE
SEE ALSO
    * Install (almost) the same list of Debian packages on multiple machines
        ${LINK}/debian-package-list/

_EOF_
}

Run_options() {
while getopts ":hp:" OPT
do
    case $OPT in
        h)
            Hello_you
            exit
            ;;
        p)
            PKG_LIST="$OPTARG"
            L_test_required_file "$PKG_LIST"
            ;;
        :)
            local ARG_ERR="Option '-$OPTARG' requires an argument."
            L_echo_red "\\n$( L_penguin ) .: $ARG_ERR"
            exit 1
            ;;
        ?)
            L_echo_red "\\n$( L_penguin ) .: Invalid option '-$OPTARG'"
            exit 1
            ;;
    esac
done
}

Conf_apt_update() {
clear
L_banner_begin "Update packages and upgrade $HOSTNAME"
apt-get update && apt-get -y dist-upgrade
L_sig_ok
sleep $SLEEP
}

Conf_ssh() {
clear
L_banner_begin "Create SSH directory for $USERNAME"
# Install SSH server and create $HOME/.ssh.
# "Secure remote access using SSH keys"
#   https://www.circuidipity.com/ssh-keys/
local SSH_DIR="/home/${USERNAME}/.ssh"
local AUTH_KEY="${SSH_DIR}/authorized_keys"
# Install ssh server and keychain
apt-get -y install openssh-server keychain
# Create ~/.ssh
if [[ -d "$SSH_DIR" ]]; then
    echo "SSH directory $SSH_DIR already exists. Skipping ..."
else
    mkdir $SSH_DIR && chmod 700 $SSH_DIR && touch $AUTH_KEY
    chmod 600 $AUTH_KEY && chown -R ${USERNAME}:${USERNAME} $SSH_DIR
fi
L_sig_ok
sleep $SLEEP
}

Conf_trim() {
clear
L_banner_begin "Configure periodic trim for SSD"
# Periodic TRIM optimizes performance on SSD storage. Enable a weekly task
# that discards unused blocks on the drive.
echo "Enabling timer ..."
systemctl enable fstrim.timer
L_sig_ok
sleep $SLEEP
}

Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
# Add some extras. See "GNU GRUB" -- https://www.circuidipity.com/grub/
local GRUB_DEFAULT="/etc/default/grub"
local WALLPAPER="/boot/grub/wallpaper-grub.tga"
local DWNLD="${SRC_DIR}/blob/master/config${WALLPAPER}?raw=true"
local CUSTOM="/boot/grub/custom.cfg"
# Backup config
L_bak_file $GRUB_DEFAULT
if ! grep -q ^GRUB_DISABLE_SUBMENU "$GRUB_DEFAULT"; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Kernel list as a single menu
GRUB_DISABLE_SUBMENU=y
_EOL_
fi
if ! grep -q ^GRUB_INIT_TUNE "$GRUB_DEFAULT"; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Start off with a bit of "Close Encounters"
GRUB_INIT_TUNE='480 900 2 1000 2 800 2 400 2 600 3'
_EOL_
fi
if ! grep -q ^GRUB_BACKGROUND $GRUB_DEFAULT; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Wallpaper
GRUB_BACKGROUND='$WALLPAPER'
_EOL_
fi
# Install wallpaper
if [[ -f "$WALLPAPER" ]]; then
    echo "$WALLPAPER already exists. Skipping ..."
else
    wget -c "$DWNLD" -O "$WALLPAPER"
fi
# Menu colours
if [[ -f "$CUSTOM" ]]; then
    echo "$CUSTOM already exists. Skipping ..."
else
    cat << _EOL_ > $CUSTOM
set color_normal=white/black
set menu_color_normal=white/black
set menu_color_highlight=white/blue
_EOL_
fi
# Apply changes
update-grub
L_sig_ok
sleep $SLEEP
}

Inst_pkg_list() {
clear
L_banner_begin "Install packages from '$PKG_LIST' list (option '-p')"
# Update dpkg database of known packages.
# "Install (almost) the same list of Debian packages on multiple machines"
#   https://www.circuidipity.com/debian-package-list/
local AVAIL
    AVAIL=$( mktemp )
apt-cache dumpavail > "$AVAIL"
dpkg --merge-avail "$AVAIL"
rm -f "$AVAIL"
# Update the dpkg selections
dpkg --set-selections < "$PKG_LIST"
L_sig_ok
sleep $SLEEP
# Use apt-get to install the selected packages
apt-get -y dselect-upgrade
L_sig_ok
sleep $SLEEP
}

Conf_microcode() {
clear
L_banner_begin "Install microcode"
# Intel and AMD processors may periodically need updates to their microcode
# firmware. Microcode can be updated (and kept in volatile memory) during
# boot by installing either intel-microcode or amd64-microcode (AMD).
local CPU="/proc/cpuinfo"
if grep -q GenuineIntel "$CPU"; then
    apt-get -y install intel-microcode
elif grep -q AuthenticAMD "$CPU"; then
    apt-get -y install amd64-microcode
fi
L_sig_ok
sleep $SLEEP
}

Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local PKG_TOOLS="apt-file apt-listchanges apt-show-versions apt-utils 
aptitude command-not-found"
local CONSOLE="bsd-mailx cowsay cryptsetup git gnupg htop mlocate net-tools 
pmount rsync sl tmux unzip vrms wget whois"
local EDITOR="neovim shellcheck"
# shellcheck disable=SC2086
apt-get -y install $PKG_TOOLS $CONSOLE $EDITOR
apt-file update
# Create the mlocate database
/etc/cron.daily/mlocate
# Train kept a rollin' ...
if [[ -x "/usr/games/sl" ]]; then
    /usr/games/sl
fi
L_sig_ok
sleep $SLEEP
}

Inst_theme() {
clear
L_banner_begin "Install theme"
local GTK="gnome-themes-standard gtk2-engines-murrine gtk2-engines-pixbuf"
local QT="qt5-style-plugins"
local TOOL="lxappearance obconf"
local THEME="Shades-of-gray-theme"
local THEMEDIR="/home/${USERNAME}/.themes"
local DWNLD_THEME="https://github.com/WernerFP/Shades-of-gray-theme.git"
local ICON="Suru++"
local ICONDIR="/home/${USERNAME}/.icons"
local ICONGIT="https://raw.githubusercontent.com"
local DWNLD_ICON="${ICONGIT}/gusbemacbe/suru-plus/master/install.sh"
# shellcheck disable=SC2086 
apt-get -y install $GTK $QT $TOOL
# Install the *Shades-of-gray* theme
if [[ -d "$THEMEDIR" ]]; then
    echo "$THEMEDIR already exists."
else
    mkdir $THEMEDIR
fi
if [[ -d "$THEME" ]]; then
    echo "$THEME already exists."
else
    git clone $DWNLD_THEME
    cp -r ${THEME}/Shades-of-* $THEMEDIR
    chown -R ${USERNAME}:${USERNAME} $THEMEDIR
fi
# Install Suru++ icons
if [[ -d "$ICONDIR" ]]; then
    echo "$ICONDIR already exists."
else
    mkdir $ICONDIR
fi
if [[ -d "${ICONDIR}/${ICON}" ]]; then
    echo "${ICON} icons already installed."
else
    wget -qO- $DWNLD_ICON | env DESTDIR="$ICONDIR" sh
    chown -R ${USERNAME}:${USERNAME} $ICONDIR
fi
L_sig_ok
sleep $SLEEP
}

Inst_workstation_pkg() {
clear
L_banner_begin "Install some favourite desktop packages"
local DESKTOP="chrome-gnome-shell dconf-editor ffmpeg flashplugin-installer 
geeqie gimp gimp-help-en gimp-data-extras gnome-shell-extensions 
gnome-system-monitor gnome-tweak-tool qpdfview rofi rxvt-unicode sox vlc"
# *-restricted extras -- metapackage requires end-user consent before install
local RESTRICT="ubuntu-restricted-extras"
# shellcheck disable=SC2086
apt-get -y install $DESKTOP
# shellcheck disable=SC2086
apt-get -y install $RESTRICT
L_sig_ok
sleep $SLEEP
}

Conf_alt_workstation() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
update-alternatives --config x-terminal-emulator
L_sig_ok
sleep $SLEEP
}

Goto_work() {
local NUM_Q="4"
local SSD="foo"
local GRUB_X="foo"
while :
do
    clear
    L_banner_begin "Question 1 of $NUM_Q"
    read -r -p "What is your non-root username? > " FOO; USERNAME="$FOO"
    L_test_homedir "$USERNAME"        # $HOME exists for USERNAME?
    clear
    L_banner_begin "Question 2 of $NUM_Q"
	while :
    do
        echo "Periodic TRIM optimizes performance on solid-state storage. If"
        echo -e "this machine has an SSD drive, you should enable this task.\\n"
		read -r -n 1 -p "Enable task that discards unused blocks? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            SSD="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            SSD="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 3 of $NUM_Q"
    while :
    do
        echo -e "GRUB extras: Add a bit of colour, sound, and wallpaper!\\n"
		read -r -n 1 -p "Setup a custom GRUB? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            GRUB_X="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            GRUB_X="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 4 of $NUM_Q"
    L_echo_purple "Username: $USERNAME"
    if [[ "$SSD" == "yes" ]]; then
        L_echo_green "SSD: $SSD"
    else
        L_echo_red "SSD: $SSD"
    fi
    if [[ "$GRUB_X" == "yes" ]]; then
        L_echo_green "Custom GRUB: $GRUB_X"
    else
        L_echo_red "Custom GRUB: $GRUB_X"
    fi
    if [[ "$PKG_LIST" != "foo" ]]; then
        L_echo_green "Package List: $PKG_LIST"
    fi
    echo ""
	read -r -n 1 -p "Is this correct? [Yn] > "
    if [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
		echo ""
        L_sig_ok
        sleep 4
        break
    elif [[ "$REPLY" == [nN] ]]; then
        echo -e "\\nOK ... Let's try again ..."
        sleep 4
    else
        L_invalid_reply_yn
        sleep 4
    fi
done
Conf_apt_update
Conf_ssh
Conf_microcode
# Periodic trim
if [[ "$SSD" == "yes" ]]; then
    Conf_trim
fi
# Custon grub
if [[ "$GRUB_X" == "yes" ]]; then
    Conf_grub
fi
if [[ $PKG_LIST != "foo" ]]; then
    Inst_pkg_list
else
    Inst_console_pkg
    Inst_theme
    Inst_workstation_pkg
    Conf_alt_workstation
fi
}

#: START
Run_options "$@"
L_test_announce
sleep 4
L_test_root			# Script run with root priviliges?
L_test_internet		# Internet access available?
L_test_datetime		# Confirm date + timezone
# ... rollin' rollin' rollin' ...
Hello_you
L_run_script
Goto_work
clear
L_all_done
L_echo_green "See 'dotfiles' <${DOTFILES}> for config file examples"
L_echo_green "useful for ${USERNAME}'s HOME directory."
L_echo_green "\\nThanks for using '${NAME}' and happy hacking!"
