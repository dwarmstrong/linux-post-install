#!/bin/bash

case $1/$2 in
  pre/*)
    # Unbind ehci for preventing error 
    echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
    # Unbind snd_hda_intel for sound
    echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
    echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
    ;;
  post/*)
    # Bind ehci for preventing error 
    echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/bind
    # bind snd_hda_intel for sound
    echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
    echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
    ;;
esac
