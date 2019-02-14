#!/bin/bash
NAME="debian-after-install.sh"
BLURB="Configure a device after a fresh install of Debian *Buster*"
SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/debian-after-install"
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
# shellcheck disable=SC1091
source ./Library.sh

RELEASE="buster"           # Debian release _codename_ to track
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # Setup machine for USERNAME
SLEEP="8"                   # Pause for X seconds

Hello_you() {
L_echo_yellow "\\n$( L_penguin ) .: Howdy!"
##local LINK1="https://www.circuidipity.com/debian-after-install/"
local LINK2="https://www.circuidipity.com/minimal-debian/"
local LINK3="https://www.circuidipity.com/openbox/"
local LINK4="https://www.circuidipity.com/debian-package-list/"
cat << _EOF_
NAME
    $NAME
        $BLURB
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' [1] is ideally run immediately following
    the first successful boot into a minimal install [2] of Debian "$RELEASE".

    A choice of either a [w]orkstation or [s]erver setup is available. [S]erver
    is a basic console setup, whereas the [w]orkstation choice is a more
    extensive configuration using the lightweight *Openbox* [3] window manager
    and a range of desktop applications.
    
    Alternately, in lieu of a pre-defined list of Debian packages, the user may
    specify their own custom list of packages to be installed.
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST [4]
EXAMPLES
    Run script (requires superuser privileges) ...
        # ./$NAME
    Install the list of packages specified in 'my-pkg-list' ...
        # ./$NAME -p my-pkg-list
SOURCE
    $SOURCE
SEE ALSO
    TODO
    ###[1] "Console tools: debian-after-install"
        ##LINK1
    #####
    [2] "Minimal Debian"
        $LINK2
    [3] "Roll your own Linux desktop using Openbox"
        $LINK3
    [4] "Install (almost) the same list of Debian packages on multiple machines"
        $LINK4

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

Conf_apt_sources() {
clear
L_banner_begin "Configure sources.list for '$RELEASE'"
# Add backports repository, update package list, upgrade packages."
# "Minimal Debian -- Main, non-free, contrib, and backports"
#   https://www.circuidipity.com/minimal-debian/#8-main-non-free-contrib-and-backports
local FILE="/etc/apt/sources.list"
local MIRROR="http://deb.debian.org/debian/"
local MIRROR1="http://security.debian.org/debian-security"
local COMP="main contrib non-free"
L_bak_file $FILE
cat << _EOL_ > $FILE
# Base repository
deb $MIRROR $RELEASE $COMP
deb-src $MIRROR $RELEASE $COMP

# Security updates
deb $MIRROR1 $RELEASE/updates $COMP
deb-src $MIRROR1 $RELEASE/updates $COMP

# Stable updates
#deb $MIRROR $RELEASE-updates $COMP
#deb-src $MIRROR $RELEASE-updates $COMP

# Stable backports
#deb $MIRROR $RELEASE-backports $COMP
#deb-src $MIRROR $RELEASE-backports $COMP
_EOL_
#
echo "Update packages and upgrade $HOSTNAME ..."
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
# Install ssh server and keychain
apt-get -y install openssh-server keychain
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

Conf_sudoersd() {
clear
L_banner_begin "Configure sudo"
# Add config files to /etc/sudoers.d/ to allow members of the sudo group
# extra privileges. 
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
# Allow specified users to execute these commands without password
$USERNAME ALL=(ALL) NOPASSWD: SHUTDOWN_CMDS
_EOL_
adduser $USERNAME sudo
L_sig_ok
sleep $SLEEP
}

Conf_sysctl() {
clear
L_banner_begin "Configure sysctl"
local SYSCTL="/etc/sysctl.conf"
local DMESG="kernel.dmesg_restrict"
if grep -q "$DMESG" $SYSCTL; then
    echo "Option $DMESG already set. Skipping ..."
else
    L_bak_file $SYSCTL
    # dmesg
cat << _EOL_ >> $SYSCTL

# Allow non-root access to 'dmesg' command
kernel.dmesg_restrict = 0
_EOL_
    # Reload configuration.
    sysctl -p
fi
L_sig_ok
sleep $SLEEP
}

Conf_trim() {
clear
L_banner_begin "Configure periodic trim for SSD"
# Periodic TRIM optimizes performance on SSD storage. Enable a weekly task
# that discards unused blocks on the drive.
# "Minimal Debian -- SSD"
#   https://www.circuidipity.com/minimal-debian/#11-ssd
local TIMER="fstrim.timer"
echo "Enabling timer ..."
systemctl enable $TIMER
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
if ! grep -q ^GRUB_INIT_TUNE $GRUB_DEFAULT; then
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
if ! grep -q ^GRUB_BACKGROUND $GRUB_DEFAULT; then
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

Conf_swapfile() {
clear
L_banner_begin "Configure swapfile"
# File that holds data transferred out of RAM to free up extra memory.
local SWAPFILE="/swapfile"
local SWAPSIZE="2G"
if [[ -f $SWAPFILE ]]; then
    echo "Swap file $SWAPFILE already exists. Skipping ..."
else
    echo "Create a $SWAPSIZE file to be used for swap ..."
    fallocate -l $SWAPSIZE $SWAPFILE
    # Only root should be granted read/write access.
    chmod 600 $SWAPFILE
    # Create the swap area
    mkswap $SWAPFILE
    echo "Activating $SWAPFILE ..."
    swapon $SWAPFILE
    echo ""
    swapon -s
    echo ""
    free -h
    # Make the change permanent in /etc/fstab.
    L_bak_file /etc/fstab
    echo "$SWAPFILE none swap sw 0 0" | tee -a /etc/fstab
fi
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
local PKG_TOOLS="apt-file apt-listchanges apt-show-versions apt-utils aptitude"
local CONSOLE="bsd-mailx cowsay cryptsetup git gnupg htop mlocate net-tools 
pmount rsync sl tmux unzip vrms whois"
local EDITOR="neovim python-dev python-pip python3-dev python3-pip pylint 
pylint3 shellcheck"
# shellcheck disable=SC2086
apt-get -y install $PKG_TOOLS $CONSOLE $EDITOR
apt-file update
# Create the mlocate database
/etc/cron.daily/mlocate
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

Inst_xorg() {
clear
L_banner_begin "Install X environment"
local XORG="xorg xbacklight xbindkeys xvkbd xinput xserver-xorg-input-all"
# shellcheck disable=SC2086
apt-get -y install $XORG
L_sig_ok
sleep $SLEEP
}

Inst_openbox() {
clear
L_banner_begin "Install Openbox window manager"
# "Roll your own Linux desktop using Openbox"
#   https://www.circuidipity.com/openbox/
local WM="openbox obconf menu"
local WM_EXTRA="clipit compton compton-conf dunst dbus-x11 feh hsetroot i3lock 
libnotify-bin mirage network-manager network-manager-gnome pavucontrol 
pulseaudio-utils rofi scrot tint2 volumeicon-alsa xfce4-power-manager"
# shellcheck disable=SC2086
apt-get -y install $WM $WM_EXTRA
L_sig_ok
sleep $SLEEP
}

Inst_theme() {
clear
L_banner_begin "Install theme"
local GTK="adapta-gtk-theme"
local QT="qt5-style-plugins"
local ICON="papirus-icon-theme"
local FONT="fonts-liberation2 fonts-noto fonts-roboto fonts-ubuntu"
local TOOL="lxappearance lxappearance-obconf"
# Install the *Adapta* theme for Openbox, GTK2+3, and QT.
# "Openbox -- Themes"
#   https://www.circuidipity.com/openbox/#6-themes
# shellcheck disable=SC2086 
apt-get -y install $GTK $QT $ICON $FONT $TOOL
echo "Use the *lxappearance* graphical config utility to setup your new theme"
echo "(details stored in ~/.gtkrc-2.0)."
L_sig_ok
sleep $SLEEP
}

Inst_nonpkg_firefox() {
clear
L_banner_begin "Install Firefox"
# Install the latest Firefox Stable. Create ~/opt directory to store
# programs in $HOME. Download and unpack the latest binaries from
# official website, and create a link to the executable in my PATH.
local DIR="/home/$USERNAME/opt"
local FF_EXE="FirefoxSetup.exe"
local FF_TAR="firefox.tar.bz2"
local FF_SRC="https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
local LINK="/usr/local/bin/firefox"
if [[ -a $LINK ]]; then
    echo "$LINK already exists. Skipping ..."
else
    # shellcheck disable=SC2086
    wget -c -O $FF_EXE $FF_SRC 
    if [[ -d $DIR ]]; then
        echo "$DIR already exists. Skipping ..."
    else
        echo "Create $DIR ..."
        mkdir $DIR
        chown ${USERNAME}:${USERNAME} $DIR
        mv $FF_EXE $FF_TAR
        tar xvf $FF_TAR -C $DIR
        echo "Create symbolic link $LINK to firefox installed in $DIR ..."
        ln -s $DIR/firefox/firefox $LINK
    fi
fi
L_sig_ok
sleep $SLEEP
}

Inst_workstation_pkg() {
clear
L_banner_begin "Install some favourite workstation packages"
local AV="alsa-utils default-jre ffmpeg gstreamer1.0-plugins-ugly pavucontrol 
pulseaudio pulseaudio-utils rhythmbox sox vlc"
local DOC="libreoffice libreoffice-help-en-us libreoffice-gnome 
hunspell-en-ca qpdfview"
local IMAGE="mirage scrot geeqie gimp gimp-help-en gimp-data-extras"
local NET="chromium network-manager-gnome transmission-gtk"
local SYS="dunst rofi rxvt-unicode"
local DEV="autoconf automake bc build-essential devscripts fakeroot 
libncurses5-dev python-dev python-pip python3-dev python3-pip 
python-pygments python3-pygments"
# Sometimes apt gets stuck on a slow download ... breaking up downloads
# speeds things up ...
# shellcheck disable=SC2086
apt-get -y install $AV && apt-get -y install $DOC && \
    apt-get -y install $IMAGE && apt-get -y install $NET && \
    apt-get -y install $SYS && apt-get -y install $DEV
# Virtualbox - more: https://www.circuidipity.com/virtualbox-debian-stretch/
local KERNEL
KERNEL=$(uname -r)
local VB_DEP="dkms module-assistant linux-headers-$KERNEL"
# shellcheck disable=SC2086
apt-get -y install $VB_DEP
apt-get -y install virtualbox
adduser $USERNAME vboxusers
# Remove packages ...
local REMOVE="firefox-esr"
apt-get -y --purge remove $REMOVE
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
    cp "$FILE_DIR/usr/lib/x86_64-linux-gnu/urxvt/perl/tabbed" $TERM_TAB
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
local NUM_Q="6"
local PROFILE="foo"
local SSD="foo"
local GRUB_X="foo"
local SWAPFILE="foo"
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
        echo "Periodic TRIM optimizes performance on solid-state storage. If"
        echo "this machine has an SSD drive, you should enable this task."
        echo ""; read -r -n 1 -p "Enable a weekly task that discards unused blocks on this drive? [Yn] > "
        if [[ $REPLY == [nN] ]]; then
            SSD="no"
            break
        elif [[ $REPLY == [yY] || $REPLY == "" ]]; then
            SSD="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 4 of $NUM_Q"
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
    L_banner_begin "Question 5 of $NUM_Q"
    while :
    do
        echo "If not using a swap partition, creating a swap file is recommended."
        echo "This allows data to be transferred out of RAM to free up extra memory."
        echo ""; read -r -n 1 -p "Create a 2GB swapfile? [Yn] > "
        if [[ $REPLY == [nN] ]]; then
            SWAPFILE="no"
            break
        elif [[ $REPLY == [yY] || $REPLY == "" ]]; then
            SWAPFILE="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 6 of $NUM_Q"
    L_echo_purple "Username: $USERNAME"
    L_echo_purple "Profile: $PROFILE"
    if [[ $SSD == "yes" ]]; then
        L_echo_green "SSD: $SSD"
    else
        L_echo_red "SSD: $SSD"
    fi
    if [[ $GRUB_X == "yes" ]]; then
        L_echo_green "Custom GRUB: $GRUB_X"
    else
        L_echo_red "Custom GRUB: $GRUB_X"
    fi
    if [[ $SWAPFILE == "yes" ]]; then
        L_echo_green "Swap File: $SWAPFILE"
    else
        L_echo_red "Swap File: $SWAPFILE"
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
        echo -e "\\nOK ... Let's try again ..."
        sleep 4
    else
        L_invalid_reply_yn
        sleep 4
    fi
done
# Common tasks
Conf_apt_sources
Conf_sudoersd
Conf_ssh
Conf_sysctl
# Periodic trim
if [[ $SSD == "yes" ]]; then
    Conf_trim
fi
# Custon grub
if [[ $GRUB_X == "yes" ]]; then
    Conf_grub
fi
# Swap file
if [[ $SWAPFILE == "yes" ]]; then
    Conf_swapfile
fi
# Workstation setup
if [[ $PROFILE == "workstation" ]]; then
    if [[ $PKG_LIST != "foo" ]]; then
        Inst_pkg_list
    else
        Inst_console_pkg
        Inst_xorg
        Inst_openbox
        Inst_theme
        Inst_nonpkg_firefox
        Inst_workstation_pkg
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
