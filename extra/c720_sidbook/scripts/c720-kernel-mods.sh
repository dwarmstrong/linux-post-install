#!/bin/bash
set -e

# * Modified for Debian sid/unstable from ChrUbuntu's cros-haswell-modules.sh
#   https://googledrive.com/host/0B0YvUuHHn3MndlNDbXhPRlB2eFE/cros-haswell-modules.sh
# * ... and the Arch Linux C720 adaptation ...
#   http://pastie.org/pastes/8763538/text

# Script variables
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

func_done() {
echo_green "\n... done!\n"
$goto_sleep
}

penguinista() {
cat << _EOF_

(0<
(/)_
_EOF_
}

# Test for ROOT privileges
if [[ $UID -ne 0 ]]
then
    echo_red "\n$( penguinista ) .:This script requires ROOT privileges to do its job.\n"
    exit 1
fi

# Create a temporary directory for our work
TEMPBUILD=$(mktemp -d)
cd $TEMPBUILD

# Determine kernel version
#KERNPKG=$(uname -r)
#KERNVER=$(uname -v | awk '{print $4}' | cut -d '-' -f 1)
KERNVER="3.13.10"
KERNPKG="3.13-1-amd64"

# Install necessary deps to build a kernel
clear
echo_green "\n$( penguinista ) .: Installing build dependencies for $KERNVER kernel ...\n"
apt-get build-dep -y linux-image-${KERNPKG}
func_done

# Grab kernel source
clear
echo_green "\n$( penguinista ) .: Fetching kernel source ...\n"
wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNVER}.tar.xz
echo_green "\nExtracting kernel sources ...\n"
tar xJvf linux-${KERNVER}.tar.xz
cd linux-${KERNVER}
func_done

# Use Benson Leung's post-Pixel Chromebook patches:
# https://patchwork.kernel.org/bundle/bleung/chromeos-laptop-deferring-and-haswell/
# Note: drivers/platform/x86/chromeos* moved to drivers/platform/chrome/chromeos*
PLATFORM="chrome"
clear
echo_green "\n$( penguinista ) .: Applying Chromebook Haswell Patches ...\n"
for patch in 3078491 3078481 3074391 3074441 3074421 3074401 3074431 3074411; do
  wget -O - https://patchwork.kernel.org/patch/${patch}/raw/ \
  | sed "s/drivers\/platform\/x86\/chromeos_laptop.c/drivers\/platform\/$PLATFORM\/chromeos_laptop.c/g" \
  | patch -p1
done

# Need this
cp /usr/src/linux-headers-${KERNPKG}/Module.symvers .

# Prep tree
cat /boot/config-${KERNPKG} > ./.config
echo "CONFIG_CHROMEOS_LAPTOP=m" >> ./.config
make oldconfig
make prepare
make modules_prepare

echo_green "\nBuilding relevant modules ...\n"
# Build only the needed directories
make SUBDIRS=drivers/platform/$PLATFORM modules
make SUBDIRS=drivers/i2c/busses modules

echo_green "\nInstalling relevant modules ...\n"
# switch to using our new chromeos_laptop.ko module
# preserve old as DATE.bak
CHROME_LAP="/lib/modules/${KERNPKG}/kernel/drivers/platform/${PLATFORM}/chromeos_laptop.ko"
DATE=$(date +%Y-%m-%dT%H%M%S)
CHROME_LAP_BAK="${CHROME_LAP}.${DATE}.bak"
if [ -f $CHROME_LAP ];
then
    mv $CHROME_LAP $CHROME_LAP_BAK
fi
cp drivers/platform/${PLATFORM}/chromeos_laptop.ko /lib/modules/${KERNPKG}/kernel/drivers/platform/${PLATFORM}/

# switch to using our new designware i2c modules
# preserve old as DATE.bak
I2C_CORE="/lib/modules/${KERNPKG}/kernel/drivers/i2c/busses/i2c-designware-core.ko"
I2C_CORE_BAK="${I2C_CORE}.${DATE}.bak"
I2C_PCI="/lib/modules/${KERNPKG}/kernel/drivers/i2c/busses/i2c-designware-pci.ko"
I2C_PCI_BAK="${I2C_PCI}.${DATE}.bak"
mv $I2C_CORE $I2C_CORE_BAK 
mv $I2C_PCI $I2C_PCI_BAK
cp drivers/i2c/busses/i2c-designware-*.ko /lib/modules/${KERNPKG}/kernel/drivers/i2c/busses/
depmod -a $KERNPKG
func_done

clear
echo_green "\n$( penguinista ) .: Installing xserver-xorg-input-synaptics ..."
apt-get -y install xserver-xorg-input-synaptics
func_done

# Cleanup
rm -rf $TEMPBUILD

echo_green "\nTouchpad will be enabled after reboot!"
$goto_sleep
