#!/bin/bash
NAME="ubuntu-mate-setup"
BLURB="Post-install setup of a machine running Ubuntu MATE 17.10"
SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/ubuntu-mate-stable-setup"
set -eu

# Copyright (c) 2017 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

# Import some helpful functions, prefixed 'L_'
. ./Library.sh

USERNAME="${*: -1}"         # Setup machine for USERNAME
RELEASE="artful"            # Ubuntu MATE release _codename_ to track
CONFIG="$(pwd)/config"      # Script settings
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'

Hello_you() {
local HTTP0="https://www.circuidipity.com/minimal-ubuntu/"
local HTTP1="https://github.com/vonbrownie/homebin/blob/master/generatePkgList"
local HTTP2="https://www.circuidipity.com/debian-package-list/"
L_echo_yellow "\n$( L_penguin ) .: Howdy!"
cat << _EOF_
NAME
    $NAME
SYNOPSIS
    $NAME.sh [ options ] USER
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST
EXAMPLE
    $BLURB for (existing) USER 'foo' ...
        $ sudo ./$NAME.sh foo
    Install packages from 'pkg-list' ...
        $ sudo ./$NAME.sh -p pkg-list foo
DESCRIPTION
    Script '$NAME.sh' is ideally run immediately following
    the first successful boot into your new Ubuntu MATE installation.

    Building on a default setup of release 17.10 "Artful Aardvark",
    a choice of either ...

    1) configuration tweaks and extra desktop packages; or
    2) duplicate the same list of packages as PKG_LIST
    
    ... will be installed.

    More ...
    * "Minimal Ubuntu" <$HTTP0>
    * "generatePkgList" <$HTTP1>
    * "Install list of Ubuntu/Debian packages on multiple machines" <$HTTP2>
DEPENDS
    bash
SOURCE
    $SOURCE

_EOF_
}


Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local PKG_TOOLS="apt-file apt-show-versions apt-utils aptitude" 
local CONSOLE="cowsay cryptsetup curl dirmngr figlet git gnupg hdparm htop 
keychain less neovim net-tools nmap openssh-server pmount rsync sl tmux unzip 
wget whois"
apt-get -y install $PKG_TOOLS $CONSOLE
apt-file update
L_sig_ok
sleep 8
}


Conf_ssh() {
clear
L_banner_begin "Create SSH directory for $USERNAME"
local SSH_DIR="/home/$USERNAME/.ssh"
local AUTH_KEY="$SSH_DIR/authorized_keys"
if [[ -d $SSH_DIR ]]; then
    echo "SSH directory $SSH_DIR already exists. Skipping ..."
else
    echo "Create $SSH_DIR and set permissions ..."
    mkdir $SSH_DIR && chmod 700 $SSH_DIR && \
    touch $AUTH_KEY && chmod 600 $AUTH_KEY && \
    chown -R "$USERNAME:$USERNAME" $SSH_DIR
fi
L_sig_ok
sleep 8
}


Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
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
sleep 8
}


Inst_desktop_pkg() {
clear
L_banner_begin "Install some favourite desktop packages"
local XORG="xbacklight xbindkeys xinput xvkbd" 
local AV="ffmpeg pavucontrol sox ubuntu-restricted-extras vlc"
local DOC="qpdfview"
local IMAGE="gimp gimp-help-en gimp-data-extras"
local NET="flashplugin-installer"
local DEV="autoconf automake bc build-essential devscripts fakeroot"
# Sometimes apt gets stuck on a slow download ... breaking up downloads
# speeds things up ...
apt-get -y install $XORG && apt-get -y install $AV && \
    apt-get -y install $DOC && apt-get -y install $IMAGE && \
    apt-get -y install $NET && apt-get -y install $DEV
L_sig_ok
sleep 8
}


Inst_pkg_list() {
clear
L_banner_begin "Install packages from '$PKG_LIST' list (option '-p')"
# Update dpkg database of known packages
local AVAIL
    AVAIL=$( mktemp )
apt-cache dumpavail > "$AVAIL"
dpkg --merge-avail "$AVAIL"
rm -f "$AVAIL"
# Update the dpkg selections
dpkg --set-selections < $PKG_LIST
L_sig_ok
sleep 8
# Use apt-get to install the selected packages
apt-get -y dselect-upgrade
L_sig_ok
sleep 8
}


Conf_update_alt() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
#update-alternatives --config pager
#update-alternatives --config x-terminal-emulator
L_sig_ok
sleep 8
}


Task_setup() {
# Basic setup
Inst_console_pkg
Conf_ssh
# Read the 'GRUB_EXTRAS' property from $CONFIG
local GRUB_X
    GRUB_X="$( grep -i ^GRUB_EXTRAS $CONFIG | cut -f2- -d'=' )"
if [[ $GRUB_X == 'y' ]]; then
    Conf_grub
fi
# Full setup (workstation)
if [[ $PKG_LIST == "foo" ]]; then
    Inst_desktop_pkg
else
    Inst_pkg_list
fi
Conf_update_alt
}


Run_options() {
while getopts ":hbxp:" OPT
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


#: START
Run_options "$@"
L_test_announce
sleep 4
L_test_required_file $CONFIG    # Script settings file in place?
L_test_root                     # Script run with root priviliges?
L_test_homedir $USERNAME        # $HOME exists for USERNAME?
L_test_internet                 # Internet access available?
L_test_datetime                 # Confirm date + timezone
L_test_systemd_fail             # Any failed units?
L_test_priority_err             # Identify high priority errors
# ... rollin' rollin' rollin' ...
Hello_you
L_run_script
Task_setup
clear
L_all_done
