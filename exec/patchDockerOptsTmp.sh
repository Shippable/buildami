#!/bin/bash -e
set -o pipefail

patch_docker_config() {
  echo "Patching docker opts"
  echo "-----------------------------------"

  config_location="/etc/default/docker"
  # Remove any old configs first.
  sudo sed -i '/^DOCKER_OPTS/d' $config_location
  # Apply opts.
  opts='DOCKER_OPTS="$DOCKER_OPTS -H unix:///var/run/docker.sock -g=/data --storage-driver aufs --dns 8.8.8.8 --dns 8.8.4.4"'
  sudo sh -c "echo '$opts' >> $config_location"
}

main() {
  patch_docker_config
}

main
