#!/bin/bash -e

readonly CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly NODE_SCRIPTS_LOCATION="/root/node"
readonly BASE_DIR="/var/lib/shippable"
readonly REQKICK_DIR="$BASE_DIR/reqKick"
readonly REQPROC_MASTER_IMAGE="drydock/u16reqproc:master"
readonly NODE_ARCHITECTURE="x86_64"
readonly NODE_OPERATING_SYSTEM="CentOS_7"
readonly SHIPPABLE_RELEASE_VERSION="master"
readonly REPORTS_DOWNLOAD_URL="https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

clean_cexec() {
  if [ -d "$CEXEC_LOCATION_ON_HOST" ]; then
    sudo rm -rf $CEXEC_LOCATION_ON_HOST || true
  fi
}

clone_cexec() {
  sudo mkdir -p $CEXEC_LOCATION_ON_HOST
  sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOCATION_ON_HOST

  local reports_dir="$CEXEC_LOCATION_ON_HOST/bin"
  local reports_tar_file="reports.tar.gz"
  sudo rm -rf $reports_dir
  sudo mkdir -p $reports_dir
  pushd $reports_dir
    sudo wget $REPORTS_DOWNLOAD_URL -O $reports_tar_file
    sudo tar -xf $reports_tar_file
    sudo rm -rf $reports_tar_file
  popd
}

clean_node_scripts() {
  sudo rm -rf $NODE_SCRIPTS_LOCATION
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
    sudo /usr/local/bin/npm install
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
