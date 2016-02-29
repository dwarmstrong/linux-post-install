#!/bin/bash
set -eu

## Copyright (c) 2016 Daniel Wayne Armstrong. All rights reserved.
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License (GPLv2) published by
## the Free Software Foundation.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
## or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

NAME="sidition"
BLURB="debian _sid/unstable_ configuration"
GIT_SRC="https://github.com/vonbrownie/linux-post-install/tree/master/scripts/"

penguinista() {
cat << _EOF_

(O<
(/)_
_EOF_
}

echoRed() {
echo -e "\E[1;31m$1"
echo -e '\e[0m'
}

echoGreen() {
echo -e "\E[1;32m$1"
echo -e '\e[0m'
}

echoCyan() {
echo -e "\E[1;36m$1"
echo -e '\e[0m'
}

echoMagenta() {
echo -e "\E[1;35m$1"
echo -e '\e[0m'
}

header() {
echoCyan "$( penguinista ) .: $top ..."
}

footer() {
echoGreen "\n\nOK ... $bottom ..."
sleep 4
}

exitOK() {
echoGreen "\n$( penguinista ) .: Exiting ... Have a good day!"
exit
}

badRep() {
echoRed "\n'$REPLY' is invalid input ...\n"
}

badRepYN() {
echoRed "\n'$REPLY' is invalid input. Please select 'Y(es)' or 'N(o)' ...\n"
}

letsGo() {
local http0="http://www.circuidipity.com/minimal-debian.html"
local http1="http://www.circuidipity.com/i3-tiling-window-manager.html"
clear
echoCyan "$( penguinista ) .: $NAME -- $BLURB :."
cat << _EOF_
Howdy! Ideally this script is run immediately following the first successful
boot into your new Debian installation.

Building on a minimal install [0] ... the system will be configured to track
Debian's _sid/unstable_ branch, and the i3 tiling window manager [1] plus a
collection of packages suitable for a workstation will be installed.

[0] "Minimal Debian" <$http0>
[1] "i3 wm" <$http1>

_EOF_
while :
do
    read -n 1 -p "Run script now? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echoGreen "\n\nLet's roll then..."
        sleep 4
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        exitOK
    else
        badRepYN
    fi
done
}

testRoot() {
local message="$NAME requires ROOT privileges to do its job."
if [[ $UID -ne 0 ]]; then
    echoRed "$( penguinista ) .: $message"
    exit 1
fi
}

testConnect() {
local message="$NAME requires an active network interface."
if ! $(ip addr show | grep "state UP" &>/dev/null); then
    echoRed "$( penguinista ) .: $message"
    echo "INTERFACES FOUND"
    ip link
    exit 1
fi
}

testUnit() {
local unit="systemctl --failed"
local top="List failed units with '$unit'"
local bottom="Moving onward"
clear
header
while :
do
    read -n 1 -p "Run test? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo ""
        $unit
        while :
        do
            read -n 1 -p "Continue script? [yN] > "
            if [[ $REPLY == [yY] ]]; then
                break
            elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
                exitOK
            else
                badRepYN
            fi
        done
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        break
    else
        badRepYN
    fi
done
footer
}

testErr() {
local err="journalctl -p 0..3 -xn"
local top="Look for high priority errors with '$err'"
local bottom="Moving onward"
clear
header
while :
do
    read -n 1 -p "Run test? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo ""
        $err
        while :
        do
            read -n 1 -p "Continue script? [yN] > "
            if [[ $REPLY == [yY] ]]; then
                break
            elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
                exitOK
            else
                badRepYN
            fi
        done
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        break
    else
        badRepYN
    fi
done
footer
}

testTime() {
local top="Confirm date + timezone"
local tDZ="/usr/bin/timedatectl"
local tDZ2="$(date -I'minutes')"
local bottom="Moving onward"
clear
header
if [[ -x $tDZ ]]; then
    $tDZ
    echo ""
else
    echo -e "Current date is $(echoMagenta $tDZ2)"
fi
while :
do
    read -n 1 -p "Modify? [yN] > "
    if [[ $REPLY == [yY] ]]; then
        echo -e "\n\nOK ... Check out datetime in the Arch Wiki"`
        `"- https://wiki.archlinux.org/index.php/time - and\n"`
        `"also the 'sudo dpkg-reconfigure tzdata' command for configuring"`
        `" the default timezone."
        exitOK
    elif [[ $REPLY == [nN] || $REPLY == "" ]]; then
        break
    else
        badRepYN
    fi
done
footer
}

instApt() {
## Configure system to track _sid/unstable_
local list="/etc/apt/sources.list"
local mirror="http://httpredir.debian.org/debian/"
cp $list ${list}.$(date +%FT%H%M%S).bak && \
    echo -e "deb $mirror unstable main contrib non-free" > $list && \
    echo -e "#deb-src $mirror unstable main contrib non-free" >> $list && \
    echo -e "\ndeb $mirror experimental main" >> $list
}


instUU() {
local top="Upgrade system to latest packages"
local bottom="Moving onward"
local console="cowsay cryptsetup figlet htop keychain less most pmount rsync
sl sudo tmux unzip vim wget whois"
clear; header; sleep 4
apt update && apt -y full-upgrade && apt -y install $console && footer
}

instX() {
local top="Install X environment"
local bottom="Moving onward"
local xOrg="xorg xinput xterm rxvt-unicode-256color xfonts-terminus xbindkeys
xbacklight xvkbd fonts-liberation"
clear; header; sleep 4
apt -y install $xOrg && footer
}

instWM() {
local bottom="Moving onward"
local i3="i3 i3status i3lock dunst rofi"
##
## Styling ##
## I use Ambiance Colors [0] + Vibrancy Color Icon [1] themes. Download the
## *.deb files separately and install. Depends: gtk2-engines-{murrine,pixbuf}
##
## [0] http://www.ravefinity.com/p/download-ambiance-radiance-colors.html
## [1] http://www.ravefinity.com/p/vibrancy-colors-gtk-icon-theme.html
##
## Ubuntu fonts [2] ... Download the *.zip file, unpack, and install the *.ttf 
## in /usr/local/share/fonts/truetype/ttf-ubuntu
##
## [2] http://font.ubuntu.com/
##
## Theming for QT5 apps can be configured using the qt5ct utility. Download
## the qt5ct package available on the WebUpd8 PPA [3] and install.
## 
## [3] http://ppa.launchpad.net/nilarimogard/webupd8/ubuntu/pool/main/q/qt5ct/
##
## My HOWTO: http://www.circuidipity.com/i3-tiling-window-manager.html
## 
local theme="gnome-themes-standard gtk2-engines-murrine gtk2-engines-pixbuf
lxappearance qt4-qtconfig"
local sl="/usr/games/sl"
clear; echo ""; figlet 'OK...'; figlet 'Here'; figlet 'comes'; \
    figlet 'i3 ...'; sleep 4; clear; $sl
apt -y install $i3 $theme && footer
}

instPkg() {
local top="Install some favourite packages suitable for a desktop environment"
local bottom="Moving onward"
local sound="pulseaudio pulseaudio-utils pavucontrol alsa-utils sox"
local net="iceweasel default-jre icedtea-plugin transmission-gtk"
local av="flashplugin-nonfree ffmpeg vlc"
local image="eog scrot geeqie gimp gimp-help-en gimp-data-extras"
local doc="libreoffice libreoffice-help-en-us libreoffice-gnome
hunspell-en-ca qpdfview"
local devel="build-essential bc git"
clear; header; sleep 4
## Sometimes apt gets stuck on a slow download ... breaking up downloads
## speeds things up ...
apt -y install $sound && \
    apt -y install $net && \
    apt -y install $av && \
    apt -y install $image && \
    apt -y install $doc && \
    apt -y install $devel && \
    footer
}

confAlt() {
local top="Configure symbolic links determining default commands"
local bottom="Moving onward"
clear; header; update-alternatives --config editor
clear; header; update-alternatives --config pager
clear; header; update-alternatives --config x-terminal-emulator; footer
}

auRevoir() {
local message="That should get you started ... Goodbye"
local figlet="/usr/bin/figlet"
local cowsay="/usr/games/cowsay"
clear
if [[ -x $figlet ]] && [[ -x $cowsay ]]; then
    echoGreen "$($figlet -f mini $message | $cowsay -n -f dragon-and-cow)"
else
    echoGreen "$( penguinista ) .: $message"
fi
}

##: START
## Run a few tests before we begin ...
testRoot
testConnect
## ... OK then ...
letsGo
testUnit
testErr
testTime
instApt
instUU
instX
instWM  # Hint: Comment out this line ...
instPkg # and this one to skip i3 and/or extra pkg install
confAlt
auRevoir
