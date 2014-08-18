#!/bin/bash
set -eu

# Copyright (c) 2014 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (GPLv2) published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

# Script variables
script_name="c720-sidbook-main.sh"
script_description="configure Debian sid/unstable branch for Acer C720 Chromebook"
script_synopsis="$script_name [OPTION] [PACKAGE_LIST]"
script_git="https://github.com/vonbrownie"
script_src="$script_git/linux-post-install/blob/master/$script_name"

# Script global directory variables
tmp_dir="/tmp/tmp.debian-post-install"
current_dir="."
extras_dir="${current_dir}/extras/"

# Debian variables
deb_stable="wheezy"
deb_testing="jessie"
deb_unstable="sid"
apt_preferences="/etc/apt/preferences"
apt_sources_list="/etc/apt/sources.list"
deb_archive="http://http.debian.net/debian/"
deb_arch=$(dpkg --print-architecture)
dpkg_info="/var/lib/dpkg/info"
deb_branch=""
deb_package_list=""

# Functions
echo_red() {
echo -e "\E[1;31m$1"
echo -e '\e[0m'
}

echo_green() {
echo -e "\E[1;32m$1"
echo -e '\e[0m'
}

echo_yellow() {
echo -e "\E[1;33m$1"
echo -e '\e[0m'
}

echo_blue() {
echo -e "\E[1;34m$1"
echo -e '\e[0m'
}

echo_magenta() {
echo -e "\E[1;35m$1"
echo -e '\e[0m'
}

echo_cyan() {
echo -e "\E[1;36m$1"
echo -e '\e[0m'
}

penguinista() {
cat << _EOF_

(O<
(/)_
_EOF_
}

available_options() {
cat << _EOF_
OPTIONS
  -h    print command syntax and options
  -i    import a Debian package list for installation
EXAMPLE
  Install packages from 'package-list.txt':
  (as_root)# ./$script_name -i package-list.txt

_EOF_
}

long_description() {
clear
echo_yellow "$( penguinista ) .: $script_name -- $script_description :."
cat << _EOF_
SYNOPSIS
  $script_synopsis
SOURCE
  $script_src

Howdy! Ideally this script is run following a fresh installation of
Debian GNU/Linux.

See: "Debian Wheezy Minimal Install"
http://www.circuidipity.com/install-debian-wheezy-screenshot-tour.html

"Install Debian using grml-debootstrap"
http://www.circuidipity.com/grml-debootstrap.html

This system will be configured to track Debian's ${deb_unstable}/unstable branch and the
Openbox window manager + extra apps suitable for a desktop environment will be installed.

## TIP ##
Import a list of packages that duplicate the configuration from another system
running Debian.

See: "Duplicate Debian package selection on multiple machines"
http://www.circuidipity.com/dpkg-duplicate.html

... and run this script with option '-i' and the location of the package list.

EXAMPLE
  Install packages from 'package-list.txt':
  (as_root)# ./$script_name -i package-list.txt

_EOF_
}

run_options() {
while getopts ":hi:" OPT
do
    case $OPT in
        h)
            long_description
            exit 0
            ;;
        i)
            deb_package_list="$OPTARG"
            break
            ;;
        :)
            echo_red "\n$( penguinista ) .: Option '-$OPTARG' missing argument.\n"
            available_options
            exit 1
            ;;
        *)
            echo_red "\n$( penguinista ) .: Invalid option '-$OPTARG'\n"
            available_options
            exit 1
            ;;
    esac
done
}

invalid_reply() {
echo_red "\n'$REPLY' is invalid input...\n"
}

invalid_reply_yn() {
echo_red "\n'$REPLY' is invalid input. Please select 'Y(es)' or 'N(o)'...\n"
}

confirm_start() {
while :
do
    read -n 1 -p "Run script now? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
        echo_green "\nLet's roll then ...\n"
        sleep 2
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
        penguinista
        exit
    else
        invalid_reply_yn
    fi
done
}

test_root() {
if [[ $UID -ne 0 ]]
then
    echo_red "\n$( penguinista ) .: $script_name requires ROOT privileges to do its job.\n"
    exit 1
else
    if [[ ! -d "$tmp_dir" ]]
    then
        mkdir $tmp_dir
    fi
fi
}

interface_found() {
ip link | awk '/mtu/ {gsub(":",""); printf "\t%s", $2} END {printf "\n"}'
}

test_connect() {
if ! $(ip addr show | grep "state UP" &>/dev/null)
then
    echo_red "\n$( penguinista ) .: $script_name requires an active network interface."
    printf "\nINTERFACES FOUND\n"
    interface_found
    exit 1
fi
}

test_package_list() {
if [[ ! -z $deb_package_list && ! -e $deb_package_list ]]
then
    echo_red "\n$( penguinista ) .: '$deb_package_list' not found.\n"
    exit 1
fi
}

test_conditions() {
test_root
test_connect
test_package_list
}

apt_preferences_unstable() {
if [[ -e $apt_preferences ]]
then
    cp $apt_preferences ${apt_preferences}.$(date +%Y%m%dT%H%M%S).bak
fi
cat > $apt_preferences << _EOF_
# Configure default preferences in package installation
# * unlisted repositories are auto-ranked 500
# * installed packages are ranked 100

Package: *
Pin: release a=unstable
Pin-Priority: 900

Package: *
Pin: release a=experimental
Pin-Priority: 1
_EOF_
}

apt_sources_unstable() {
if [[ -e $apt_sources_list ]]
then
    cp $apt_sources_list ${apt_sources_list}.$(date +%Y%m%dT%H%M%S).bak
fi
clear
cat > $apt_sources_list << _EOF_
### unstable ###
deb $deb_archive unstable main contrib non-free
deb-src $deb_archive unstable main contrib non-free

### experimental ###
deb $deb_archive experimental main

### multimedia ###
deb http://www.deb-multimedia.org unstable main non-free

_EOF_
apt-get update
}

apt_keys() {
clear
apt-get install -y debian-archive-keyring
apt-get install deb-multimedia-keyring
apt-get install pkg-mozilla-archive-keyring
apt-get update
apt-get -y dist-upgrade
}

apt_package_list() {
local deb_packages
deb_packages=$(mktemp)
clear
if [[ ! -z $deb_package_list && -e $deb_package_list ]]
then
    apt-cache dumpavail > "$deb_packages"
    dpkg --merge-avail "$deb_packages"
    rm -f "$deb_packages"
    dpkg --clear-selections
    dpkg --set-selections < $deb_package_list
    apt-get dselect-upgrade
fi
}

apt_package_purge() {
local deb_package_purge
deb_package_purge="gdm3 gnome-system-tools nautilus* libnautilus* \
notification-daemon tumbler* libtumbler*"
clear
apt-get --purge remove $deb_package_purge
}

package_console() {
local console_pkgs
console_pkgs="build-essential dkms module-assistant colordiff \
cryptsetup htop iproute iw lxsplit par2 pmount p7zip-full unrar \
unzip rsync sudo sl tmux vim whois xz-utils wpasupplicant"
clear
apt-get install -y $console_pkgs
}

package_xorg() {
local xorg_pkgs
xorg_pkgs="xorg x11-utils xbacklight xdotool xfonts-terminus xterm rxvt-unicode"
clear
apt-get install -y $xorg_pkgs
}

package_openbox() {
local openbox_pkgs
openbox_pkgs="openbox obconf eject feh flashplugin-nonfree gksu gsimplecal \
iceweasel icedtea-7-plugin openjdk-7-jre leafpad lxappearance \
lxappearance-obconf menu mirage network-manager-gnome pavucontrol \
qt4-qtconfig scrot suckless-tools tint2 thunar-volman vlc xarchiver \
xfce4-notifyd xfce4-power-manager xfce4-settings xfce4-volumed \
xscreensaver zenity"
clear
apt-get install -y $openbox_pkgs
}

package_theme() {
local ubuntu_ver
local cb_archive
local cb_icons
local cb_icons_deb
ubuntu_ver="trusty"
cb_archive="http://packages.crunchbang.org/waldorf/pool/main"
cb_icons="faenza-crunchbang-icon-theme"
cb_icons_deb="${cb_icons}_1.2-crunchang1_all.deb"

# Theme - Numix
# -------------
# * http://numixproject.org/
# * includes GTK2 + GTK3.6+ + Openbox + Xfce support
apt-get install -y gtk2-engines gtk2-engines-murrine libgnomeui-0
echo "### numix theme ###" >> $apt_sources_list
echo "deb http://ppa.launchpad.net/numix/ppa/ubuntu $ubuntu_ver main" >> $apt_sources_list 
echo "deb-src http://ppa.launchpad.net/numix/ppa/ubuntu $ubuntu_ver main" >> $apt_sources_list 
apt-get update
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0F164EEB
apt-get update
apt-get install -y numix-gtk-theme

# Icons - Faenza-Dark-Crunchbang
# ------------------------------
if [[ ! -e "${dpkg_info}/${cb_icons}.list" ]]
then
    clear
    wget -P $tmp_dir ${cb_archive}/${cb_icons_deb}
    dpkg -i ${tmp_dir}/$cb_icons_deb
fi

# Fonts - Droid Sans
# ------------------
apt-get install -y fonts-liberation fonts-droid

# Theme Config Utils
# ------------------
# * Openbox: obconf
# * GTK+LXDE: lxappearance
# * Xfce4: xfce4-settings-manager
# * QT: qtconfig-qt4
# * Xfce4: xfce4-settings
apt-get install -y obconf lxappearance lxappearance-obconf \
qt4-qtconfig xfce4-settings
}

package_extra() {
local cb_archive
local cb_pnmixer
local cb_pnmixer_deb
cb_archive="http://packages.crunchbang.org/waldorf/pool/main"
cb_pnmixer="pnmixer"
cb_pnmixer_deb="${cb_pnmixer}_0.5.1-crunchbang1_${deb_arch}.deb"

# pnmixer - volume mixer for the system tray
if [[ ! -e "${dpkg_info}/${cb_pnmixer}.list" ]]
then
    clear
    wget -P $tmp_dir ${cb_archive}/${cb_pnmixer_deb}
    dpkg -i ${tmp_dir}/$cb_pnmixer_deb
fi
}

config_branch() {
clear
echo_green "\nUpdating system and configuring Debian unstable branch...\n"
deb_branch="$deb_unstable"
apt_preferences_unstable
apt_sources_unstable
}

config_alternative() {
clear
update-alternatives --config editor
clear
update-alternatives --config x-terminal-emulator
}

config_desktop() {
clear
echo_green "\nInstalling Openbox...\n"
package_console
package_xorg
package_openbox
package_theme
package_extra
config_alternative
}

config_blacklist_pcspkr() {
local pcspkr_conf
pcspkr_conf="/etc/modprobe.d/pcspkr-blacklist.conf"

if [[ -e $pcspkr_conf ]]
then
    cp $pcspkr_conf ${pcspkr_conf}.$(date +%Y%m%dT%H%M%S).bak
fi
cat >> $pcspkr_conf << _EOF_
# shutdown that annoying beep
# note: always run 'update-initramfs -u -k all' after modifying modules
blacklist pcspkr
_EOF_
}

config_blacklist() {
clear
config_blacklist_pcspkr
update-initramfs -u -k all
}

config_group() {
set +e
local user_groups
user_groups="adm audio cdrom dialout dip floppy fuse netdev plugdev sudo \
vboxusers video users"

clear
read -p "What will be your (non-root) user name? > " user_name
echo_green "\nHello ${user_name}!\n"
sleep 2
if [[ ! -d /home/${user_name} ]]
then
    adduser $user_name
fi
for i in ${user_groups[@]}
do
    adduser $user_name $i
done
set -e
}

config_locale() {
clear
dpkg-reconfigure locales
}

config_timezone() {
clear
dpkg-reconfigure tzdata
}

cleanup() {
apt_package_purge
rm -rf $tmp_dir
}

au_revoir() {
clear
echo_yellow "$( penguinista ) .: All done!\n"
}

#: START
run_options "$@"
long_description
confirm_start
test_conditions

#: APT
config_branch
apt_keys
apt_package_list

#: CONFIGURE
config_desktop
config_blacklist
config_group
config_locale
config_timezone

#: FINISH
cleanup
au_revoir
