#!/bin/bash -e

# TODO: If this gets used later for other kernels, get it from Packer.
KERNEL_VERSION="3.13.0-126"

sudo apt-get update
sudo apt-get install -y linux-image-$KERNEL_VERSION-generic \
  linux-headers-$KERNEL_VERSION

# GCE overrides the default path of grub from "/etc/default/grub" to "/etc/default/grub.d/50-cloudimg-settings.cfg".
sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Debian GNU\/Linux>Debian GNU\/Linux, with Linux $KERNEL_VERSION-generic\"/" /etc/default/grub.d/50-cloudimg-settings.cfg
sudo update-grub
