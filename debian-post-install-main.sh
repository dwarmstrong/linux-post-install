#!/bin/bash
set -eu

# Copyright (c) 2014 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

# Script variables
script_name="debian-post-install-main.sh"
script_description="_stable|testing|unstable_ branch configuration"
script_git="https://github.com/vonbrownie"
script_src="source: ${script_git}/linux-post-install/blob/master/${script_name}"
script_synopsis="usage: $script_name [ OPTION ] [ PACKAGE_LIST ]"
goto_sleep="sleep 4"

# Script global directory variables
tmp_dir="/tmp/tmp.debian-post-install"
current_dir="."
extra_dir="${current_dir}/extra"

# Debian variables
deb_stable="wheezy"
deb_testing="jessie"
deb_unstable="sid"
deb_arch=$(dpkg --print-architecture)
apt_pref="/etc/apt/preferences"
apt_src_list="/etc/apt/sources.list"
deb_archive="http://http.debian.net/debian/"
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

func_done() {
echo_green "\n... done!\n"
$goto_sleep
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
  Install packages from _package-list.txt_:
  (as_root)# ./$script_name -i package-list.txt

_EOF_
}

long_description() {
clear
echo_yellow "$( penguinista ) .: $script_name - $script_description :."
echo_cyan "$script_src"
echo_cyan "$script_synopsis"
available_options
cat << _EOF_
Howdy! Ideally this script is run following a fresh installation of
Debian GNU/Linux.

See: "Debian Wheezy Minimal Install"
http://www.circuidipity.com/install-debian-wheezy-screenshot-tour.html

"Install Debian using grml-debootstrap"
http://www.circuidipity.com/grml-debootstrap.html

This system will be configured to track a choice of Debian's _${deb_stable}_/stable,
_${deb_testing}_/testing, or _${deb_unstable}_/unstable branch with the option of installing the
Openbox window manager + extra apps suitable for a desktop environment.

## TIP ##
Import a list of packages that duplicate the configuration from another
system running Debian.

See: "Duplicate Debian package selection on multiple machines"
http://www.circuidipity.com/dpkg-duplicate.html

... and run script with option '-i' and name of package list.

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
            deb_pkg_list="$OPTARG"
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
echo_red "\n'$REPLY' is invalid input ...\n"
}

invalid_reply_yn() {
echo_red "\n'$REPLY' is invalid input. Please select 'Y(es)' or 'N(o)' ...\n"
}

confirm_start() {
while :
do
    read -n 1 -p "Run script now? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
        echo_green "\nLet's roll then ...\n"
        $goto_sleep
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

test_pkg_list() {
if [[ ! -z $deb_pkg_list && ! -e $deb_pkg_list ]]
then
    echo_red "\n$( penguinista ) .: '$deb_pkg_list' not found.\n"
    exit 1
fi
}

test_conditions() {
test_root
test_connect
test_pkg_list
}

apt_pref_stable() {
if [[ -e $apt_pref ]]
then
    cp $apt_pref ${apt_pref}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_pref ...\n"
$goto_sleep
cat > $apt_pref << _EOF_
# Configure default preferences in package installation
# * unlisted repositories are auto-ranked 500
# * installed packages are ranked 100

Package: *
Pin: release n=${deb_stable}
Pin-Priority: 900
_EOF_
func_done
}

apt_pref_testing() {
if [[ -e $apt_pref ]]
then
    cp $apt_pref ${apt_pref}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_pref ...\n"
$goto_sleep
cat > $apt_pref << _EOF_
# Configure default preferences in package installation
# * unlisted repositories are auto-ranked 500
# * installed packages are ranked 100

Package: *
Pin: release n=${deb_testing}
Pin-Priority: 900
_EOF_
func_done
}

apt_pref_unstable() {
if [[ -e $apt_pref ]]
then
    cp $apt_pref ${apt_pref}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_pref ...\n"
$goto_sleep
cat > $apt_pref << _EOF_
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
func_done
}

apt_update() {
clear
echo_green "\n$( penguinista ) .: Updating package list ...\n"
$goto_sleep
apt-get update
func_done
}

apt_src_stable() {
if [[ -e $apt_src_list ]]
then
    cp $apt_src_list ${apt_src_list}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_src_list ...\n"
$goto_sleep
cat > $apt_src_list << _EOF_
### $deb_stable ###
deb $deb_archive $deb_stable main contrib non-free
deb-src $deb_archive $deb_stable main contrib non-free

### $deb_stable security ###
deb http://security.debian.org/ ${deb_stable}/updates main contrib non-free
#deb-src http://security.debian.org/ ${deb_stable}/updates main contrib non-free

### ${deb_stable}-updates ###
deb $deb_archive ${deb_stable}-updates main non-free contrib
#deb-src deb $deb_archive ${deb_stable}-updates main non-free contrib 

### backports ###
deb $deb_archive ${deb_stable}-backports main contrib non-free
deb http://mozilla.debian.net/ ${deb_stable}-backports iceweasel-release

### multimedia ###
deb http://www.deb-multimedia.org $deb_stable main non-free

_EOF_
func_done
apt_update
}

apt_src_testing() {
if [[ -e $apt_src_list ]]
then
    cp $apt_src_list ${apt_src_list}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_src_list ...\n"
$goto_sleep
cat > $apt_src_list << _EOF_
### $deb_testing ###
deb $deb_archive $deb_testing main contrib non-free
deb-src $deb_archive $deb_testing main contrib non-free

### $deb_testing security ###
deb http://security.debian.org/ ${deb_testing}/updates main contrib non-free
#deb-src http://security.debian.org/ ${deb_testing}/updates main contrib non-free

### multimedia ###
deb http://www.deb-multimedia.org $deb_testing main non-free

_EOF_
func_done
apt_update
}

apt_src_unstable() {
if [[ -e $apt_src_list ]]
then
    cp $apt_src_list ${apt_src_list}.$(date +%Y%m%dT%H%M%S).bak
fi

clear
echo_green "\n$( penguinista ) .: Configuring $apt_src_list ...\n"
$goto_sleep
cat > $apt_src_list << _EOF_
### unstable ###
deb $deb_archive unstable main contrib non-free
deb-src $deb_archive unstable main contrib non-free

### experimental ###
deb $deb_archive experimental main

### multimedia ###
deb http://www.deb-multimedia.org unstable main non-free

_EOF_
func_done
apt_update
}

apt_keys() {
clear
echo_green "\n$( penguinista ) .: Installing archive keys ...\n"
$goto_sleep
apt-get install -y debian-archive-keyring
apt-get install deb-multimedia-keyring
apt-get install pkg-mozilla-archive-keyring
func_done
apt_update

clear
echo_green "\n$( penguinista ) .: Upgrading system ...\n"
$goto_sleep 
apt-get -y dist-upgrade
func_done
}

apt_pkg_list() {
local deb_pkgs
deb_pkgs=$(mktemp)

if [[ ! -z $deb_pkg_list && -e $deb_pkg_list ]]
then
    clear
    echo_green "\n$( penguinista ) .: Importing $deb_pkg_list and installing packages ...\n"
    $goto_sleep
    apt-cache dumpavail > "$deb_pkgs"
    dpkg --merge-avail "$deb_pkgs"
    rm -f "$deb_pkgs"
    dpkg --clear-selections
    dpkg --set-selections < $deb_pkg_list
    apt-get dselect-upgrade
    func_done
fi
}

apt_pkg_purge() {
local deb_pkg_purge
deb_pkg_purge="gdm3 gnome-system-tools nautilus* libnautilus* \
notification-daemon tumbler* libtumbler*"

clear
echo_green "\n$( penguinista ) .: Purging packages ...\n"
echo_red "$deb_pkg_purge"
$goto_sleep
apt-get --purge remove $deb_pkg_purge
func_done
}

pkg_console() {
local console_pkgs
console_pkgs="build-essential dkms module-assistant colordiff \
cryptsetup htop iproute iw lxsplit par2 pmount p7zip-full unrar \
unzip rsync sudo sl tmux vim whois xz-utils wpasupplicant"

clear
echo_green "\n$( penguinista ) .: Installing console packages ...\n"
$goto_sleep
apt-get install -y $console_pkgs
func_done
}

pkg_xorg() {
local xorg_pkgs
xorg_pkgs="xorg x11-utils xbacklight xbindkeys xdotool xfonts-terminus \
xterm rxvt-unicode"

clear
echo_green "\n$( penguinista ) .: Installing X packages ...\n"
$goto_sleep
apt-get install -y $xorg_pkgs
func_done
}

pkg_openbox() {
local ob_pkgs
ob_pkgs="openbox obconf eject feh gksu gsimplecal leafpad \
menu mirage network-manager-gnome pavucontrol scrot suckless-tools \
tint2 thunar-volman xarchiver xfce4-notifyd xfce4-power-manager \
xfce4-settings xfce4-volumed xscreensaver zenity"

clear
echo_green "\n$( penguinista ) .: Installing Openbox ...\n"
$goto_sleep
apt-get install -y $ob_pkgs
func_done
}

pkg_theme() {
local ubuntu_ver
local desktop_theme
local numix_ppa
local theme_pkgs
local desktop_theme_pkg
local cb_archive
local cb_icons
local cb_icons_deb
local deb_fonts
local deb_theme_conf
ubuntu_ver="trusty"
desktop_theme="Numix"
numix_ppa="http://ppa.launchpad.net/numix/ppa/ubuntu $ubuntu_ver main"
theme_pkgs="gtk2-engines gtk2-engines-murrine libgnomeui-0"
desktop_theme_pkg="numix-gtk-theme"
cb_archive="http://packages.crunchbang.org/waldorf/pool/main"
cb_icons="faenza-crunchbang-icon-theme"
cb_icons_deb="${cb_icons}_1.2-crunchang1_all.deb"
deb_fonts="fonts-liberation fonts-droid"
deb_theme_conf="obconf lxappearance lxappearance-obconf \
qt4-qtconfig xfce4-settings"

# Theme - Numix
# -------------
# * http://numixproject.org/
# * includes GTK2 + GTK3.6+ + Openbox + Xfce support
clear
echo_green "\n$( penguinista ) .: Installing $desktop_theme theme ...\n"
$goto_sleep
echo "" >> $apt_src_list
echo "### numix theme ###" >> $apt_src_list
echo "deb $numix_ppa" >> $apt_src_list
echo "deb-src $numix_ppa" >> $apt_src_list
apt-get update
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0F164EEB
apt-get update
apt-get install -y $theme_pkgs
apt-get install -y $desktop_theme_pkg
func_done

# Icons - Faenza-Dark-Crunchbang
# ------------------------------
if [[ ! -e "${dpkg_info}/${cb_icons}.list" ]]
then
    clear
    echo_green "\n$( penguinista ) .: Installing $cb_icons ...\n"
    $goto_sleep
    wget -P $tmp_dir ${cb_archive}/${cb_icons_deb}
    dpkg -i ${tmp_dir}/${cb_icons_deb}
    func_done
fi

# Fonts - Droid Sans
# ------------------
clear
echo_green "\n$( penguinista ) .: Installing fonts ...\n"
$goto_sleep
apt-get install -y $deb_fonts
func_done

# Theme Config Utils
# ------------------
# * Openbox: obconf, lxappearance-obconf
# * GTK+LXDE: lxappearance
# * Xfce4: xfce4-settings-manager
# * QT: qt4-qtconfig
# * Xfce4: xfce4-settings
clear
echo_green "\n$( penguinista ) .: Installing theme utilities ...\n"
$goto_sleep
apt-get install -y $deb_theme_conf
func_done
}

pkg_backport() {
local backport_pkgs
backport_pkgs="iceweasel"

if [[ $deb_branch == $deb_stable ]]
then
    clear
    echo_green "\n$( penguinista ) .: Installing backported packages ...\n"
    $goto_sleep
    apt-get install -y -t ${deb_stable}-backports $backport_pkgs
    func_done
fi
}

pkg_extra() {
local extra_debs
local cb_archive
local cb_pnmixer
extra_debs="flashplugin-nonfree iceweasel icedtea-7-plugin openjdk-7-jre \
rxvt-unicode vlc"
cb_archive="http://packages.crunchbang.org/waldorf/pool/main"
cb_pnmixer="pnmixer_0.5.1-crunchbang1_${deb_arch}.deb"

clear
echo_green "\n$( penguinista ) .: Installing extra packages ...\n"
$goto_sleep
# extra debian pkgs
apt-get -y install $extra_debs

# pnmixer - volume mixer for the system tray
if [[ ! -e "${dpkg_info}/pnmixer.list" ]]
then
    wget -P $tmp_dir ${cb_archive}/${cb_pnmixer}
    dpkg -i ${tmp_dir}/${cb_pnmixer}
fi
func_done
}

conf_branch() {
clear
while :
do
echo_green "$( penguinista ) .: Please select the default Debian branch for packages:"
cat << _EOF_
0) ${deb_stable}/stable
1) ${deb_testing}/testing
2) ${deb_unstable}/unstable

_EOF_

read -n 1 -p "Your choice? [0-2] > "

case $REPLY in
    0)
        echo_green "\nOK. System will be configured to track the stable branch ...\n"
        $goto_sleep
        deb_branch="$deb_stable"
        apt_pref_stable
        apt_src_stable
        func_done
        break
        ;;
    1)
        echo_green "\nOK. System will be configured to track the testing branch ...\n"
        $goto_sleep
        deb_branch="$deb_testing"
        apt_pref_testing
        apt_src_testing
        func_done
        break
        ;;
    2)
        echo_green "\nOK. System will be configured to track the unstable branch ...\n"
        $goto_sleep
        deb_branch="$deb_unstable"
        apt_pref_unstable
        apt_src_unstable
        func_done
        break
        ;;
    *)
        invalid_reply
        ;;
esac
done
}

config_alternative() {
clear
update-alternatives --config editor

clear
update-alternatives --config x-terminal-emulator
}

config_desktop() {
clear
while :
do
echo_green "$( penguinista ) .: Please select console-only or Openbox:"
cat << _EOF_
0) Do not install an X environment
1) Openbox - lightweight window manager

_EOF_

read -n 1 -p "Your choice? [0-1] > "

case $REPLY in
    0)
        echo_green "\nOK. No X environment will be installed ...\n"
        $goto_sleep
        package_console
        break
        ;;
    1)
        echo_green "\nOK. Installing Openbox ...\n"
        $goto_sleep
        package_console
        package_xorg
        package_openbox
        package_theme
        package_backport
        package_extra
        config_alternative
        break
        ;;
    *)
        invalid_reply
        ;;
esac
done
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
echo_green "$( penguinista ) .: Configuring users and groups ...\n"
read -p "What will be your (non-root) user name? > " user_name
echo_green "\nHello ${user_name}!\n"
$goto_sleep
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
