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
script_name="c720-sidbook-post-install-main.sh"
script_description="configure Debian's _sid_ branch on the Acer C720 Chromebook"
script_git="https://github.com/vonbrownie"
script_src="source: ${script_git}/linux-post-install/blob/master/${script_name}"
script_synopsis="usage: $script_name [ OPTION ] [ PACKAGE_LIST ]"
goto_sleep="sleep 4"

# Script global directory variables
tmp_dir="/tmp/tmp.sidbook-post-install"
current_dir="."
extra_dir="${current_dir}/extra/c720_sidbook"
extra_doc="${extra_dir}/doc"
extra_etc="${extra_dir}/etc"
extra_lib="${extra_dir}/lib"
extra_scripts="${extra_dir}/scripts"

# Debian variables
deb_unstable="sid"
deb_arch=$(dpkg --print-architecture)
apt_pref="/etc/apt/preferences"
apt_src_list="/etc/apt/sources.list"
deb_archive="http://http.debian.net/debian/"
dpkg_info="/var/lib/dpkg/info"
deb_pkg_list=""

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
Howdy! Ideally this script is run following a fresh installation of Debian GNU/Linux
on the Acer C720 Chromebook.

See "From Chromebook to Sidbook" for details:
http://www.circuidipity.com/c720-sidbook.html

This script configures the Chromebook to track Debian's _${deb_unstable}_/unstable branch and
installs the lightweight Openbox window manager + extra apps suitable for a desktop
environment.

## TIP ##
Import a list of packages that duplicate the configuration from another system running
Debian _${deb_unstable}_.

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
cryptsetup htop iproute iw lxsplit par2 pmount pulseaudio-utils \
p7zip-full unrar unzip rsync sudo sl tmux vim whois xz-utils \
wpasupplicant"

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

pkg_kernel() {
local deb_snapshot
local pool
local kernel_ver
local chbk_kernel
local chbk_head
local chbk_head_common
local chbk_kbuild
deb_snapshot="http://snapshot.debian.org/archive/debian"
pool="pool/main/l/linux"
kernel_ver="3.13.10"
chbk_kernel="linux-image-3.13-1-${deb_arch}_${kernel_ver}-1_${deb_arch}.deb"
chbk_head="linux-headers-3.13-1-${deb_arch}_${kernel_ver}-1_${deb_arch}.deb"
chbk_head_common="linux-headers-3.13-1-common_${kernel_ver}-1_${deb_arch}.deb"
chbk_kbuild="linux-kbuild-3.13_3.13.6-1_${deb_arch}.deb"

clear
echo_green "\n$( penguinista ) .: Installing $kernel_ver kernel ...\n"
$goto_sleep
wget -P $tmp_dir ${deb_snapshot}/20140320T042639Z/${pool}-tools/${chbk_kbuild}
dpkg -i ${tmp_dir}/${chbk_kbuild}
wget -P $tmp_dir ${deb_snapshot}/20140416T101543Z/${pool}/${chbk_head_common}
dpkg -i ${tmp_dir}/${chbk_head_common}
wget -P $tmp_dir ${deb_snapshot}/20140416T101543Z/${pool}/${chbk_head}
dpkg -i ${tmp_dir}/${chbk_head}
wget -P $tmp_dir ${deb_snapshot}/20140416T101543Z/${pool}/${chbk_kernel}
dpkg -i ${tmp_dir}/${chbk_kernel}
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

conf_skel() {
local skel_extra
local xbindkeysrc
skel_extra="${extra_etc}/skel"
xbindkeysrc="${skel_extra}/.xbindkeysrc"

clear
echo_green "$( penguinista ) .: Configuring default user settings ...\n"
$goto_sleep
cp $xbindkeysrc /etc/skel/
func_done
}

conf_branch() {
clear
echo_green "$( penguinista ) .: Tracking Debian _${deb_unstable}_ ...\n"
$goto_sleep
apt_pref_unstable
apt_src_unstable
func_done
}

conf_touchpad() {
local xorg_conf
local touchpad_conf
local sdbk_touchpad
xorg_conf="/etc/X11/xorg.conf.d"
touchpad_conf="${xorg_conf}/50-c720-touchpad.conf"
sdbk_touchpad="${extra_etc}/X11/xorg.conf.d/50-c720-touchpad.conf"

clear
echo_green "$( penguinista ) .: Configuring touchpad ...\n"
$goto_sleep
if [[ -e $touchpad_conf ]]
then
    cp $touchpad.conf ${touchpad_conf}.$(date +%Y%m%dT%H%M%S).bak
fi
if [[ ! -d $xorg_conf ]]
then
    mkdir $xorg_conf
fi
cp $sdbk_touchpad $touchpad_conf
func_done
}

conf_suspend() {
local snd_suspend
local wakeup_conf
local sdbk_wakeup
local sdbk_snd_suspend
snd_suspend="/lib/system-sleep/cros-sound-suspend.sh"
wakeup_conf="/etc/tmpfiles.d/cros-acpi-wakeup.conf"
sdbk_wakeup="${extra_etc}/tmpfiles.d/cros-acpi-wakeup.conf"
sdbk_snd_suspend="${extra_lib}/systemd/system-sleep/cros-sound-suspend.sh"

clear
echo_green "$( penguinista ) .: Configuring suspend|resume ...\n"
$goto_sleep
if [[ -e $snd_suspend ]]
then
    cp $snd_suspend ${snd_suspend}.$(date +%Y%m%dT%H%M%S).bak
    cp $sdbk_snd_suspend $snd_suspend
fi
if [[ -e $wakeup_conf ]]
then
    cp $wakeup_conf ${wakeup_conf}.$(date +%Y%m%dT%H%M%S).bak
    cp $sdbk_wakeup $wakeup_conf
fi
func_done
}

conf_alternative() {
clear
update-alternatives --config editor

clear
update-alternatives --config x-terminal-emulator
}

conf_desktop() {
clear
pkg_console
pkg_xorg
pkg_kernel
pkg_openbox
pkg_theme
pkg_extra
conf_touchpad
conf_suspend
conf_alternative
}

conf_blacklist_pcspkr() {
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

conf_blacklist() {
clear
conf_blacklist_pcspkr
update-initramfs -u -k all
}

conf_group() {
set +e

local user_groups
local x_keys
user_groups="adm audio cdrom dialout dip floppy fuse netdev plugdev sudo \
vboxusers video users"
x_keys=".xbindkeysrc"

clear
echo_green "$( penguinista ) .: Configuring users and groups ...\n"
read -p "What will be your (non-root) user name? > " user_name
echo_green "\nHello ${user_name}!\n"
$goto_sleep

# Default groups
clear
echo_green "$( penguinista ) .: Adding $user_name to groups ...\n"
$goto_sleep
if [[ ! -d /home/${user_name} ]]
then
    adduser $user_name
fi
for i in ${user_groups[@]}
do
    adduser $user_name $i
done
func_done

# Configure chromebook function keys
clear
echo_green "$( penguinista ) .: Configuring function keys ...\n"
$goto_sleep
cp /etc/skel/${x_keys} /home/${user_name}
chown ${user_name}.${user_name} /home/${user_name}/${x_keys}
chmod 644 /home/${user_name}/${x_keys}
func_done

set -e
}

conf_locale() {
clear
dpkg-reconfigure locales
}

conf_timezone() {
clear
dpkg-reconfigure tzdata
}

conf_grub() {
local grub_conf
local sdbk_grub
grub_conf="/etc/default/grub"
sdbk_grub="${extra_etc}/default/grub"

clear
echo_green "$( penguinista ) .: Configuring GRUB ...\n"
$goto_sleep
cp $grub_conf ${grub_conf}.$(date +%Y%m%dT%H%M%S).bak
cp $sdbk_grub $grub_conf
update-grub
func_done
}

conf_scripts() {
# After installing Debian the C720 touchpad is non-functional and requires
# compiling new kernel modules.
${extra_scripts}/c720-kernel-mods.sh
}

cleanup() {
apt_pkg_purge
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
conf_branch
apt_keys
apt_pkg_list

#: CONFIGURE
conf_skel
conf_desktop
conf_blacklist
conf_group
conf_locale
conf_timezone
conf_grub
conf_scripts

#: FINISH
cleanup
au_revoir
