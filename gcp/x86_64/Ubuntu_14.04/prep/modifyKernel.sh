#!/bin/bash -e

if [[ "$MODIFY_KERNEL" == "true" ]]; then
  if [[ -z "$KERNEL_VER" ]]; then
    echo "Failed to find env KERNEL_VER."
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y linux-image-$KERNEL_VER-generic \
    linux-headers-$KERNEL_VER

  # GCE overrides the default path of grub from "/etc/default/grub" to "/etc/default/grub.d/50-cloudimg-settings.cfg".
  sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Debian GNU\/Linux>Debian GNU\/Linux, with Linux $KERNEL_VER-generic\"/" /etc/default/grub.d/50-cloudimg-settings.cfg
  sudo update-grub
fi
