#!/bin/bash
set -eu

# Copyright (c) 2015 Daniel Wayne Armstrong. All rights reserved.
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License (GPLv2) published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for more details.

scriptName="raspbian-post-install.sh"
scriptBlurb="configure Raspbian on Raspberry Pi"
scriptProject="https://github.com/vonbrownie/linux-post-install"
scriptSrc="${scriptProject}/blob/master/scripts/${scriptName}"

release="jessie"

echoRed() {
echo -e "\E[1;31m$1"
echo -e '\e[0m'
}

echoGreen() {
echo -e "\E[1;32m$1"
echo -e '\e[0m'
}

echoYellow() {
echo -e "\E[1;33m$1"
echo -e '\e[0m'
}

echoBlue() {
echo -e "\E[1;34m$1"
echo -e '\e[0m'
}

echoMagenta() {
echo -e "\E[1;35m$1"
echo -e '\e[0m'
}

echoCyan() {
echo -e "\E[1;36m$1"
echo -e '\e[0m'
}

penguinista() {
cat << _EOF_

(O<
(/)_
_EOF_
}

scriptDetails() {
echo "$( penguinista ) .: $scriptName -- $scriptBlurb :."
echo "USAGE"
echo -e "\t$scriptName [OPTION]"
echo "OPTIONS"
echo -e "\t-h\t$scriptName details"
}

runOptions() {
while getopts ":h" OPT
do
    case $OPT in
        h)
            scriptDetails
            exit 0
            ;;
        *)
            echoRed "$( penguinista ) .: Invalid option '-$OPTARG'"
            exit 1
            ;;
    esac
done
}

moreDetails() {
clear
scriptDetails
echo
cat << _EOF_
Howdy! Ideally this script is run following a fresh installation
of Raspbian using *raspbian-ua-netinst*:

* Minimal Raspbian Jessie
  http://www.circuidipity.com/minimal-raspbian-jessie.html
* raspbian-ua-netinst
  http://github.com/debian-pi/raspbian-ua-netinst
* $scriptName
  $scriptSrc

This system will be configured to track Raspbian's "${release}" branch. 

_EOF_
}

invalidReply() {
echoRed "\n'$REPLY' is invalid input...\n"
}

invalidReplyYN() {
echoRed "\n'$REPLY' is invalid input. Please select 'Y(es)' or 'N(o)'...\n"
}

confirmStart() {
while :
do
    read -n 1 -p "Run script now? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
        echoGreen "\nLet's roll then...\n"
        sleep 4
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
        penguinista
        exit
    else
        invalidReplyYN
    fi
done
}

testRoot() {
local message
message="$scriptName requires ROOT privileges to do its job."
if [[ $UID -ne 0 ]]
then
    echoRed "\n$( penguinista ) .: $message\n"
    exit 1
fi
}

interfaceFound() {
    ip link | awk '/mtu/ {gsub(":",""); printf "\t%s", $2} END {printf "\n"}'
}

testConnect() {
local message
message="$scriptName requires an active network interface."
if ! $(ip addr show | grep "state UP" &>/dev/null)
then
    echoRed "\n$( penguinista ) .: $message"
    echo -e "\nINTERFACES FOUND\n"
    interfaceFound
    exit 1
fi
}

testConditions() {
    testRoot
    testConnect
}

configRoot() {
clear
while :
do
    read -n 1 -p "Change root password? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
        echo
	passwd
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
        break
    else
        invalidReplyYN
    fi
done
}

configLocales() {
clear
dpkg-reconfigure locales
sleep 4
}

configTimezone() {
clear
dpkg-reconfigure tzdata
sleep 4
}

outputDone() {
echoGreen "\nDone!"
sleep 4
}

configSwap() {
clear
while :
do
    read -n 1 -p "Create swapfile(size=1GB)? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
	echo -e "\nOK... Creating /swap...\n"
        dd if=/dev/zero of=/swap bs=1M count=1024 && mkswap /swap \
            && echo "/swap none swap sw 0 0" >> /etc/fstab && outputDone
        break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
        break
    else
        invalidReplyYN
    fi
done
}

configApt() {
clear
local list
list="/etc/apt/sources.list"
local deb1
deb1="deb http://mirrordirector.raspbian.org/raspbian $release main"
local deb2
deb2="deb http://archive.raspbian.org/raspbian $release main"
cp $list ${list}.$(date +%FT%H:%M:%S.%N%Z).bak
echo "$deb1 contrib non-free firmware rpi" > $list
echo "$deb2" >> $list
echo -e "\nUpgrading the Pi to '$release'...\n"
sleep 4
apt-get update && apt-get -y dist-upgrade && apt-get -y autoremove && outputDone
}

addPkgs() {
clear
local pkgs
echo -e "\nInstalling a few extra packages...\n"
pkgs="apt-file apt-utils aptitude cowsay htop figlet keychain rsync sl whois"
apt-get -y install $pkgs && outputDone
}

addRNG() {
clear
echo -e "\nEnabling the hardware random number generator...\n"
apt-get -y install rng-tools && echo "bcm2708-rng" >> /etc/modules && outputDone
}

configSudo() {
clear
while :
do
    read -n 1 -p "Grant $username sudo privileges? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
	echo -e "\nOK... Assigning $1 to sudo group...\n"
	apt-get -y install sudo && usermod -a -G sudo $1 && outputDone
	break
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
	break
    else
	invalidReplyYN
    fi
done
}

addUser() {
clear
while :
do
    read -n 1 -p "Add another user to $HOSTNAME? [yN] > "
    if [[ $REPLY == [yY] ]]
    then
        echo
        read -p "Username? > " username
        adduser $username && configSudo $username
    elif [[ $REPLY == [nN] || $REPLY == "" ]]
    then
        break
    else
        invalidReplyYN
    fi
done
}

auRevoir() {                                                                    
clear                                                                           
local message                                                                   
message="All done! Say 'Howdy!' to $release."
local cowsay
cowsay="/usr/games/cowsay"                                      
if [ -x $cowsay ]                                                     
then                                                                            
    echoGreen "$($cowsay $message)"                                            
else                                                                            
    echoGreen "$message"                                                        
fi                                                                              
}
 
#: START
runOptions "$@"
moreDetails
confirmStart
testConditions
configRoot
configLocales
configTimezone
configSwap
configApt
addPkgs
addRNG
addUser
auRevoir
