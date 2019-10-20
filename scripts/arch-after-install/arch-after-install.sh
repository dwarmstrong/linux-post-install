#!/bin/bash
NAME="arch-after-install.sh"
BLURB="Configure a device after a fresh install of Arch Linux"
SRC_DIR="https://github.com/vonbrownie/linux-post-install"
SOURCE="${SRC_DIR}/tree/master/scripts/arch-after-install"
set -eu


# Copyright (c) 2019 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.


PKG_LIST="foo"              # packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # setup machine for USERNAME
SLEEP="5"                   # pause for X seconds
SRC_RAW="https://raw.githubusercontent.com/vonbrownie/linux-post-install"
DOTFILES="https://github.com/vonbrownie/dotfiles"
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
#UP=$( nc -z 8.8.8.8 53; echo $? ) # Google DNS is listening?
# `nc` not available on barebones Arch install ... use ping instead ...
UP=$( ping -q -c 1 -W 1 8.8.8.8 >/dev/null; echo $?)

if [[ "$UP" -ne 0 ]]; then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
    exit 1
fi
}


L_test_required_file() {
local FILE=$1
local ERR="ERROR: file '$FILE' not found."

if [[ ! -f "$FILE" ]]; then
    L_echo_red "\\n$( L_penguin ) .: $ERR"
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

if [[ -x "/usr/bin/cowsay" ]]; then
    L_echo_green "$( /usr/bin/cowsay "$MSG" )"
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
    Script '$NAME' is ideally run after the first successful boot
    into an install of Arch Linux. 

    A choice of either [w]orkstation or [s]erver setup is available. [S]erver
    is a basic console setup, whereas [w]orkstation is a more complete setup
    using Xorg with the option of installing Openbox window manager plus a
    selection of applications suitable for a desktop environment.
    
    Alternately, in lieu of a pre-defined list of Arch packages, the user may
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
SEE ALSO
    * More Arch Linux: arch-after-install
        ${LINK}/arch-after-install/
    * Minimal Arch Linux
        ${LINK}/minimal-arch/
    * Roll your own Linux desktop using Openbox
        ${LINK}/openbox/
    * Install (almost) the same list of Arch packages on multiple machines
        ${LINK}/arch-package-list/

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


Conf_username() {
clear
L_banner_begin "Configure account for $USERNAME"

# Add user
if [[ -d "/home/${USERNAME}" ]]; then
    echo "User '$USERNAME' already exists. Skipping ..."
else
    useradd -m -G wheel -s /bin/bash $USERNAME
    echo "Enter password for $USERNAME ..."
    passwd $USERNAME
fi

L_sig_ok
sleep $SLEEP
}


Conf_pacman() {
clear
L_banner_begin "Configure pacman"
local FILE="/etc/pacman.conf"

# TODO ...
# Misc options
#Color
#ILoveCandy

L_sig_ok
sleep $SLEEP
}


Conf_mirrorlist() {
clear
L_banner_begin "Configure mirrorlist and upgrade $HOSTNAME"
local FILE="/etc/pacman.d/mirrorlist"
local SYSTEMD_SERVICE="reflector.service"
local SYSTEMD_UNIT="/etc/systemd/system/${SYSTEMD_SERVICE}"
local REF_OPTS="--verbose --latest 10 --protocol https --sort rate"
local REF_CNTRY="--country Canada --country 'United States' --country Germany"

# Backup previous config
L_bak_file $FILE

# Download `reflector` to generate a fresh mirrorlist
pacman --noconfirm -S reflector

# Create a systemd service unit
cat << _EOL_ > $SYSTEMD_UNIT
[Unit]
Description=Pacman mirrorlist update

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector $REF_OPTS $REF_CNTRY --save $FILE

[Install]
RequiredBy=multi-user.target
_EOL_

# Start the service to perform a mirror refresh, then run a system upgrade
systemctl start $SYSTEMD_SERVICE && pacman -Syyu

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
pacman --noconfirm -S openssh keychain

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
# Add config files to /etc/sudoers.d/ to allow members of the wheel group
# extra privileges. 
local ALIAS="/etc/sudoers.d/00-alias"
local NOPASSWD="/etc/sudoers.d/01-nopasswd"
local OFF="/usr/bin/systemctl poweroff"
local REBOOT="/usr/bin/systemctl reboot"
local SUSPEND="/usr/bin/systemctl suspend"

# Install
pacman --noconfirm -S sudo

# TODO ... Uncomment 'wheel' group in sudoers

# Create configs
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
    pacman --noconfirm -S intel-ucode
elif grep -q AuthenticAMD "$CPU"; then
    pacman --noconfirm -S amd-ucode
fi

# Regenerate the GRUB config to activate loading the microcode update
grub-mkconfig -o /boot/grub/grub.cfg

L_sig_ok
sleep $SLEEP
}


Inst_kernel_lts() {
clear
L_banner_begin "Install the long-term support (LTS) Linux kernel"
# Use either as a fallback option to Arch's default kernel, or set LTS kernel
# as default kernel (for added stability and less frequent updates)

pacman --noconfirm -S linux-lts
grub-mkconfig -o /boot/grub/grub.cfg

L_sig_ok
sleep $SLEEP
}


Conf_trim() {
clear
L_banner_begin "Configure periodic trim for SSD"

# Periodic TRIM optimizes performance on SSD storage. Enable a weekly task
# that discards unused blocks on the drive.
systemctl enable fstrim.timer

L_sig_ok
sleep $SLEEP
}


Conf_grub() {
clear
L_banner_begin "Configure GRUB extras"
# Add some extras. See "GNU GRUB" -- https://www.circuidipity.com/grub/
local GRUB_DEFAULT="/etc/default/grub"
local WALLPAPER="/boot/grub/grub_wallpaper.png"
local DWNLD="${SRC_DIR}/blob/master/config${WALLPAPER}?raw=true"
local CUSTOM="/boot/grub/custom.cfg"

# Backup config
L_bak_file $GRUB_DEFAULT

# Submenu
if ! grep -q ^GRUB_DISABLE_SUBMENU "$GRUB_DEFAULT"; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Kernel list as a single menu
GRUB_DISABLE_SUBMENU=y
_EOL_
fi

# Tunes
if ! grep -q ^GRUB_INIT_TUNE "$GRUB_DEFAULT"; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Start off with a bit of "Close Encounters"
#GRUB_INIT_TUNE='480 900 2 1000 2 800 2 400 2 600 3'
_EOL_
fi

# Wallpaper
if ! grep -q ^GRUB_BACKGROUND $GRUB_DEFAULT; then
    cat << _EOL_ >> $GRUB_DEFAULT

# Wallpaper
GRUB_BACKGROUND='$WALLPAPER'
_EOL_
fi
if [[ -f "$WALLPAPER" ]]; then
    echo "$WALLPAPER already exists. Skipping ..."
else
    pacman --noconfirm -S wget
    wget -c "$DWNLD" -O "$WALLPAPER"
fi

# Menu colours
if [[ -f "$CUSTOM" ]]; then
    echo "$CUSTOM already exists. Skipping ..."
else
    cat << _EOL_ > $CUSTOM
set color_normal=white/black
set menu_color_normal=white/black
set menu_color_highlight=white/red
_EOL_
fi

# Apply changes
grub-mkconfig -o /boot/grub/grub.cfg

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
    swapon $SWAPFILE
    echo ""
    swapon -s
    echo ""
    free -h
    # Add swapfile to /etc/fstab.
    L_bak_file /etc/fstab
    echo "$SWAPFILE none swap sw 0 0" | tee -a /etc/fstab
fi

L_sig_ok
sleep $SLEEP
}


Inst_pkg_list() {
clear
L_banner_begin "Install packages from '$PKG_LIST' list (option '-p')"

# TODO

L_sig_ok
sleep $SLEEP
}


Inst_console_pkg() {
clear
L_banner_begin "Install console packages"
local PKG_TOOLS="pkgfile"
local CONSOLE="bc cowsay cryptsetup curl git gnupg htop mlocate net-tools 
rsync sl tmux unzip usbutils wget whois"
local EDITOR="neovim shellcheck"

# shellcheck disable=SC2086
pacman --noconfirm -S $PKG_TOOLS $CONSOLE $EDITOR

# Automatically search the official repositories when entering an
# unrecognized command; update package database
pkgfile --update

# Package `pkgfile` includes systemd timer `pkgfile-update.timer` for
# automatically (daily) synchronizing the database
systemctl enable pkgfile-update.timer

# Update database for `locate`; package contains an `updatedb.timer` unit
# which invokes a database update each day and is enabled after install
updatedb

# Train kept a rollin' ...
if [[ -x "/usr/bin/sl" ]]; then
    /usr/bin/sl
fi

L_sig_ok
sleep $SLEEP
}


Inst_server_pkg() {
clear
L_banner_begin "Install server packages"
local PKG="fail2ban logwatch"

# shellcheck disable=SC2086
pacman --noconfirm -S $PKG

L_sig_ok
sleep $SLEEP
}


Inst_xorg() {
clear
L_banner_begin "Install X environment"
local XORG="xorg xorg-xbacklight xorg-xinit xorg-xmodmap xbindkeys tk"
local FONT="ttf-dejavu ttf-liberation ttf-ubuntu-font-family"

# shellcheck disable=SC2086
pacman --noconfirm -S $XORG $FONT

# Load driver for intel video card if present
if lspci | grep -Ei 'vga.*intel'; then
    pacman --noconfirm -S xf86-video-intel
fi

L_sig_ok
sleep $SLEEP
}


Inst_openbox() {
clear
L_banner_begin "Install Openbox window manager"
# "Roll your own Linux desktop using Openbox"
#   https://www.circuidipity.com/openbox/
local WM="openbox obconf"
local WM_EXTRA="compton dunst feh hsetroot i3lock libnotify 
network-manager-applet pavucontrol pulseaudio rofi scrot 
tint2 viewnior volumeicon xfce4-power-manager"

# shellcheck disable=SC2086
pacman --noconfirm -S $WM $WM_EXTRA

L_sig_ok
sleep $SLEEP
}


Inst_theme() {
clear
L_banner_begin "Install theme"
local GTK="gnome-themes-standard gtk-engines gtk-engine-murrine"
local QT="qt5-styleplugins"
local TOOL="lxappearance obconf"
local THEME="Shades-of-gray-theme"
local THEMEDIR="/home/${USERNAME}/.themes"
local DWNLD_THEME="https://github.com/WernerFP/Shades-of-gray-theme.git"
local ICON="papirus-icon-theme"

# shellcheck disable=SC2086 
pacman --noconfirm -S $GTK $QT $TOOL

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

# Install icons
pacman --noconfirm -S $ICON

L_sig_ok
sleep $SLEEP
}


Inst_workstation_pkg() {
clear
L_banner_begin "Install some favourite workstation packages"
local AV="alsa-utils jre-openjdk espeak ffmpeg gst-plugins-ugly pavucontrol 
pulseaudio rhythmbox sox vlc"
local DOC="libreoffice-still hunspell hunspell-en_CA qpdfview"
local IMAGE="scrot viewnior geeqie gimp gimp-help-en"
local NET="firefox network-manager-applet newsboat transmission-gtk"
local SYS="dunst rofi rxvt-unicode"
local DEV="base-devel"

# shellcheck disable=SC2086
pacman --noconfirm -S $AV $DOC $IMAGE $NET $SYS $DEV

L_sig_ok
sleep $SLEEP
}


Goto_work() {
local NUM="7"
local PROFILE="foo"
local SSD="foo"
local GRUB_X="foo"
local SWAPFILE="foo"
local GUI="foo"

while :
do
    clear
    L_banner_begin "Question 1 of $NUM"
    read -r -p "What will be your non-root username? > " FOO; USERNAME="$FOO"
    
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
    L_banner_begin "Question 4 of $NUM"
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
    L_banner_begin "Question 5 of $NUM"
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
    L_banner_begin "Question 6 of $NUM"
    while :
    do
        echo "Choice of desktops:"
        echo "[1] Openbox"
        echo "[2] Xorg (no desktop)"
        echo ""
	read -r -n 1 -p "Your choice? [1-2] > "
        if [[ "$REPLY" == "1" ]]; then
            GUI="openbox"
            break
        elif [[ "$REPLY" == "2" ]]; then
            GUI="xorg"
            break
        else
            L_invalid_reply_yn
        fi
    done
    
    clear
    L_banner_begin "Question 7 of $NUM"
    L_echo_purple "Username: $USERNAME"
    L_echo_purple "Profile: $PROFILE"
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
    if [[ "$GUI" != "none" ]]; then
        L_echo_green "Desktop: $GUI"
    else
        L_echo_red "Desktop: $GUI"
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

# Configure and install
Conf_username
Conf_pacman
Conf_mirrorlist
Conf_ssh
Conf_sudoersd
Conf_microcode
Inst_kernel_lts
 Periodic trim
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
        if [[ "$GUI" == "openbox" ]]; then
            Inst_xorg
            Inst_openbox
            Inst_theme
            Inst_workstation_pkg
        elif [[ "$GUI" == "xorg" ]]; then
            Inst_xorg
        fi
    fi
fi
# Server setup
if [[ "$PROFILE" == "server" ]]; then
    if [[ "$PKG_LIST" != "foo" ]]; then
        Inst_pkg_list
    else
        Inst_console_pkg
        Inst_server_pkg
    fi
fi
}


#: START
Run_options "$@"
L_test_root         # Script run with root priviliges?
L_test_internet		# Internet access available?
# ... rollin' rollin' rollin' ...
Hello_you
L_run_script
Goto_work
clear
L_all_done
L_echo_green "\\nThanks for using '${NAME}' and happy hacking!"
