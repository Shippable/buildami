#!/bin/bash -e

readonly CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly NODE_SCRIPTS_LOCATION="/tmp/shippable/node"

clean_cexec() {
  if [ -d "$CEXEC_LOCATION_ON_HOST" ]; then
    exec_cmd "sudo rm -rf $CEXEC_LOCATION_ON_HOST"
  fi
}

clone_cexec() {
  sudo mkdir -p $CEXEC_LOCATION_ON_HOST
  sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOCATION_ON_HOST
}

clean_node_scripts() {
  if [ -d "$NODE_SCRIPTS_LOCATION" ]; then
    exec_cmd "sudo rm -rf $NODE_SCRIPTS_LOCATION"
  fi
}

clone_node_scripts() {
  sudo mkdir -p $NODE_SCRIPTS_LOCATION
  sudo git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
}

main() {
  clean_cexec
  clone_cexec
  clean_node_scripts
  clone_node_scripts
}

main
