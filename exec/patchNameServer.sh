#!/bin/bash -e
set -o pipefail

patch_name_server() {
  sudo sh -c "echo 'supersede domain-name-servers 8.8.8.8, 8.8.4.4;' >> /etc/dhcp/dhclient.conf"
}

main() {
  patch_name_server
}

main
