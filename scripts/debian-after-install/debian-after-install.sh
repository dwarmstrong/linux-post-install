#!/bin/bash
NAME="debian-after-install.sh"
BLURB="Configure a device after a fresh install of Debian's _testing_ release"
SRC_DIR="https://github.com/vonbrownie/linux-post-install"
SOURCE="${SRC_DIR}/tree/master/scripts/debian-after-install"
set -eu

# Copyright (c) 2019 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

RELEASE="buster"           # Debian release _codename_ to track
SRC_RAW="https://raw.githubusercontent.com/vonbrownie/linux-post-install"
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
        $BLURB
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' is ideally run after the first successful
    boot into a minimal install of Debian's _testing_ aka "$RELEASE" release.

    A choice of either [w]orkstation or [s]erver setup is available. [S]erver
    is a basic console setup, whereas [w]orkstation is a more complete setup
    using Xorg and the lightweight _Openbox_ window manager plus a range
    of desktop applications.
    
    Alternately, in lieu of a pre-defined list of Debian packages, the user may
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
    * More Debian: debian-after-install
        ${LINK}/debian-after-install/
    * Minimal Debian
        ${LINK}/minimal-debian/
    * Roll your own Linux desktop using Openbox
        ${LINK}/openbox/
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

Conf_keyboard() {
clear
L_banner_begin "Configure keyboard"
echo "Choose a different keymap ..."
sleep 4
dpkg-reconfigure keyboard-configuration
setupcon
cat /etc/default/keyboard
L_sig_ok
sleep $SLEEP
}

Conf_consolefont() {
clear
L_banner_begin "Configure console font"
echo "Choose a different font for the console ..."
sleep 4
dpkg-reconfigure console-setup
cat /etc/default/console-setup
L_sig_ok
sleep $SLEEP
}

Conf_apt_sources() {
clear
L_banner_begin "Configure sources.list for '$RELEASE'"
# Add backports repository, update package list, upgrade packages.
local FILE="/etc/apt/sources.list"
local MIRROR="http://deb.debian.org/debian/"
local MIRROR1="http://security.debian.org/debian-security"
local COMP="main contrib non-free"
# Backup previous config
L_bak_file $FILE
# Create a new config
cat << _EOL_ > $FILE
# Base repository
deb $MIRROR $RELEASE $COMP
deb-src $MIRROR $RELEASE $COMP

# Security updates
deb $MIRROR1 ${RELEASE}/updates $COMP
deb-src $MIRROR1 ${RELEASE}/updates $COMP

# Stable updates
#deb $MIRROR ${RELEASE}-updates $COMP
#deb-src $MIRROR ${RELEASE}-updates $COMP

# Stable backports
#deb $MIRROR ${RELEASE}-backports $COMP
#deb-src $MIRROR ${RELEASE}-backports $COMP
_EOL_
# Update/upgrade
echo "Update list of packages available and upgrade $HOSTNAME ..."
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

Conf_sudoersd() {
clear
L_banner_begin "Configure sudo"
# Add config files to /etc/sudoers.d/ to allow members of the sudo group
# extra privileges. 
local ALIAS="/etc/sudoers.d/00-alias"
local NOPASSWD="/etc/sudoers.d/01-nopasswd"
local OFF="/usr/bin/systemctl poweroff"
local REBOOT="/usr/bin/systemctl reboot"
local SUSPEND="/usr/bin/systemctl suspend"
apt-get -y install sudo
if [[ -f "$ALIAS" ]]; then
    echo "$ALIAS already exists. Skipping ..."
else
    cat << _EOL_ > $ALIAS
User_Alias ADMIN = $USERNAME
Cmnd_Alias SYS_CMDS = $OFF, $REBOOT, $SUSPEND
_EOL_
fi
if [[ -f "$NOPASSWD" ]]; then
    echo "$NOPASSWD already exists. Skipping ..."
else
    cat << _EOL_ > $NOPASSWD
# Allow specified users to execute these commands without password
ADMIN ALL=(ALL) NOPASSWD: SYS_CMDS
_EOL_
fi
adduser $USERNAME sudo
L_sig_ok
sleep $SLEEP
}

Conf_sysctl() {
clear
L_banner_begin "Configure sysctl"
local SYSCTL="/etc/sysctl.conf"
local DMESG="kernel.dmesg_restrict"
if grep -q "$DMESG" "$SYSCTL"; then
    echo "Option $DMESG already set. Skipping ..."
else
    L_bak_file $SYSCTL
    cat << _EOL_ >> $SYSCTL

# Allow non-root access to dmesg
$DMESG = 0
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

Conf_swapfile() {
clear
L_banner_begin "Configure swapfile"
# File that holds data transferred out of RAM to free up extra memory.
local SWAPFILE="/swapfile"
local SWAPSIZE="2G"
if [[ -f "$SWAPFILE" ]]; then
    echo "Swap file $SWAPFILE already exists. Skipping ..."
else
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

Conf_unattend_upgrade() {
clear 
L_banner_begin "Install unattend-upgrades"
# Install security updates automatically courtesy of `unattended-upgrades`
# package with options set in /etc/apt/apt.conf.d/50unattended-upgrades.
#
# Activate tracking with details provided in /etc/apt/apt.conf.d/02periodic.
# 
# Upgrade information is logged under /var/log/unattended-upgrades.
#
# See: "Automatic security updates on Debian"
#       https://www.circuidipity.com/unattended-upgrades.html
local PKG="unattended-upgrades"
local PERIODIC="/etc/apt/apt.conf.d/02periodic"
local UPGRADE="/etc/apt/apt.conf.d/50unattended-upgrades"
local DWNLD="${SRC_RAW}/master/config/etc/apt/apt.conf.d/02periodic"
local DWNLD2="${SRC_RAW}/master/config/etc/apt/apt.conf.d/50unattended-upgrades"
apt-get -y install $PKG
if [[ -f "$PERIODIC" ]]; then
    echo "$PERIODIC already exists. Skipping ..."
else
    wget -c $DWNLD -O $PERIODIC
fi
if [[ -f "$UPGRADE" ]]; then
    echo "$UPGRADE already exists. Skipping .."
else
    wget -c $DWNLD2 -O $UPGRADE
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
echo ""
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
local CONSOLE="bsd-mailx cowsay cryptsetup curl git gnupg htop mlocate net-tools 
pmount rsync sl tmux unzip vrms wget whois"
local EDITOR="neovim shellcheck"
# shellcheck disable=SC2086
apt-get -y install $PKG_TOOLS $CONSOLE $EDITOR
apt-file update && update-command-not-found
# Create the mlocate database
/etc/cron.daily/mlocate
# Train kept a rollin' ...
if [[ -x "/usr/games/sl" ]]; then
    /usr/games/sl
fi
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
local FONT="fonts-dejavu fonts-liberation2 fonts-ubuntu"
# shellcheck disable=SC2086
apt-get -y install $XORG $FONT
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
libnotify-bin network-manager network-manager-gnome pavucontrol pulseaudio 
pulseaudio-utils rofi scrot tint2 viewnior volumeicon-alsa xfce4-power-manager"
# shellcheck disable=SC2086
apt-get -y install $WM $WM_EXTRA
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

Inst_nonpkg_firefox() {
clear
L_banner_begin "Install Firefox"
# Install the latest Firefox Stable. Create ~/opt directory to store
# programs in $HOME. Download and unpack the latest binaries from
# official website, and create a link to the executable in my PATH.
local DIR="/home/${USERNAME}/opt"
local FF_EXE="FirefoxSetup.exe"
local FF_TAR="firefox.tar.bz2"
local FF_SRC="https://download.mozilla.org"
local DWNLD="${FF_SRC}/?product=firefox-latest&os=linux64&lang=en-US"
local LINK="/usr/local/bin/firefox"
if [[ -a "$LINK" ]]; then
    echo "$LINK already exists. Skipping ..."
else
    # shellcheck disable=SC2086
    wget -c -O $FF_EXE $FF_SRC 
    if [[ -d "$DIR" ]]; then
        echo "$DIR already exists. Skipping ..."
    else
        echo "Create $DIR ..."
        mkdir $DIR
        mv $FF_EXE $FF_TAR
        tar xvf $FF_TAR -C $DIR
        chown -R ${USERNAME}:${USERNAME} $DIR
        echo "Create symbolic link $LINK to firefox installed in $DIR ..."
        ln -s ${DIR}/firefox/firefox $LINK
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
local DOC="libreoffice libreoffice-help-en-us libreoffice-gnome hunspell-en-ca 
qpdfview"
local IMAGE="scrot viewnior geeqie gimp gimp-help-en gimp-data-extras"
local NET="firefox-esr network-manager-gnome newsboat transmission-gtk"
local SYS="dunst rofi rxvt-unicode"
local DEV="build-essential dkms libncurses5-dev linux-headers-amd64 
module-assistant python3-dev python3-pip python3-pygments"
# Sometimes apt gets stuck on a slow download. Breaking up downloads tends to
# speeds things up.
# shellcheck disable=SC2086
apt-get -y install $AV && apt-get -y install $DOC && \
apt-get -y install $IMAGE && apt-get -y install $NET && \
apt-get -y install $SYS && apt-get -y install $DEV
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
local NUM="9"
local PROFILE="foo"
local AUTO="foo"
local KEY="foo"
local FONT="foo"
local SSD="foo"
local GRUB_X="foo"
local SWAPFILE="foo"
while :
do
    clear
    L_banner_begin "Question 1 of $NUM"
    read -r -p "What is your non-root username? > " FOO; USERNAME="$FOO"
    L_test_homedir "$USERNAME"        # $HOME exists for USERNAME?
    clear
    L_banner_begin "Question 2 of $NUM"
    while :
    do
        read -r -n 1 -p "Are you configuring a [w]orkstation or [s]erver? > "
        if [[ "$REPLY" == [wW] ]]; then
            PROFILE="workstation"
             break
        elif [[ "$REPLY" == [sS] ]]; then
            PROFILE="server"
            break
        else
            L_invalid_reply
        fi
    done
	clear
	L_banner_begin "Question 3 of $NUM"
	while :
	do
		echo "Fetch and install the latest security fixes courtesy of package"
		echo -e "_unattended-upgrades_. Useful especially on servers.\\n"
		read -r -n 1 -p "Install security updates automatically? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            AUTO="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            AUTO="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
	clear
	L_banner_begin "Question 4 of $NUM"
	while :
	do
		echo "Change the model of keyboard and/or the keyboard map. Example:"
        echo -e "from QWERTY to Colemak, or for non-English layouts.\\n"
		read -r -n 1 -p "Setup a different keyboard configuration? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            KEY="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            KEY="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
	clear
	L_banner_begin "Question 5 of $NUM"
	while :
	do
		echo "Change the font or font-size used in the console. Example:"
        echo -e "TERMINUS font in size 8x16 (default) or 10x20.\\n"
		read -r -n 1 -p "Setup a different console font? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            FONT="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            FONT="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 6 of $NUM"
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
    L_banner_begin "Question 7 of $NUM"
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
    L_banner_begin "Question 8 of $NUM"
    while :
    do
        echo "If not using a swap partition, creating a *swapfile* is a good"
		echo "idea. This allows data to be transferred out of RAM to free up"
		echo -e "extra memory.\\n"
		read -r -n 1 -p "Create a 2GB swapfile? [Yn] > "
        if [[ "$REPLY" == [nN] ]]; then
            SWAPFILE="no"
            break
        elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            SWAPFILE="yes"
            break
        else
            L_invalid_reply_yn
        fi
    done
    clear
    L_banner_begin "Question 9 of $NUM"
    L_echo_purple "Username: $USERNAME"
    L_echo_purple "Profile: $PROFILE"
    if [[ "$AUTO" == "yes" ]]; then
        L_echo_green "Automatic Update: $AUTO"
    else
        L_echo_red "Automatic Update: $AUTO"
    fi
    if [[ "$KEY" == "yes" ]]; then
        L_echo_green "Configure Keyboard: $KEY"
    else
        L_echo_red "Configure Keyboard: $KEY"
    fi
    if [[ "$FONT" == "yes" ]]; then
        L_echo_green "Configure Font: $FONT"
    else
        L_echo_red "Configure Font: $FONT"
    fi
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
    if [[ "$SWAPFILE" == "yes" ]]; then
        L_echo_green "Swap File: $SWAPFILE"
    else
        L_echo_red "Swap File: $SWAPFILE"
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
# Alternative keyboard
if [[ "$KEY" == "yes" ]]; then
	# continue even if exit is not 0
    Conf_keyboard || true
fi
# Alternative font
if [[ "$FONT" == "yes" ]]; then
    Conf_consolefont || true
fi
Conf_apt_sources
Conf_sudoersd
Conf_ssh
Conf_sysctl
Conf_microcode
# Security updates
if [[ "$AUTO" == "yes" ]]; then
    Conf_unattend_upgrade
fi
# Periodic trim
if [[ "$SSD" == "yes" ]]; then
    Conf_trim
fi
# Custon grub
if [[ "$GRUB_X" == "yes" ]]; then
    Conf_grub
fi
# Swap file
if [[ "$SWAPFILE" == "yes" ]]; then
    Conf_swapfile
fi
# Workstation setup
if [[ "$PROFILE" == "workstation" ]]; then
    if [[ "$PKG_LIST" != "foo" ]]; then
        Inst_pkg_list
    else
        Inst_console_pkg
        Inst_xorg
        Inst_openbox
        Inst_theme
        #Inst_nonpkg_firefox	# Install firefox-esr instead
        Inst_workstation_pkg
        Conf_alt_workstation
    fi
fi
# Server setup
if [[ "$PROFILE" == "server" ]]; then
    if [[ "$PKG_LIST" != "foo" ]]; then
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
