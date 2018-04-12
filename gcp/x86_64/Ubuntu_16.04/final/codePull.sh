#!/bin/bash -e

set -o pipefail

readonly MESSAGE_STORE_LOCATION="/tmp/cexec"
readonly REL_VER="$REL_VER"
readonly IMG_VER="$IMG_VER"
readonly KEY_STORE_LOCATION="/tmp/ssh"
readonly NODE_TYPE_CODE=7001
readonly SHIPPABLE_NODE_INIT=true
readonly NODE_DATA_LOCATION="/etc/shippable"
readonly NODE_LOGS_LOCATION="$NODE_DATA_LOCATION/logs"
readonly EXEC_REPO="https://github.com/Shippable/cexec.git"
readonly NODE_SCRIPTS_REPO="https://github.com/Shippable/node.git"

readonly CEXEC_LOC="/home/shippable/cexec"
readonly NODE_SCRIPTS_LOC="/root/node"

readonly REQPROC_IMG="drydock/u16reqproc"
readonly REQKICK_DIR="/var/lib/shippable/reqKick"
readonly REQKICK_REPO="https://github.com/Shippable/reqKick.git"
readonly NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOC/shipctl"
readonly NODE_ARCHITECTURE="x86_64"
readonly NODE_OPERATING_SYSTEM="Ubuntu_16.04"
readonly REPORTS_DOWNLOAD_URL="https://s3.amazonaws.com/shippable-artifacts/reports/$REL_VER/reports-$REL_VER-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

#temporary zephyr build speed up....
readonly ZEPHYR_IMG="zephyrprojectrtos/ci:v0.2"

set_context() {
  echo "Setting context for AMI"
  echo "REQPROC_IMG=$REQPROC_IMG"
  echo "CEXEC_LOC=$CEXEC_LOC"

  readonly REQPROC_IMG_WITH_TAG="$REQPROC_IMG:$REL_VER"
}

validate_envs() {
  echo "Validating environment variables for AMI"

  if [ -z "$REL_VER" ] || [ "$REL_VER" == "" ]; then
    echo "REL_VER env not defined, exiting"
    exit 1
  else
    echo "REL_VER: $REL_VER"
  fi

  if [ -z "$IMG_VER" ] || [ "$IMG_VER" == "" ]; then
    echo "IMG_VER env not defined, exiting"
    exit 1
  else
    echo "IMG_VER: $IMG_VER"
  fi
}

pull_images() {
  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < /tmp/images.txt))
  echo $IMAGE_NAMES_SPACED

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$IMG_VER"
    sudo docker pull $IMAGE_NAME:$IMG_VER
  done
}

clone_cexec() {
  if [ -d "$CEXEC_LOC" ]; then
    sudo rm -rf $CEXEC_LOC
  fi
  sudo git clone $EXEC_REPO $CEXEC_LOC
}

tag_cexec() {
  pushd $CEXEC_LOC
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  popd
}

fetch_reports() {
  local reports_dir="$CEXEC_LOC/bin"
  local reports_tar_file="reports.tar.gz"
  sudo rm -rf $reports_dir
  sudo mkdir -p $reports_dir
  pushd $reports_dir
    sudo wget $REPORTS_DOWNLOAD_URL -O $reports_tar_file
    sudo tar -xf $reports_tar_file
    sudo rm -rf $reports_tar_file
  popd
}

clone_node_scripts() {
  sudo rm -rf $NODE_SCRIPTS_LOC || true
  echo "Downloading Shippable node init repo"
  sudo mkdir -p $NODE_SCRIPTS_LOC
  sudo git clone $NODE_SCRIPTS_REPO $NODE_SCRIPTS_LOC
}

tag_node_scripts() {
  pushd $NODE_SCRIPTS_LOC
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  popd
}

pull_zephyr() {
  sudo docker pull $ZEPHYR_IMG
}

before_exit() {
  ## flush any remaining console
  echo $1
  echo $2

  echo "AMI build script completed"
}

install_nodejs() {
  pushd /tmp
  echo "Installing node 4.8.5"
  sudo wget https://nodejs.org/dist/v4.8.5/node-v4.8.5-linux-x64.tar.xz
  sudo tar -xf node-v4.8.5-linux-x64.tar.xz
  sudo cp -Rf node-v4.8.5-linux-x64/{bin,include,lib,share} /usr/local

  echo "Checking node version"
  node -v
  popd
}

install_shipctl() {
  echo "Installing shipctl components"
  eval "$NODE_SHIPCTL_LOCATION/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/install.sh"
}

clone_reqKick() {
  echo "cloning reqKick"
  sudo rm -rf $REQKICK_DIR || true
  sudo git clone $REQKICK_REPO $REQKICK_DIR
}

tag_reqKick() {
  echo "tagging reqKick"
  pushd $REQKICK_DIR
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  sudo npm install
  popd
}

pull_tagged_reqproc() {
  echo "pulling tagged reqproc image: $REQPROC_IMG_WITH_TAG"
  sudo docker pull $REQPROC_IMG_WITH_TAG
}

patch_name_server() {
  sudo sh -c "echo 'supersede domain-name-servers 8.8.8.8, 8.8.4.4;' >> /etc/dhcp/dhclient.conf"
}

clean_genexec() {
  echo "Remove any existing genExec image and related configs..."
#  sudo docker images | grep drydock/genexec | awk '{print $3}' | xargs sudo docker rmi || true
  sudo rm -rf /etc/shippable || true
}

main() {
  validate_envs
  set_context
  pull_images
  clone_cexec
  tag_cexec
  fetch_reports
  clone_node_scripts
  tag_node_scripts
  pull_zephyr
  install_nodejs
  install_shipctl
  clone_reqKick
  tag_reqKick
  pull_tagged_reqproc
  patch_name_server
  clean_genexec
}

echo "Running execPull script..."
trap before_exit EXIT
main
