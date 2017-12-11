#!/bin/bash -e

readonly CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly NODE_SCRIPTS_LOCATION="/home/shippable/node"
readonly BASE_DIR="/var/lib/shippable"
readonly REQKICK_DIR="$BASE_DIR/reqKick"
readonly REQPROC_MASTER_IMAGE="drydock/reqproc:master"

clean_cexec() {
  if [ -d "$CEXEC_LOCATION_ON_HOST" ]; then
    sudo rm -rf $CEXEC_LOCATION_ON_HOST || true
  fi
}

clone_cexec() {
  sudo mkdir -p $CEXEC_LOCATION_ON_HOST
  sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOCATION_ON_HOST
}

clean_node_scripts() {
  if [ -d "$NODE_SCRIPTS_LOCATION" ]; then
    sudo rm -rf $NODE_SCRIPTS_LOCATION || true
  fi
}

clone_node_scripts() {
  sudo mkdir -p $NODE_SCRIPTS_LOCATION
  sudo git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
}

clean_reqKick () {
  echo "Cleaning reqKick..."
  sudo rm -rf $REQKICK_DIR || true
}

clone_reqKick () {
  echo "Cloning reqKick..."
  sudo git clone https://github.com/Shippable/reqKick.git $REQKICK_DIR

  pushd $REQKICK_DIR
    sudo git checkout $SHIPPABLE_RELEASE_VERSION
    sudo npm install
  popd
}

pull_reqProc () {
  sudo docker pull $REQPROC_MASTER_IMAGE
}

main() {
  clean_cexec
  clone_cexec
  clean_node_scripts
  clone_node_scripts
  clean_reqKick
  clone_reqKick
  pull_reqProc
}

main
