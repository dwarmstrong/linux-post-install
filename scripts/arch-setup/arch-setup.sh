#!/bin/bash
NAME="arch-setup.sh"
BLURB="Post-install setup of a machine running Arch Linux"
SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/arch-setup"
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
CONFIG="$(pwd)/config"      # Script settings
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
BASIC=n     # Basic setup (console only); toggle to 'y[es]' with option '-b'
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'

Hello_you() {
local HTTP0="http://www.circuidipity.com/i3-tiling-window-manager.html"
local HTTP1="TODO"
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
EXAMPLE
    $BLURB for USER 'foo' ...
        $ sudo ./$NAME foo
    Install packages from 'pkg-list' ...
        $ sudo ./$NAME -p pkg-list foo
DESCRIPTION
    Script '$NAME' is ideally run immediately following the
    first successful boot into your new Arch Linux installation.

    Building on a minimal install, the system will be configured
    with a choice of either ...

    1) a basic console setup; or
    2) a more complete setup which includes the i3 tiling window manager
    plus a packages collection suitable for a workstation; or
    3) install the same list of packages as PKG_LIST
    
    ... will be installed.

    More ...
    * "Tiling window manager" <$HTTP0>
    * "Install list of Arch packages on multiple machines" <$HTTP1>
DEPENDS
    bash
SOURCE
    $SOURCE

_EOF_
}


Inst_upgrade() {
clear
L_banner_begin "Upgrade to latest packages"
pacman --noconfirm -Syu
L_sig_ok
sleep 8
}


Conf_adduser() {
clear
L_banner_begin "Create user account for $USERNAME"
local ACCT_OPTS="-m -G wheel -s /bin/bash"
if [[ -d "/home/$USERNAME" ]]; then
    echo "Username '$USERNAME' exists. Skipping ..."
else
    useradd $ACCT_OPTS $USERNAME
    echo "useradd $ACCT_OPTS $USERNAME"
    passwd $USERNAME
fi
L_sig_ok
sleep 8
}


Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local CONSOLE="cowsay cryptsetup git gnupg htop keychain neovim openssh 
python-pip python2-pip python-pylint python2-pylint 
rsync shellcheck sl tmux wget whois"
pacman --needed --noconfirm -S $CONSOLE
pacman --needed --noconfirm -S mlocate && updatedb   # Create the mlocate database
L_sig_ok
sleep 8
}


Conf_ssh() {
clear
L_banner_begin "Create SSH directory for $USERNAME"
local SSH_DIR="/home/$USERNAME/.ssh"
local AUTH_KEY="$SSH_DIR/authorized_keys"
if [[ -d $SSH_DIR ]]; then
    echo "SSH directory $SSH_DIR exists. Skipping ..."
else
    echo "Create $SSH_DIR and set permissions ..."
    mkdir $SSH_DIR && chmod 700 $SSH_DIR && \
    touch $AUTH_KEY && chmod 600 $AUTH_KEY && \
    chown -R "$USERNAME:$USERNAME" $SSH_DIR
fi
systemctl enable sshd.service
L_sig_ok
sleep 8
}


Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
local GRUB_DEFAULT="/etc/default/grub"
local WALLPAPER="/boot/grub/wallpaper-grub.tga"
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
        
# Wallpaper + menu colours
GRUB_BACKGROUND="$WALLPAPER"
GRUB_COLOR_NORMAL="white/black"          
GRUB_COLOR_HIGHLIGHT="white/blue"
_EOL_
    if [[ -f $WALLPAPER ]]; then
        L_bak_file $WALLPAPER
    fi
    cp "$FILE_DIR/boot/grub/wallpaper-grub.tga" $WALLPAPER
    L_sig_ok
else
    echo "Grub already includes wallpaper and colour. Skipping ..."
    L_sig_ok
fi
grub-mkconfig -o /boot/grub/grub.cfg
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
Cmnd_Alias SHUTDOWN_CMDS = /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/shutdown
_EOL_
L_sig_ok
echo "Create $NOPASSWD ..."
cat << _EOL_ > $NOPASSWD
# Allow specified users to execute these commands without password
$USERNAME ALL=(ALL) NOPASSWD: SHUTDOWN_CMDS, /usr/bin/dmesg
_EOL_
L_sig_ok
sleep 8
}


Conf_issue() {
clear
L_banner_begin "Configure issue"
local ISSUE="/etc/issue"
if [[ -f $ISSUE ]]; then
    L_bak_file $ISSUE
fi
echo "Customize $ISSUE ..."
cp "$FILE_DIR/etc/issue" $ISSUE
L_sig_ok
sleep 8
}


Inst_xorg() {
clear
L_banner_begin "Install X environment"
local XORG="xbindkeys xf86-input-libinput xorg-xbacklight xorg-xinit 
xorg-xinput xorg-xset xterm xvkbd rxvt-unicode gtk2-perl"
local FONTS="terminus-font ttf-dejavu ttf-liberation"
pacman --needed --noconfirm -S xorg-server
# Note: ">>> xorg-server has now the ability to run without root rights with
# the help of systemd-logind. xserver will fail to run if not launched from
# the same virtual terminal as was used to log in.
# Without root rights, log files will be in ~/.local/share/xorg/ directory.
if [[ $(lspci -v | grep VGA | grep Intel) ]]; then
    pacman --needed --noconfirm -S xf86-video-intel  # install video driver
fi
pacman --needed --noconfirm -S $XORG $FONTS
pacman --needed --noconfirm -S xf86-input-synaptics # Touchpad
# Note: ">>> xf86-input-synaptics driver is on maintenance mode and
# xf86-input-libinput driver must be prefered over." However, on my
# Acer C720 Chromebook I have a perfectly good config that works in
# /etc/X11/xorg.conf.d/50-c720-touchpad.conf so synaptics it is for
# the present time.
L_sig_ok
sleep 8
}


Inst_i3wm() {
clear
L_banner_begin "Install i3 window manager"
local WM="i3-wm i3status i3lock dunst rofi"
pacman --needed --noconfirm -S $WM
L_sig_ok
sleep 8
}


Inst_theme() {
clear
L_banner_begin "Install theme"
# Breeze is the default Qt style of KDE Plasma with good support for both Qt
# and GTK applications.
# More: http://www.circuidipity.com/breeze-qt-gtk.html
local THEME="breeze breeze-gtk breeze-icons breeze-kde4"
# A few configuration tools ...
# qt5ct for Qt5 (available in AUR)
# qt4-qtconfig for Qt4 (qt4)
# lxappearance for Gtk2 and Gtk3
local TOOLS="lxappearance qt4"
pacman --needed --noconfirm -S $THEME $TOOLS
# Run each config tool for its respective environment. Settings are
# saved to ...
# ~/.config/qt5ct/qt5ct.conf for Qt5
# ~/.config/Trolltech.conf for Qt4
# ~/.config/gtk-3.0/settings.ini for Gtk3
# ~/.gtkrc-2.0 for Gtk2
L_sig_ok
sleep 8
}


Inst_desktop_pkg() {
clear
L_banner_begin "Install some favourite desktop packages"
local SND="alsa-utils pulseaudio pamixer pavucontrol"
# Volume control in i3
# Link: https://i3wm.org/i3status/manpage.html#_volume
# Set multimedia keys in `xbindkeys` and controls in `i3status.conf`.
local AV="ffmpeg gst-libav gst-plugins-ugly rhythmbox vlc"
local DOC="libreoffice-fresh" 
local IMG="eog fbida geeqie gimp gimp-help-en imagemagick scrot"
local NET="firefox flashplugin icedtea-web transmission-qt weechat"
local DEV="intltool subversion"
pacman --needed --noconfirm -S $SND $AV $DOC $IMG $NET $DEV
L_sig_ok
sleep 8
}


Inst_netmanager() {
clear
L_banner_begin "Install Network Manager"
local NETMAN="networkmanager network-manager-applet gnome-keyring polkit"
pacman --needed --noconfirm -S $NETMAN
systemctl enable NetworkManager.service
# If launching X courtesy of 'startx' - and desire to use nm-applet - start the
# gnome-keyring by adding to  ~/.xinitrc ...
#
# eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
# export SSH_AUTH_SOCK
L_sig_ok
sleep 8
}


Inst_pkg_list() {
clear
L_banner_begin "Install packages from '$PKG_LIST' list (option '-p')"
# TODO
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


Task_setup() {
# --------[ Basic setup ]---------------------------------------------------- #
Inst_upgrade
Conf_adduser
Inst_console_pkg
Conf_ssh
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
# READ the 'ISSUE_CUSTOM' property from $CONFIG
local ISSUE_CUST
    ISSUE_CUST="$( grep -i ^ISSUE_CUSTOM $CONFIG | cut -f2- -d'=' )"
if [[ $ISSUE_CUST == 'y' ]]; then
    Conf_issue
fi
# --------[ Full setup (workstation) ]--------------------------------------- #
if [[ $BASIC == "n" ]]; then
    if [[ $PKG_LIST == "foo" ]]; then
        Inst_xorg
        Inst_i3wm
        Inst_theme
        Inst_desktop_pkg
        # READ the 'NETMAN_INSTALL' property from $CONFIG
        local NETMAN_INST
            NETMAN_INST="$( grep -i ^NETMAN_INSTALL $CONFIG | cut -f2- -d'=' )"
        if [[ $NETMAN_INST == 'y' ]]; then
            Inst_netmanager
        fi
    else
        Inst_pkg_list
    fi
    Conf_terminal
fi
}


Run_options() {
while getopts ":hbp:" OPT
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
#L_test_homedir $USERNAME        # $HOME exists for USERNAME?
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
