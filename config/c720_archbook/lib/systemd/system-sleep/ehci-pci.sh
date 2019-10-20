#!/bin/bash

case $1/$2 in
  pre/*)
    # Unbind ehci for preventing error 
    echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
    ;;
  post/*)
    # Bind ehci for preventing error 
    echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/bind
    ;;
esac
