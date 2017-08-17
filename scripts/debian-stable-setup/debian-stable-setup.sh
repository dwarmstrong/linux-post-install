#!/bin/bash
NAME="debian-stable-setup"
BLURB="Post-install setup of a machine running Debian _stable_ release"
GITHUB="https://github.com/vonbrownie"
SOURCE="$GITHUB/linux-post-install/tree/master/scripts/debian-stable-setup"
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
RELEASE="stretch"           # Debian stable release _codename_ to track
CONFIG="$(pwd)/config"      # Script settings
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
BASIC=n     # Basic setup (console only); toggle to 'y[es]' with option '-b'
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'

Hello_you() {
local HTTP0="http://www.circuidipity.com/minimal-debian.html"
local HTTP1="http://www.circuidipity.com/i3-tiling-window-manager.html"
local HTTP2="https://github.com/vonbrownie/homebin/blob/master/generatePkgList"
local HTTP3="http://www.circuidipity.com/debian-package-list.html"
L_echo_yellow "\n$( L_penguin ) .: Howdy!"
cat << _EOF_
NAME
    $NAME
SYNOPSIS
    $NAME.sh [ options ] USER
OPTIONS
    -h              print details
    -b              basic setup (console only)
    -p PKG_LIST     install packages from PKG_LIST
    -x              track unstable/_sid_ release
EXAMPLE
    $BLURB for (existing) USER 'foo' ...
        $ sudo ./$NAME.sh foo
    Install packages from 'pkg-list' ...
        $ sudo ./$NAME.sh -p pkg-list foo
DESCRIPTION
    Script '$NAME.sh' is ideally run immediately following the
    first successful boot into your new Debian installation.

    Building on a minimal install the system will be configured
    to track Debian's "$RELEASE" release. A choice of either ...

    1) a basic console setup; or
    2) a more complete setup which includes the i3 tiling window manager
    plus a packages collection suitable for a workstation; or
    3) install the same list of packages as PKG_LIST
    
    ... will be installed.

    More ...
    * "Minimal Debian" <$HTTP0>
    * "Tiling window manager" <$HTTP1>
    * "generatePkgList" <$HTTP2>
    * "Install list of Debian packages on multiple machines" <$HTTP3>
DEPENDS
    bash
SOURCE
    $SOURCE

_EOF_
}


Conf_apt_src() {
clear
L_banner_begin "Configure sources.list"
L_conf_apt_src_release $RELEASE
sleep 8
}


Conf_unattended_upgrades() {
clear
L_banner_begin "Configure automatic security updates"
local UNATTENDED_UPGRADES="/etc/apt/apt.conf.d/50unattended-upgrades"
local PERIODIC="/etc/apt/apt.conf.d/02periodic"
if [[ -f $UNATTENDED_UPGRADES ]]; then
    L_bak_file $UNATTENDED_UPGRADES
fi
if [[ -f $PERIODIC ]]; then
    L_bak_file $PERIODIC
fi
echo "Setup $UNATTENDED_UPGRADES ..."
cp "$FILE_DIR/etc/apt/apt.conf.d/50unattended-upgrades" $UNATTENDED_UPGRADES
L_sig_ok
echo "Setup $PERIODIC ..."
cp "$FILE_DIR/etc/apt/apt.conf.d/02periodic" $PERIODIC
L_sig_ok
sleep 8
}


Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local PKG_TOOLS="apt-file apt-listbugs apt-listchanges apt-show-versions 
apt-utils aptitude bsd-mailx checkinstall unattended-upgrades"
local CONSOLE="bsd-mailx cowsay cryptsetup curl dirmngr figlet git gnupg 
hdparm htop keychain less mc mlocate most neovim net-tools nmap 
openssh-server pmount resolvconf rsync rtorrent sl sudo tmux unzip wget whois"
apt-get -y install $PKG_TOOLS $CONSOLE
apt-file update
# Create the mlocate database
/etc/cron.daily/mlocate
L_sig_ok
sleep 8
}


Conf_adduser() {
adduser $USERNAME sudo
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


Conf_sudoersd() {
clear
L_banner_begin "Configure sudo"
local ALIAS="/etc/sudoers.d/00-alias"
local NOPASSWD="/etc/sudoers.d/01-nopasswd"
if [[ -f $ALIAS ]]; then
    L_bak_file $ALIAS
fi
if [[ -f $NOPASSWD ]]; then
    L_bak_file $NOPASSWD
fi
echo "Create $ALIAS ..."
cat << _EOL_ > $ALIAS
# Cmnd alias specification
Cmnd_Alias SHUTDOWN_CMDS = /sbin/poweroff, /sbin/reboot, /sbin/shutdown
_EOL_
L_sig_ok
echo "Create $NOPASSWD ..."
cat << _EOL_ > $NOPASSWD
# Allow specified users to execute these commands without password
$USERNAME ALL=(ALL) NOPASSWD: SHUTDOWN_CMDS, /bin/dmesg
_EOL_
L_sig_ok
sleep 8
}


Inst_xorg() {
clear
L_banner_begin "Install X environment"
local XORG="xorg xbacklight xbindkeys xfonts-terminus xinput 
xserver-xorg-input-synaptics xterm xvkbd fonts-liberation 
rxvt-unicode-256color"
apt-get -y install $XORG
L_sig_ok
sleep 8
}


Inst_i3wm() {
clear
L_banner_begin "Install i3 window manager"
local WM="i3 i3status i3lock dunst rofi"
apt-get -y install $WM
L_sig_ok
sleep 8
}


Inst_theme() {
clear
L_banner_begin "Install theme"
# Breeze is the default Qt style of KDE Plasma with good support for both Qt
# and GTK applications.
# More: http://www.circuidipity.com/breeze-qt-gtk.html
local THEME="breeze gtk3-engines-breeze gnome-themes-standard"
# A few independent configuration tools ...
# * qt5ct for Qt5 (pkg built from mentors.debian.net and installed separately)
# * qt4-qtconfig for Qt4
# * lxappearance for Gtk2 and Gtk3
local TOOLS="qt4-qtconfig lxappearance"
apt-get -y install $THEME $TOOLS
L_sig_ok
sleep 8
}


Inst_desktop_pkg() {
clear
L_banner_begin "Install some favourite desktop packages"
local AV="alsa-utils default-jre ffmpeg gstreamer1.0-plugins-ugly pavucontrol 
pulseaudio pulseaudio-utils rhythmbox sox vlc"
local DOC="libreoffice libreoffice-help-en-us libreoffice-gnome 
hunspell-en-ca qpdfview"
local IMAGE="eog scrot geeqie gimp gimp-help-en gimp-data-extras"
local NET="firefox-esr icedtea-plugin"
#local FLASH="flashplugin-nonfree" # Problematic ... almost never downloads
local SYS="rxvt-unicode-256color"
local DEV="autoconf automake bc build-essential devscripts fakeroot
libncurses5-dev python-dev python-pip python3-dev python3-pip 
python-pygments python3-pygments"
# Sometimes apt gets stuck on a slow download ... breaking up downloads
# speeds things up ...
apt-get -y install $AV && apt-get -y install $DOC && \
    apt-get -y install $IMAGE && apt-get -y install $NET && \
    apt-get -y install $SYS && apt-get -y install $DEV
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


Conf_terminal() {
clear
L_banner_begin "Configure terminal"
local TERM="/usr/bin/urxvt"
local TERM_TAB="/usr/lib/urxvt/perl/tabbed"
if [[ -x $TERM ]]; then
    L_bak_file $TERM_TAB
    echo "Modify $TERM_TAB ..."
    cp "$FILE_DIR/usr/lib/urxvt/perl/tabbed" $TERM_TAB
fi
L_sig_ok
sleep 8
}


Conf_update_alt() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
update-alternatives --config pager
update-alternatives --config x-terminal-emulator
L_sig_ok
sleep 8
}


Task_setup() {
# Basic setup
Conf_apt_src
Inst_console_pkg
Conf_adduser
Conf_ssh
# Read the 'UNATTENDED_UPGRADES' property from $CONFIG
local UNATTEND
    UNATTEND="$( grep -i ^UNATTENDED_UPGRADES $CONFIG | cut -f2- -d'=' )"
if [[ $UNATTEND == 'y' ]]; then
    Conf_unattended_upgrades
fi
# Read the 'GRUB_EXTRAS' property from $CONFIG
local GRUB_X
    GRUB_X="$( grep -i ^GRUB_EXTRAS $CONFIG | cut -f2- -d'=' )"
if [[ $GRUB_X == 'y' ]]; then
    Conf_grub
fi
# READ the 'SUDO_EXTRAS' property from $CONFIG
local SUDO_X
    SUDO_X="$( grep -i ^SUDO_EXTRAS $CONFIG | cut -f2- -d'=' )"
if [[ $SUDO_X == 'y' ]]; then
    Conf_sudoersd
fi
#
# Full setup (workstation)
if [[ $BASIC == "n" ]]; then
    if [[ $PKG_LIST == "foo" ]]; then
        Inst_xorg
        Inst_i3wm
        Inst_theme
        Inst_desktop_pkg
    else
        Inst_pkg_list
    fi
    Conf_terminal
    Conf_update_alt
fi
}


Run_options() {
while getopts ":hbxp:" OPT
do
    case $OPT in
        h)
            Hello_you
            exit
            ;;
        b)
            BASIC=y
            ;;
        p)
            PKG_LIST="$OPTARG"
            L_test_required_file "$PKG_LIST"
            ;;
        x)
            RELEASE="unstable"
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
