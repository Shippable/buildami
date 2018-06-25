#!/bin/bash -e

echo "Copying 99-shippable.conf..."
sudo cp /tmp/99-shippable.conf /etc/sysctl.d/99-shippable.conf
