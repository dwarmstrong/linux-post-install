#!/bin/bash
NAME="debian-stable-setup.sh"
BLURB="Setup a machine running the Debian _stable_ release"
SOURCE="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/debian-stable-setup"
set -eu

# Copyright (c) 2018 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

# Import some helpful functions, prefixed 'L_'
source ./Library.sh

RELEASE="stretch"           # Debian stable release _codename_ to track
FILE_DIR="$(pwd)/files"     # Directory tree contents to be copied to machine
PKG_LIST="foo"  # Install packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # Setup machine for USERNAME

What_do() {
L_echo_yellow "\n$( L_penguin ) .: Howdy!"
local LINK0="https://www.circuidipity.com/debian-stable-setup/"
local LINK1="https://www.circuidipity.com/minimal-debian/"
local LINK2="https://www.circuidipity.com/debian-package-list/"
local LINK3="https://www.circuidipity.com/openbox/"
local LINK4="https://www.circuidipity.com/laptop-home-server/"
cat << _EOF_
NAME
    $NAME
        $BLURB
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' is ideally run immediately following the first successful
    boot into a fresh install of Debian's "$RELEASE" release.

    A choice of either a [desktop] or [server] setup will be configured.
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST
EXAMPLES
    Run script (requires superuser privileges) ...
        # ./$NAME
    Install the list of packages specified in 'my-pkg-list' ...
        # ./$NAME -p my-pkg-list foo
SOURCE
    $SOURCE
SEE ALSO
    * "Command line tools: debian-stable-setup"
        $LINK0
    * "Minimal Debian"
        $LINK1
    * "Install (almost) the same list of Debian packages on multiple machines"
        $LINK2
    * "Roll your own Linux desktop using Openbox"
        $LINK3
    * "New life for an old laptop as a Linux home server"
        $LINK4

_EOF_
}

Run_options() {
while getopts ":hp:" OPT
do
    case $OPT in
        h)
            What_do_you_do
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

Conf_apt_src() {
clear
L_banner_begin "Configure sources.list for '$RELEASE'"
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
deb $MIRROR $RELEASE-updates $COMP
deb-src $MIRROR $RELEASE-updates $COMP

# Stable backports
deb $MIRROR $RELEASE-backports $COMP
deb-src $MIRROR $RELEASE-backports $COMP
_EOL_
echo "Update packages and upgrade $HOSTNAME ..."
apt-get update && apt-get -y dist-upgrade
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

Conf_sudoersd() {
clear
L_banner_begin "Configure sudo"
# Add config files to /etc/sudoers.d/ to allow members of the sudo group
# extra privileges; the ability to shutdown/reboot the system and read 
# the kernel buffer using `dmesg` without a password for example.
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
adduser $USERNAME sudo
L_sig_ok
sleep 8
}

Conf_trim() {
clear
L_banner_begin "Configure periodic trim for SSD"
local TRIM="/etc/cron.weekly/trim"
# Enable periodic TRIM on SSD drives. Create a weekly TRIM job.
if [[ -f $TRIM ]]; then
    echo "Weekly trim job $TRIM already exists. Skipping ..."
else
cat << _EOL_ > $TRIM
#!/bin/sh
# trim all mounted file systems which support it
/usr/bin/fstrim --all
_EOL_
chmod 755 $TRIM
#/etc/cron.weekly/trim                # check the program runs without errors
#run-parts --test /etc/cron.weekly    # checks that cron can run the script
#    /etc/cron.weekly/trim
fi
L_sig_ok
sleep 8
}

Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
# Add a bit of colour, a bit of sound, and wallpaper!
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

Conf_unattended_upgrades() {
clear
L_banner_begin "Configure automatic security updates"
# Install security updates automatically courtesy of `unattended-upgrades`
# package with options set in /etc/apt/apt.conf.d/50unattended-upgrades.
#
# Activate tracking with details provided in /etc/apt/apt.conf.d/02periodic.
# 
# Upgrade information is logged under /var/log/unattended-upgrades.
#
# See: "Automatic security updates on Debian"
#       https://www.circuidipity.com/unattended-upgrades/
local UNATTENDED_UPGRADES="/etc/apt/apt.conf.d/50unattended-upgrades"
local PERIODIC="/etc/apt/apt.conf.d/02periodic"
if [[ -f $UNATTENDED_UPGRADES ]]; then
    L_bak_file $UNATTENDED_UPGRADES
fi
if [[ -f $PERIODIC ]]; then
    L_bak_file $PERIODIC
fi
apt-get -y install unattended-upgrades
echo "Setup $UNATTENDED_UPGRADES ..."
cp "$FILE_DIR/etc/apt/apt.conf.d/50unattended-upgrades" $UNATTENDED_UPGRADES
L_sig_ok
echo "Setup $PERIODIC ..."
cp "$FILE_DIR/etc/apt/apt.conf.d/02periodic" $PERIODIC
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
dpkg --set-selections < "$PKG_LIST"
L_sig_ok
sleep 8
# Use apt-get to install the selected packages
apt-get -y dselect-upgrade
L_sig_ok
sleep 8
}

Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local PKG_TOOLS="apt-file apt-listchanges apt-show-versions apt-utils aptitude 
bsd-mailx"
local CONSOLE="bsd-mailx cowsay cryptsetup git gnupg gpm hdparm htop keychain
less mlocate net-tools nmap openssh-server pmount resolvconf rsync sl sudo 
tmux unzip wget whois"
local EDITOR="neovim python-dev python-pip python3-dev python3-pip pylint 
pylint3 shellcheck"
apt-get -y install "$PKG_TOOLS $CONSOLE $EDITOR"
apt-file update
# Create the mlocate database
/etc/cron.daily/mlocate
L_sig_ok
sleep 8
}

Inst_server_pkg() {
clear
L_banner_begin "Install server packages"
local PKG="fail2ban logwatch"
apt-get -y install "$PKG"
L_sig_ok
sleep 8
}

Inst_xorg() {
clear
L_banner_begin "Install X environment"
local XORG="xorg xbacklight xbindkeys xfonts-terminus xinput 
xserver-xorg-input-all xterm xvkbd fonts-liberation rxvt-unicode-256color"
apt-get -y install "$XORG"
L_sig_ok
sleep 8
}


Inst_openbox() {
clear
L_banner_begin "Install Openbox window manager"
local WM="openbox obconf menu"
local WM_HELP="scrot mirage rofi xfce4-power-manager feh compton compton-conf 
xbindkeys x11-xserver-utils dunst dbus-x11 libnotify-bin tint2 clipit 
pulseaudio-utils volumeicon-alsa pavucontrol network-manager 
network-manager-gnome i3lock"
apt-get -y install "$WM $WM_HELP"
L_sig_ok
sleep 8
}

Inst_theme() {
clear
L_banner_begin "Install theme"
local GTK="arc-theme"
local OB="https://github.com/dglava/arc-openbox.git"
local QT="qt5-style-plugins"
local ICON="papirus-icon-theme"
local ICON_SRC="https://raw.githubusercontent.com/PapirusDevelopmentTeam/$ICON/master/install.sh"
local FONT="fonts-liberation fonts-noto-mono"
local FONT_UB="fonts-ubuntu_0.83-4_all.deb"
local FONT_UB_SRC="http://ftp.us.debian.org/debian/pool/non-free/f/fonts-ubuntu/$FONT_UB"
local TOOL="lxappearance lxappearance-obconf"
# GTK2+3
apt-get -y install "$GTK"
# Openbox
mkdir ~/.themes
cd ~/.themes
git clone $OB
# QT
apt-get -y install $QT
# I like the "Papirus" icon set. Install in `~/.icons` ...
mkdir ~/.icons
wget -qO- $ICON_SRC | DESTDIR="$HOME/.icons" sh
# Install a few extra fonts (including the nice **Ubuntu** fonts) ...
apt-get -y install $FONT
wget -c $FONT_UB_SRC
dpkg -i $FONT_UB
# Use the **lxappearance** graphical config utility (with the extra openbox plugin) to setup your new theme (details stored in `~/.gtkrc-2.0`). Install ...
apt-get -y install $TOOL
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
local IMAGE="mirage scrot geeqie gimp gimp-help-en gimp-data-extras"
local NET="network-manager-gnome transmission-qt"
#local FLASH="flashplugin-nonfree" # Problematic ... almost never downloads
local SYS="rxvt-unicode-256color"
local DEV="autoconf automake bc build-essential devscripts fakeroot
libncurses5-dev python-dev python-pip python3-dev python3-pip 
python-pygments python3-pygments"
# Sometimes apt gets stuck on a slow download ... breaking up downloads
# speeds things up ...
apt-get -y install "$AV" && apt-get -y install "$DOC" && \
    apt-get -y install "$IMAGE" && apt-get -y install "$NET" && \
    apt-get -y install "$SYS" && apt-get -y install "$DEV"
# Third-party packages
#
# Firefox - fetch the latest version ...
#wget -c -O firefox-latest.tar.bz2 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
# ... and - post-script - unpack tarball, install somewhere in ~/,
# and create symlink in /usr/local/bin.
L_sig_ok
sleep 8
}

Inst_nonpkg_firefox() {
clear
L_banner_begin "Install Firefox"
# Install the latest Firefox Stable on Debian Stretch.
# Create ~/opt directory to store programs in $HOME. Download and unpack the 
# latest binaries from the official website, and create a link to the
# executable in my PATH
wget -c -O FirefoxSetup.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
tar xvf FirefoxSetup.tar.bz2 -C ~/opt/
ln -s ~/opt/firefox/firefox /usr/local/bin/
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

Conf_alt_workstation() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
update-alternatives --config x-terminal-emulator
L_sig_ok
sleep 8
}

Conf_alt_server() {
clear
L_banner_begin "Configure default commands"
update-alternatives --config editor
L_sig_ok
sleep 8
}

Goto_work() {
clear
local NUM_Q="4"
local PROFILE="foo"
local SSD="foo"
L_banner_begin "Question 1 of $NUM_Q"
# What is your username?
L_test_homedir $USERNAME        # $HOME exists for USERNAME?
clear
L_banner_begin "Question 2 of $NUM_Q"
# Are you configuring a workstation or server?
clear
L_banner_begin "Question 3 of $NUM_Q"
# Setup trim on ssd?
clear
L_banner_begin "Question 4 of $NUM_Q"
# Username: $USERNAME
# Profile: $PROFILE
# SSD: $SSD
# Is this correct? [Yes|No|Quit]
Conf_apt_src
Conf_ssh
Conf_sudoersd
# if trim yes
#   Conf_trim
# if workstation
#   Conf_grub
#   if pkglist
#       Inst_pkg_list
#   else
#       Inst_console_pkg
#       Inst_xorg
#       Inst_openbox
#       Inst_theme
#       Inst_desktop_pkg
#       Inst_nonpkg_firefox
#       Conf_terminal
#       Conf_alt_workstation
#
# if server
#   Conf_unattended_upgrades
#   if pkglist
#       Inst_pkg_list
#   else
#       Inst_console_pkg
#       Inst_server_pkg
#       Conf_alt_server
}

#: START
Run_options "$@"
L_test_announce
sleep 4
L_test_required_file "$CONFIG"    # Script settings file in place?
L_test_root                     # Script run with root priviliges?
L_test_internet                 # Internet access available?
L_test_datetime                 # Confirm date + timezone
L_test_systemd_fail             # Any failed units?
L_test_priority_err             # Identify high priority errors
# ... rollin' rollin' rollin' ...
What_do
L_run_script
Goto_work
clear
L_all_done
