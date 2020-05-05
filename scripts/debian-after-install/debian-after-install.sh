#!/bin/bash
#
NAME="debian-after-install.sh"
DESCRIPTION="Configure a device after a fresh install of Debian"

# Copyright (c) 2019 Daniel Wayne Armstrong. All rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

set -euo pipefail # run `bash -x buildblog` for debugging

VERSION="10"
RELEASE="buster"            # stable release codename
TRACK="foo"                 # package repository
PKG_LIST="foo"              # packages from LIST; set with option '-p LISTNAME'
USERNAME="foo"              # setup machine for USERNAME
SRC_DIR="https://github.com/dwarmstrong/linux-post-install"
SOURCE="${SRC_DIR}/tree/master/scripts/debian-after-install"
SRC_RAW="https://raw.githubusercontent.com/dwarmstrong/linux-post-install"
DOTFILES="https://github.com/dwarmstrong/dotfiles"

##----[ Start ]--------------------------------------------------------------##

err() {
  printf "\n[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*\n" >&2
}

# ANSI escape codes
RED="\\033[1;31m"
GREEN="\\033[1;32m"
YELLOW="\\033[1;33m"
PURPLE="\\033[1;35m"
NC="\\033[0m" # no colour

echo_red() {
echo -e "${RED}$1${NC}"
}

echo_green() {
echo -e "${GREEN}$1${NC}"
}

echo_yellow() {
echo -e "${YELLOW}$1${NC}"
}

echo_purple() {
echo -e "${PURPLE}$1${NC}"
}

banner_begin() {
    printf "\n--------[  $1  ]--------\n\n"
}

invalid_reply() {
    err "Invalid input."
}

invalid_reply_yn() {
    err "Invalid input. Please select 'Y(es)' or 'N(o)'..."
}

##----[ Verify ]-------------------------------------------------------------##

verify_root() {
    if (( EUID != 0 )); then
        err "Script must be run with root privileges."
        exit 1
    fi
}

verify_internet() {
    local UP
    UP=$( nc -z 8.8.8.8 53; echo $? ) # Google DNS is listening?

    export UP
    if [[ "$UP" -ne 0 ]]; then
        err "Script requires internet access to do its job."
        exit 1
    fi
}

verify_required_file() {
    local FILE
    FILE=$1
    
    if [[ ! -f "$FILE" ]]; then
        err "File not found."
        exit 1
    fi
}

verify_homedir() {
    # $1 is $USER
    if [[ "$#" -eq 0 ]]; then
        err "No username provided."
        exit 1
    elif [[ ! -d "/home/$1" ]]; then
        err "A  home directory for $1 not found."
        exit 1
    fi
}

bak_file() {
    for f in "$@"; do cp "$f" "$f.$(date +%FT%H%M%S).bak"; done
}

run_script() {
while :
do
    read -r -n 1 -p "Run script now? [yN] > "
    if [[ "$REPLY" == [yY] ]]; then
        break
    elif [[ "$REPLY" == [nN] || "$REPLY" == "" ]]; then
        exit
    else
        invalid_reply_yn
    fi
done
}

hello_world() {
    local LINK
    LINK="https://www.dwarmstrong.org"

    cat << _EOF_

NAME
    $NAME
        $DESCRIPTION
SYNOPSIS
    $NAME [OPTION]
DESCRIPTION
    Script '$NAME' is ideally run after the first successful
    boot into a minimal install of Debian $VERSION aka "${RELEASE}" release.

    A choice of either [w]orkstation or [s]erver setup is available. [S]erver
    is a basic console setup, whereas [w]orkstation is a more complete setup
    with the option of installing:
        * Openbox window manager
        * GNOME desktop environment
        * Xorg (no desktop)
    
    Alternately, in lieu of a pre-defined list of Debian packages, the user may
    specify their own custom list of packages to be installed.
OPTIONS
    -h              print details
    -p PKG_LIST     install packages from PKG_LIST
EXAMPLES
    Run script (requires superuser privileges) ...
        # ./${NAME}
    Install the list of packages specified in 'my-pkg-list' ...
        # ./${NAME} -p my-pkg-list
AUTHOR
    Daniel Wayne Armstrong -- $LINK
SOURCE
    $SOURCE
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

run_options() {
    while getopts ":hp:" OPT
    do
        case $OPT in
        h)
            hello_world
            exit
            ;;
        p)
            PKG_LIST="${OPTARG}"
            verify_required_file "${PKG_LIST}"
            ;;
        :)
            err "Option $OPTARG requires an argument."
            exit 1
            ;;
        ?)
            err "Invalid option ${OPTARG}."
            exit 1
            ;;
        esac
    done
}

##----[ Configure ]----------------------------------------------------------##

conf_keyboard() {
    clear
    banner_begin "Configure keyboard"
    printf "Choose a different keymap ...\n"
    dpkg-reconfigure keyboard-configuration
    setupcon
    cat /etc/default/keyboard
}

conf_consolefont() {
    clear
    banner_begin "Configure console font"
    printf "Choose a different font for the console ...\n"
    dpkg-reconfigure console-setup
    cat /etc/default/console-setup
}

conf_apt_sources() {
    clear
    banner_begin "Configure sources.list for '$RELEASE'"
    # Add backports repository, update package list, upgrade packages.
    local FILE
    FILE="/etc/apt/sources.list"
    local MIRROR
    MIRROR="http://deb.debian.org/debian/"
    local MIRROR1
    MIRROR1="http://security.debian.org/debian-security"
    local COMP
    COMP="main contrib non-free"
    
    # Backup previous config
    bak_file $FILE
    # Create a new config
    cat << _EOL_ > $FILE
# Base repository
deb $MIRROR $RELEASE $COMP
deb-src $MIRROR $RELEASE $COMP

# Security updates
deb $MIRROR1 ${RELEASE}/updates $COMP
deb-src $MIRROR1 ${RELEASE}/updates $COMP

# Stable updates
deb $MIRROR ${RELEASE}-updates $COMP
deb-src $MIRROR ${RELEASE}-updates $COMP

# Stable backports
deb $MIRROR ${RELEASE}-backports $COMP
deb-src $MIRROR ${RELEASE}-backports $COMP
_EOL_
    # Update/upgrade
    printf "Update list of packages available and upgrade $HOSTNAME ...\n"
    apt-get update && apt-get -y dist-upgrade
}

conf_ssh() {
    clear
    banner_begin "Create SSH directory for $USERNAME"
    # Install SSH server and create $HOME/.ssh.
    # "Secure remote access using SSH keys"
    #   https://www.dwarmstrong.org/ssh-keys/
    local SSH_DIR
    SSH_DIR="/home/${USERNAME}/.ssh"
    local AUTH_KEY
    AUTH_KEY="${SSH_DIR}/authorized_keys"
    
    # Install ssh server and keychain
    apt-get -y install openssh-server keychain
    # Create ~/.ssh
    if [[ -d "$SSH_DIR" ]]; then
        printf "SSH directory $SSH_DIR already exists. Skipping ...\n"
    else
        mkdir $SSH_DIR && chmod 700 $SSH_DIR && touch $AUTH_KEY
        chmod 600 $AUTH_KEY && chown -R ${USERNAME}:${USERNAME} $SSH_DIR
    fi
}

conf_sudoersd() {
    clear
    banner_begin "Configure sudo"
    # Add config files to /etc/sudoers.d/ to allow members of the sudo group
    # extra privileges. 
    local ALIAS
    ALIAS="/etc/sudoers.d/00-alias"
    local NOPASSWD
    NOPASSWD="/etc/sudoers.d/01-nopasswd"
    local OFF
    OFF="/usr/bin/systemctl poweroff"
    local REBOOT
    REBOOT="/usr/bin/systemctl reboot"
    local SUSPEND
    SUSPEND="/usr/bin/systemctl suspend"
    
    apt-get -y install sudo
    if [[ -f "$ALIAS" ]]; then
        printf "$ALIAS already exists. Skipping ...\n"
    else
        cat << _EOL_ > $ALIAS
User_Alias ADMIN = $USERNAME
Cmnd_Alias SYS_CMDS = $OFF, $REBOOT, $SUSPEND
_EOL_
    fi
    if [[ -f "$NOPASSWD" ]]; then
        printf "$NOPASSWD already exists. Skipping ...\n"
    else
        cat << _EOL_ > $NOPASSWD
# Allow specified users to execute these commands without password
ADMIN ALL=(ALL) NOPASSWD: SYS_CMDS
_EOL_
    fi
    adduser $USERNAME sudo
}

conf_sysctl() {
    clear
    banner_begin "Configure sysctl"
    local SYSCTL
    SYSCTL="/etc/sysctl.conf"
    local DMESG
    DMESG="kernel.dmesg_restrict"
    
    if grep -q "$DMESG" "$SYSCTL"; then
        printf "Option $DMESG already set. Skipping ...\n"
    else
        bak_file $SYSCTL
        cat << _EOL_ >> $SYSCTL

# Allow non-root access to dmesg
$DMESG = 0
_EOL_
        # Reload configuration.
        sysctl -p
    fi
}

conf_trim() {
    clear
    banner_begin "Configure periodic trim for SSD"
    # Periodic TRIM optimizes performance on SSD storage. Enable
    # a weekly task that discards unused blocks on the drive.
    printf "Enabling timer ...\n"
    systemctl enable fstrim.timer
}

conf_grub() {
    clear
    banner_begin "Configure GRUB extras"
    # Add some extras. See "GNU GRUB" -- https://www.dwarmstrong.org/grub/
    local GRUB_DEFAULT
    GRUB_DEFAULT="/etc/default/grub"
    local WALLPAPER
    WALLPAPER="/boot/grub/grub_wallpaper.png"
    local DWNLD
    DWNLD="${SRC_DIR}/blob/master/config${WALLPAPER}?raw=true"
    local CUSTOM
    CUSTOM="/boot/grub/custom.cfg"
    
    # Backup config
    bak_file $GRUB_DEFAULT
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
}

conf_swapfile() {
    clear
    banner_begin "Configure swapfile"
    # File that holds data transferred out of RAM to free up extra memory.
    local SWAPFILE
    SWAPFILE="/swapfile"
    local SWAPSIZE
    SWAPSIZE="2G"
    
    if [[ -f "$SWAPFILE" ]]; then
        printf "Swap file $SWAPFILE already exists. Skipping ...\n"
    else
        fallocate -l $SWAPSIZE $SWAPFILE
        # Only root should be granted read/write access.
        chmod 600 $SWAPFILE
        # Create the swap area
        mkswap $SWAPFILE
        printf "Activating $SWAPFILE ...\n"
        swapon $SWAPFILE
        swapon -s
        free -h
        # Make the change permanent in /etc/fstab.
        bak_file /etc/fstab
        echo "$SWAPFILE none swap sw 0 0" | tee -a /etc/fstab
    fi
}

conf_unattend_upgrade() {
    clear 
    banner_begin "Install unattend-upgrades"
    # Install security updates automatically courtesy of `unattended-upgrades`
    # package with options set in /etc/apt/apt.conf.d/50unattended-upgrades.
    #
    # Activate tracking with details provided in /etc/apt/apt.conf.d/02periodic.
    # 
    # Upgrade information is logged under /var/log/unattended-upgrades.
    #
    # See: "Automatic security updates on Debian"
    #       https://www.dwarmstrong.org/unattended-upgrades.html
    local PKG
    PKG="unattended-upgrades"
    local PERIODIC
    PERIODIC="/etc/apt/apt.conf.d/02periodic"
    local UPGRADE
    UPGRADE="/etc/apt/apt.conf.d/50unattended-upgrades"
    local DWNLD
    DWNLD="${SRC_RAW}/master/config/etc/apt/apt.conf.d/02periodic"
    local DWNLD2
    DWNLD2="${SRC_RAW}/master/config/etc/apt/apt.conf.d/50unattended-upgrades"
    
    apt-get -y install $PKG
    if [[ -f "$PERIODIC" ]]; then
        printf "$PERIODIC already exists. Skipping ...\n"
    else
        wget -c $DWNLD -O $PERIODIC
    fi
    if [[ -f "$UPGRADE" ]]; then
        printf "$UPGRADE already exists. Skipping ...\n"
    else
        wget -c $DWNLD2 -O $UPGRADE
    fi
}

conf_alt_workstation() {
    clear
    banner_begin "Configure default commands"
    update-alternatives --config editor
    update-alternatives --config x-terminal-emulator
}

conf_alt_server() {
    clear
    banner_begin "Configure default commands"
    update-alternatives --config editor
}

#----[ Install ]-------------------------------------------------------------##

inst_pkg_list() {
    clear
    banner_begin "Install packages from '$PKG_LIST' list (option '-p')"
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
    # Use apt-get to install the selected packages
    apt-get -y dselect-upgrade
}

inst_microcode() {
    clear
    banner_begin "Install microcode"
    # Intel and AMD processors may periodically need updates to their microcode
    # firmware. Microcode can be updated (and kept in volatile memory) during
    # boot by installing either intel-microcode or amd64-microcode (AMD).
    local CPU
    CPU="/proc/cpuinfo"

    if grep -q GenuineIntel "$CPU"; then
        apt-get -y install intel-microcode
    elif grep -q AuthenticAMD "$CPU"; then
        apt-get -y install amd64-microcode
    fi
}

inst_console_pkg() {
    clear
    banner_begin "Install console packages"
    local PKG_TOOLS
    PKG_TOOLS="apt-file apt-listbugs apt-listchanges apt-show-versions 
    apt-utils aptitude command-not-found"
    local CONSOLE
    CONSOLE="bc bsd-mailx cowsay cryptsetup curl firmware-misc-nonfree git 
    gnupg htop mlocate net-tools pmount rsync sl speedtest-cli tmux unzip vrms 
    wget whois"
    local EDITOR
    EDITOR="neovim shellcheck"

    # shellcheck disable=SC2086
    apt-get -y install $PKG_TOOLS $CONSOLE $EDITOR
    apt-file update && update-command-not-found
    # Create the mlocate database
    /etc/cron.daily/mlocate
    # Train kept a rollin' ...
    if [[ -x "/usr/games/sl" ]]; then
        /usr/games/sl
    fi
}

inst_server_pkg() {
    clear
    banner_begin "Install server packages"
    local PKG
    PKG="fail2ban logwatch"
    
    # shellcheck disable=SC2086
    apt-get -y install $PKG
}

inst_xorg() {
    clear
    banner_begin "Install X environment"
    local XORG
    XORG="xorg xbacklight xbindkeys xvkbd xinput xserver-xorg-input-all"
    local FONT
    FONT="fonts-dejavu fonts-liberation2 fonts-ubuntu"
    # shellcheck disable=SC2086

    apt-get -y install $XORG $FONT
}

inst_openbox() {
    clear
    banner_begin "Install Openbox window manager"
    # "Roll your own Linux desktop using Openbox"
    #   https://www.circuidipity.com/openbox/
    local WM
    WM="openbox obconf menu"
    local WM_EXTRA
    WM_EXTRA="clipit compton compton-conf dunst dbus-x11 feh hsetroot i3lock 
    libnotify-bin network-manager network-manager-gnome pavucontrol pulseaudio 
    pulseaudio-utils rofi scrot tint2 viewnior volumeicon-alsa 
    xfce4-power-manager"

    inst_xorg
    # shellcheck disable=SC2086
    apt-get -y install $WM $WM_EXTRA
}

inst_gnome() {
    clear
    banner_begin "Install GNOME desktop"
    local DESKTOP
    DESKTOP="gnome-desktop desktop print-server"
    local REMOVE
    REMOVE="gnome-games"
    
    inst_xorg
    tasksel install $DESKTOP
    apt-get -y autoremove $REMOVE
}

inst_theme() {
    clear
    banner_begin "Install theme"
    local GTK
    GTK="gnome-themes-standard gtk2-engines-murrine gtk2-engines-pixbuf"
    local QT
    QT="qt5-style-plugins"
    local TOOL
    TOOL="lxappearance obconf"
    local THEME
    THEME="Shades-of-gray-theme"
    local THEMEDIR
    THEMEDIR="/home/${USERNAME}/.themes"
    local DWNLD_THEME
    DWNLD_THEME="https://github.com/WernerFP/Shades-of-gray-theme.git"
    local ICON
    ICON="papirus-icon-theme"

    # shellcheck disable=SC2086 
    apt-get -y install $GTK $QT $TOOL
    # Install the *Shades-of-gray* theme
    if [[ -d "$THEMEDIR" ]]; then
        printf "$THEMEDIR already exists.\n"
    else
        mkdir $THEMEDIR
    fi
    if [[ -d "$THEME" ]]; then
        printf "$THEME already exists.\n"
    else
        git clone $DWNLD_THEME
        cp -r ${THEME}/Shades-of-* $THEMEDIR
        chown -R ${USERNAME}:${USERNAME} $THEMEDIR
    fi
    # Install icons
    apt-get -y install $ICON
}

inst_backports() {
    local REMOVE
    REMOVE="firefox-esr"
    local PKG
    PKG="firefox"
    
    apt-get -y purge $REMOVE
    #apt-get -y -t ${RELEASE}-backports install $PKG    # not available (yet)
}

inst_workstation_pkg() {
    clear
    banner_begin "Install some favourite workstation packages"
    local AV
    AV="alsa-utils default-jre espeak ffmpeg gstreamer1.0-plugins-ugly 
    mpg321 pavucontrol pulseaudio pulseaudio-utils rhythmbox sox vlc"
    local DOC
    DOC="libreoffice libreoffice-help-en-us libreoffice-gnome hunspell-en-ca 
    qpdfview"
    local IMAGE
    IMAGE="scrot viewnior geeqie gimp gimp-help-en gimp-data-extras"
    local NET
    NET="network-manager-gnome newsboat transmission-gtk"
    local SYS
    SYS="dunst rofi rxvt-unicode"
    local DEV
    DEV="build-essential dkms libncurses5-dev linux-headers-amd64 
    module-assistant python3-dev python3-pip python3-pygments"
    
    # Sometimes apt gets stuck on a slow download. Breaking up downloads 
    # tends to speeds things up.
    # shellcheck disable=SC2086
    apt-get -y install $AV && apt-get -y install $DOC && \
    apt-get -y install $IMAGE && apt-get -y install $NET && \
    apt-get -y install $SYS && apt-get -y install $DEV
}

##----[ Options ]------------------------------------------------------------##

goto_work() {
    local NUM
    NUM="10"
    local PROFILE
    PROFILE="foo"
    local AUTO
    AUTO="foo"
    local KEY
    KEY="foo"
    local FONT
    FONT="foo"
    local SSD
    SSD="foo"
    local GRUB_X
    GRUB_X="foo"
    local SWAPFILE
    SWAPFILE="foo"
    local GUI
    GUI="foo"

    while :
    do
        clear
        banner_begin "Question 1 of $NUM"
        read -r -p "What is your non-root username? > " FOO; USERNAME="$FOO"
        verify_homedir "$USERNAME"        # $HOME exists for USERNAME?
        
        clear
        banner_begin "Question 2 of $NUM"
        while :
        do
            read -r -n 1 -p "Configuring a [w]orkstation or [s]erver? > "
            if [[ "$REPLY" == [wW] ]]; then
                PROFILE="workstation"
                break
            elif [[ "$REPLY" == [sS] ]]; then
                PROFILE="server"
                break
            else
            invalid_reply
            fi
        done
	
        clear
	    banner_begin "Question 3 of $NUM"
	    while :
	    do
            printf "Fetch and install the latest security fixes courtesy of\n"
            printf "_unattended-upgrades_. Useful especially on servers.\n\n"
		    read -r -n 1 -p "Install security updates automatically? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                AUTO="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                AUTO="yes"
                break
            else
                invalid_reply_yn
            fi
        done

	    clear
	    banner_begin "Question 4 of $NUM"
	    while :
	    do
		    printf "Change the model of keyboard and/or the keyboard map.\n"
            printf "Example: QWERTY to Colemak, or non-English layouts.\n\n"
		    read -r -n 1 -p "Setup different keyboard configuration? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                KEY="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                KEY="yes"
                break
            else
                invalid_reply_yn
            fi
        done

	    clear
	    banner_begin "Question 5 of $NUM"
	    while :
	    do
		    printf "Change the font and font-size used in the console.\n"
            printf "Example:TERMINUS font in size 8x16 (default) or 10x20.\n\n"
		    read -r -n 1 -p "Setup a different console font? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                FONT="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                FONT="yes"
                break
            else
                invalid_reply_yn
            fi
        done
    
        clear
        banner_begin "Question 6 of $NUM"
	    while :
        do
            printf "Periodic TRIM optimizes performance on solid-state\n"
            printf "storage. If this machine has an SSD drive, you\n"
            printf "should enable this task.\n\n"
		    read -r -n 1 -p "Enable task that discards unused blocks? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                SSD="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                SSD="yes"
                break
            else
                invalid_reply_yn
            fi
        done

        clear
        banner_begin "Question 7 of $NUM"
        while :
        do
            printf "GRUB extras: Add a bit of colour, sound, wallpaper!\n\n"
		    read -r -n 1 -p "Setup a custom GRUB? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                GRUB_X="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                GRUB_X="yes"
                break
            else
                invalid_reply_yn
            fi
        done

        clear
        banner_begin "Question 8 of $NUM"
        while :
        do
            printf "If not using a swap partition, creating a *swapfile* is\n"
            printf "a good idea. This allows data to be transferred out of\n"
            printf "RAM to free up extra memory.\n\n"
		    read -r -n 1 -p "Create a 2GB swapfile? [Yn] > "
            if [[ "$REPLY" == [nN] ]]; then
                SWAPFILE="no"
                break
            elif [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
                SWAPFILE="yes"
                break
            else
                invalid_reply_yn
            fi
        done

        clear
        banner_begin "Question 9 of $NUM"
        while :
        do
            printf "Choice of desktops:\n"
            printf "[1] Openbox\n"
            printf "[2] GNOME\n"
            printf "[3] Xorg (no desktop)\n"
            printf "[4] Console (no X)\n\n"
	        read -r -n 1 -p "Your choice? [1-4] > "
            if [[ "$REPLY" == "1" ]]; then
                GUI="openbox"
                break
            elif [[ "$REPLY" == "2" ]]; then
                GUI="gnome"
                break
            elif [[ "$REPLY" == "3" ]]; then
                GUI="xorg"
                break
            elif [[ "$REPLY" == "4" ]]; then
                GUI="console"
                break
            else
                invalid_reply
            fi
        done
    
        clear
        banner_begin "Question 10 of $NUM"
        echo_purple "Username: $USERNAME"
        echo_purple "Profile: $PROFILE"
        if [[ "$AUTO" == "yes" ]]; then
            echo_green "Automatic Update: $AUTO"
        else
            echo_red "Automatic Update: $AUTO"
        fi
        if [[ "$KEY" == "yes" ]]; then
            echo_green "Configure Keyboard: $KEY"
        else
            echo_red "Configure Keyboard: $KEY"
        fi
        if [[ "$FONT" == "yes" ]]; then
            echo_green "Configure Font: $FONT"
        else
            echo_red "Configure Font: $FONT"
        fi
        if [[ "$SSD" == "yes" ]]; then
            echo_green "SSD: $SSD"
        else
            echo_red "SSD: $SSD"
        fi
        if [[ "$GRUB_X" == "yes" ]]; then
            echo_green "Custom GRUB: $GRUB_X"
        else
            echo_red "Custom GRUB: $GRUB_X"
        fi
        if [[ "$SWAPFILE" == "yes" ]]; then
            echo_green "Swap File: $SWAPFILE"
        else
            echo_red "Swap File: $SWAPFILE"
        fi
        if [[ "$GUI" != "none" ]]; then
            echo_green "Desktop: $GUI"
        else
            echo_red "Desktop: $GUI"
        fi
        if [[ "$PKG_LIST" != "foo" ]]; then
            echo_green "Package List: $PKG_LIST"
        fi
        printf "\n"
	    read -r -n 1 -p "Is this correct? [Yn] > "
        if [[ "$REPLY" == [yY] || "$REPLY" == "" ]]; then
            break
        elif [[ "$REPLY" == [nN] ]]; then
            printf "OK ... Let's try again ...\n"
        else
            invalid_reply_yn
        fi
    done

    # Alternative keyboard
    if [[ "$KEY" == "yes" ]]; then
	    # continue even if exit is not 0
        conf_keyboard || true
    fi
    # Alternative font
    if [[ "$FONT" == "yes" ]]; then
        conf_consolefont || true
    fi
    conf_apt_sources
    conf_sudoersd
    conf_ssh
    conf_sysctl
    # Security updates
    if [[ "$AUTO" == "yes" ]]; then
        conf_unattend_upgrade
    fi
    # Periodic trim
    if [[ "$SSD" == "yes" ]]; then
        conf_trim
    fi
    # Custon grub
    if [[ "$GRUB_X" == "yes" ]]; then
        conf_grub
    fi
    # Swap file
    if [[ "$SWAPFILE" == "yes" ]]; then
        conf_swapfile
    fi
    inst_microcode
   
    # Workstation setup
    if [[ "$PROFILE" == "workstation" ]]; then
        if [[ "$PKG_LIST" != "foo" ]]; then
        inst_pkg_list
        else
            inst_console_pkg
            if [[ "$GUI" == "openbox" ]]; then
                inst_openbox
            elif [[ "$GUI" == "gnome" ]]; then
                inst_gnome
            elif [[ "$GUI" == "xorg" ]]; then
                inst_xorg
            fi
            if [[ "$GUI" == "openbox" ]] || [[ "$GUI" == "gnome" ]]; then
                inst_theme
                inst_backports
                inst_workstation_pkg
                conf_alt_workstation
            fi
        fi
    fi
    
    # Server setup
    if [[ "$PROFILE" == "server" ]]; then
        if [[ "$PKG_LIST" != "foo" ]]; then
            inst_pkg_list
        else
            inst_console_pkg
            inst_server_pkg
            conf_alt_server
        fi
    fi
}

au_revoir() {
    local message
    message="Done! Debian is ready. Happy hacking!"
    
    printf "\n(O<  $message"
    printf "\n(/)_\n"
}

##----[ Run ]----------------------------------------------------------------##

# (O<  Let's go!
# (/)_
run_options "$@"
verify_root			# Script run with root priviliges?
verify_internet		# Internet access available?
# ... rollin' rollin' rollin' ...
hello_world
run_script
goto_work
clear
au_revoir
