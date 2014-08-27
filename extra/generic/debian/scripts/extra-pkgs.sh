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
script_name="extra-pkgs.sh"
script_description="install extra Debian packages"
script_git="https://github.com/vonbrownie"
script_src="source: ${script_git}/linux-post-install/blob/master/extra/generic/debian/scripts/${script_name}"
script_synopsis="usage: $script_name"
goto_sleep="sleep 4"

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

long_description() {
clear
echo_yellow "$( penguinista ) .: $script_name - $script_description :."
echo_cyan "$script_src"
echo_cyan "$script_synopsis"
cat << _EOF_

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
            exit 1
            ;;
        *)
            echo_red "\n$( penguinista ) .: Invalid option '-$OPTARG'\n"
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

apt_update() {
clear
echo_green "\n$( penguinista ) .: Updating package list ...\n"
$goto_sleep
apt-get update
func_done
}

pkg_console() {
local console_pkgs
console_pkgs="apt-listbugs apt-listchanges build-essential dkms \
module-assistant colordiff cryptsetup dselect htop iproute iw \
lxsplit mlocate par2 pmount pulseaudio-utils p7zip-full python-dev \
python-pip python-virtualenv unrar unzip rsync sudo sl tmux vim \
whois xz-utils wpasupplicant"

clear
echo_green "\n$( penguinista ) .: Installing console packages ...\n"
$goto_sleep
apt-get install -y $console_pkgs
func_done
}

pkg_xorg() {
local xorg_pkgs
local x_extra_pkgs
xorg_pkgs="xorg x11-utils xbacklight xbindkeys xdotool xfonts-terminus \
xterm rxvt-unicode"
x_extra_pkgs="flashplugin-nonfree geeqie gimp gimp-data-extras \
gimp-help-en hardinfo icedtea-7-plugin iceweasel mirage openjdk-7-jre \
qpdfview scrot transmission vlc"

clear
echo_green "\n$( penguinista ) .: Installing X packages ...\n"
$goto_sleep
apt-get install -y $xorg_pkgs $x_extra_pkgs
func_done
}

au_revoir() {
clear
echo_yellow "$( penguinista ) .: All done!\n"
}

#: START
run_options "$@"
long_description
confirm_start

#: PACKAGES
apt_update
pkg_console
pkg_xorg

#: FINISH
au_revoir
