#!/bin/bash
NAME="ubuntu-after-install.sh"
BLURB="Configure a device after a fresh install of Ubuntu"
SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/ubuntu-after-install"
set -eu

# Copyright (c) 2019 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

# Import some helpful functions, prefixed 'L_'
source ./Library.sh

RELEASE="18.04 LTS"         # Ubuntu release
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # Setup machine for USERNAME
SLEEP="8"                   # Pause for X seconds

Hello_you() {
L_echo_yellow "\n$( L_penguin ) .: Howdy!"
local LINK1="https://www.circuidipity.com/ubuntu-mate-1804/"
local LINK2="https://www.circuidipity.com/debian-package-list/"
cat << _EOF_
NAME
    $NAME
        $BLURB $RELEASE
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' is ideally run immediately following the first
    successful boot into *Ubuntu $RELEASE* [1].

    A choice of either a [w]orkstation or [s]erver setup is available. [S]erver
    is a basic console setup, whereas the [w]orkstation choice installs a range
    of desktop applications.
    
    Alternately, in lieu of a pre-defined list of Ubuntu packages, the user may
    specify their own custom list of packages to be installed.
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST [2]
EXAMPLES
    Run script (requires superuser privileges) ...
        # ./$NAME
    Install the list of packages specified in 'my-pkg-list' ...
        # ./$NAME -p my-pkg-list
SOURCE
    $SOURCE
SEE ALSO
    [1] "Ubuntu MATE 18.04"
        $LINK1
    [2] "Install (almost) the same list of Debian packages on multiple machines"
        $LINK2

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
            L_echo_red "\n$( L_penguin ) .: $ARG_ERR"
            exit 1
            ;;
        ?)
            L_echo_red "\n$( L_penguin ) .: Invalid option '-$OPTARG'"
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
local SSH_DIR="/home/$USERNAME/.ssh"
local AUTH_KEY="$SSH_DIR/authorized_keys"
if [[ -d $SSH_DIR ]]; then
    echo "SSH directory $SSH_DIR already exists. Skipping ..."
else
    echo "Create $SSH_DIR and set permissions ..."
    mkdir $SSH_DIR && chmod 700 $SSH_DIR && \
    touch $AUTH_KEY && chmod 600 $AUTH_KEY && \
    chown -R ${USERNAME}:${USERNAME} $SSH_DIR
fi
L_sig_ok
sleep $SLEEP
}

Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
# Add a bit of colour, a bit of sound, and wallpaper.
# "GNU GRUB"
#   https://www.circuidipity.com/grub/
local GRUB_DEFAULT="/etc/default/grub"
local WALLPAPER="/boot/grub/wallpaper-grub.tga"
local GRUB_CUSTOM="/boot/grub/custom.cfg"
L_bak_file $GRUB_DEFAULT
if [[ ! $( grep ^GRUB_INIT_TUNE $GRUB_DEFAULT ) ]]; then
    echo "Put the BEEP in the grub start beep ..."
    cat << _EOL_ >> $GRUB_DEFAULT
        
# Get a beep at grub start ... how about 'Close Encounters'?
GRUB_INIT_TUNE="480 900 2 1000 2 800 2 400 2 600 3"
_EOL_
    L_sig_ok
else
    echo "Grub already includes sound effects. Skipping ..."
    L_sig_ok
fi
if [[ ! $( grep ^GRUB_BACKGROUND $GRUB_DEFAULT ) ]]; then
    echo "Include some wallpaper and colour ..."
    cat << _EOL_ >> $GRUB_DEFAULT
        
# Wallpaper
GRUB_BACKGROUND="$WALLPAPER"
_EOL_
    if [[ -f $WALLPAPER ]]; then
        L_bak_file $WALLPAPER
    fi
    cp "$FILE_DIR/boot/grub/wallpaper-grub.tga" $WALLPAPER
    if [[ -f $GRUB_CUSTOM ]]; then
        L_bak_file $GRUB_CUSTOM
    fi
    cp "$FILE_DIR/boot/grub/custom.cfg" $GRUB_CUSTOM
    L_sig_ok
else
    echo "Grub already includes wallpaper and colour. Skipping ..."
    L_sig_ok
fi
update-grub
L_sig_ok
sleep $SLEEP
}

Conf_sudoersd() {
clear
L_banner_begin "Configure sudo"
# Add config files to /etc/sudoers.d/ to allow members of the sudo group
# extra privileges; the ability to shutdown/reboot the system and read 
# the kernel buffer using 'dmesg' without a password for example.
# "Minimal Debian -- Sudo"
#   https://www.circuidipity.com/minimal-debian/#10-sudo
local ALIAS="/etc/sudoers.d/00-alias"
local NOPASSWD="/etc/sudoers.d/01-nopasswd"
# Install sudo
apt-get -y install sudo
if [[ -f $ALIAS ]]; then
    L_bak_file $ALIAS
fi
if [[ -f $NOPASSWD ]]; then
    L_bak_file $NOPASSWD
fi
echo "Create $ALIAS ..."
cat << _EOL_ > $ALIAS
# User alias
User_Alias ADMIN = $USERNAME

# Cmnd alias specification
Cmnd_Alias SHUTDOWN_CMDS = /sbin/poweroff, /sbin/reboot, /sbin/shutdown
_EOL_
L_sig_ok
echo "Create $NOPASSWD ..."
cat << _EOL_ > $NOPASSWD
# Allow ADMIN to run any command as any user without password
#ADMIN ALL=(ALL) NOPASSWD: ALL

# Allow specified users to execute these commands without password
$USERNAME ALL=(ALL) NOPASSWD: SHUTDOWN_CMDS, /bin/dmesg
_EOL_
adduser $USERNAME sudo
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

Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local CONSOLE="apt-file apt-show-versions apt-utils aptitude cowsay git htop 
keychain neovim openssh-server pylint pylint3 shellcheck rsync sl tmux unzip 
wget whois"
# shellcheck disable=SC2086
apt-get -y install $CONSOLE
apt-file update
L_sig_ok
sleep $SLEEP
}

Inst_server_pkg() {
clear
L_banner_begin "Install server packages"
local PKG="fail2ban logwatch"
# shellcheck disable=SC2086
apt-get -y install $PKG
L_sig_ok
sleep $SLEEP
}

Inst_theme() {
clear
L_banner_begin "Install theme"
# Adapta GTK theme + Papirus-Adapta icons
local PPA="ppa:tista/adapta"
local GTK="adapta-gtk-theme"
local ICON="papirus-icon-theme"
local FONT="fonts-liberation fonts-noto fonts-roboto"
apt-add-repository -y $PPA
apt update
# shellcheck disable=SC2086
apt-get -y install $GTK $ICON $FONT
L_sig_ok
sleep $SLEEP
}

Inst_desktop_pkg() {
clear
L_banner_begin "Install some favourite desktop packages"
local DESKTOP="build-essential clipit dconf-editor ffmpeg geeqie gimp 
gimp-help-en gimp-data-extras pulseaudio-utils qpdfview rofi rxvt-unicode 
sox vlc xbindkeys xbacklight xvkbd"
# Virtualbox - more: https://www.circuidipity.com/virtualbox-debian-stretch/
local KERNEL
KERNEL=$(uname -r)
local VB_DEP="dkms module-assistant linux-headers-$KERNEL"
# *-restricted extras -- metapackage requires end-user consent before install
RESTRICT="ubuntu-restricted-extras"
# Sometimes apt gets stuck on a slow download ... breaking up downloads
# speeds things up ...
# shellcheck disable=SC2086
apt-get -y install $DESKTOP && \
#apt-get -y install $VB_DEP && apt-get -y install virtualbox \
#adduser $USERNAME vboxusers
# shellcheck disable=SC2086
apt-get -y install $RESTRICT
L_sig_ok
sleep $SLEEP
}

Conf_terminal() {
clear
L_banner_begin "Configure terminal"
local TERM="/usr/bin/urxvt"
local TERM_TAB="/usr/lib/x86_64-linux-gnu/urxvt/perl/tabbed"
if [[ -x $TERM ]]; then
    L_bak_file $TERM_TAB
    echo "Modify $TERM_TAB ..."
    cp ${FILE_DIR}${TERM_TAB} $TERM_TAB
fi
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

Conf_alt_server() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
L_sig_ok
sleep $SLEEP
}

Goto_work() {
local NUM_Q="5"
local PROFILE="foo"
local GRUB_X="foo"
local SUDO_X="foo"
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
        read -r -n 1 -p "Are you configuring a [w]orkstation or [s]erver? > "
        if [[ $REPLY == [wW] ]]; then
            PROFILE="workstation"
             break
        elif [[ $REPLY == [sS] ]]; then
            PROFILE="server"
            break
        else
            L_invalid_reply
        fi
    done
    clear
    L_banner_begin "Question 3 of $NUM_Q"
    while :
    do
        echo "GRUB extras: Add a bit of colour, a bit of sound, and wallpaper!"
        echo ""; read -r -n 1 -p "Setup a custom GRUB? [Yn] > "
        if [[ $REPLY == [nN] ]]; then
            GRUB_X="no"
            break
        elif [[ $REPLY == [yY] || $REPLY == "" ]]; then
            GRUB_X="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 4 of $NUM_Q"
    while :
    do
		echo "Add config files to /etc/sudoers.d/ to allow members of the sudo"
        echo "group extra privileges; the ability to shutdown/reboot the system"
        echo "and read the kernel buffer using 'dmesg' without a password."
        echo ""; read -r -n 1 -p "Configure a custom sudo? [Yn] > "
        if [[ $REPLY == [nN] ]]; then
            SUDO_X="no"
            break
        elif [[ $REPLY == [yY] || $REPLY == "" ]]; then
            SUDO_X="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 5 of $NUM_Q"
    L_echo_purple "Username: $USERNAME"
    L_echo_purple "Profile: $PROFILE"
    if [[ $GRUB_X == "yes" ]]; then
        L_echo_green "Custom GRUB: $GRUB_X"
    else
        L_echo_red "Custom GRUB: $GRUB_X"
    fi
    if [[ $SUDO_X == "yes" ]]; then
        L_echo_green "Custom SUDO: $SUDO_X"
    else
        L_echo_red "Custom SUDO: $SUDO_X"
    fi
    if [[ $PKG_LIST != "foo" ]]; then
        L_echo_purple "Package List: $PKG_LIST"
    fi
    echo ""; read -r -n 1 -p "Is this correct? [Yn] > "
    if [[ $REPLY == [yY] || $REPLY == "" ]]; then
        L_sig_ok
        sleep 4
        break
    elif [[ $REPLY == [nN] ]]; then
        echo -e "\nOK ... Let's try again ..."
        sleep 4
    else
        L_invalid_reply_yn
        sleep 4
    fi
done
# Common tasks
Conf_apt_update
Conf_ssh
# Custon grub
if [[ $GRUB_X == "yes" ]]; then
    Conf_grub
fi
# Custom sudo
if [[ $SUDO_X == "yes" ]]; then
    Conf_sudoersd
fi
# Workstation setup
if [[ $PROFILE == "workstation" ]]; then
    if [[ $PKG_LIST != "foo" ]]; then
        Inst_pkg_list
    else
        Inst_console_pkg
        Inst_theme
        Inst_desktop_pkg
        Conf_terminal
        Conf_alt_workstation
    fi
fi
# Server setup
if [[ $PROFILE == "server" ]]; then
    if [[ $PKG_LIST != "foo" ]]; then
        Inst_pkg_list
    else
        Inst_console_pkg
        Inst_server_pkg
        Conf_alt_server
    fi
fi
}

#: START
Run_options "$@"
L_test_announce
sleep 4
L_test_root                     # Script run with root priviliges?
L_test_internet                 # Internet access available?
L_test_datetime                 # Confirm date + timezone
L_test_systemd_fail             # Any failed units?
L_test_priority_err             # Identify high priority errors
# ... rollin' rollin' rollin' ...
Hello_you
L_run_script
Goto_work
clear
L_all_done
