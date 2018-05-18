#!/bin/bash -e
set -e
set -o pipefail

readonly NODE_ARCHITECTURE="$ARCHITECTURE"
readonly NODE_OPERATING_SYSTEM="$OS"
readonly NODE_DOWNLOAD_URL="$NODE_DOWNLOAD_URL"
readonly EXEC_IMAGE="$REQPROC_IMAGE"
readonly REQKICK_DOWNLOAD_URL="$REQKICK_DOWNLOAD_URL"
readonly CEXEC_DOWNLOAD_URL="$CEXEC_DOWNLOAD_URL"
readonly REPORTS_DOWNLOAD_URL="$REPORTS_DOWNLOAD_URL"

readonly NODE_SCRIPTS_TMP_LOC="/tmp/node.tar.gz"
readonly NODE_SCRIPTS_LOCATION="/root/node"
readonly NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOCATION/shipctl"
readonly LEGACY_CI_CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly REQKICK_DIR="/var/lib/shippable/reqKick"

#temporary zephyr build speed up....
readonly ZEPHYR_IMG="zephyrprojectrtos/ci:v0.2"
readonly CPP_IMAGE="drydock/u14cppall:prod"

exec_cmd() {
  local cmd=$@
  eval $cmd
}

exec_grp() {
  local group_name=$1
  eval "$group_name"
}
__process_marker() {
  local prompt="$@"
  echo ""
  echo "# $(date +"%T") #######################################"
  echo "# $prompt"
  echo "##################################################"
}

__process_msg() {
  local message="$@"
  echo "|___ $@"
}

__process_error() {
  local message="$1"
  local error="$2"
  local bold_red_text='\e[91m'
  local reset_text='\033[0m'

  echo -e "$bold_red_text|___ $message$reset_text"
  echo -e "$error"
}

check_envs() {
    local expected_envs=(
    'ARCHITECTURE'
    'OS'
    'NODE_DOWNLOAD_URL'
    'REQPROC_IMAGE'
    'REQKICK_DOWNLOAD_URL'
    'CEXEC_DOWNLOAD_URL'
    'REPORTS_DOWNLOAD_URL'
  )

  for env in "${expected_envs[@]}"
  do
    env_value=$(eval "echo \$$env")
    if [ -z "$env_value" ] || [ "$env_value" == "" ]; then
      echo "Missing ENV: $env"
      exit 1
    fi
  done
}

fetch_cexec() {
  __process_marker "Fetching cexec..."
  local cexec_tar_file="cexec.tar.gz"

  if [ -d "$LEGACY_CI_CEXEC_LOCATION_ON_HOST" ]; then
    exec_cmd "rm -rf $LEGACY_CI_CEXEC_LOCATION_ON_HOST"
  fi
  rm -rf $cexec_tar_file
  pushd /tmp
    wget $CEXEC_DOWNLOAD_URL -O $cexec_tar_file
    mkdir -p $LEGACY_CI_CEXEC_LOCATION_ON_HOST
    tar -xzf $cexec_tar_file -C $LEGACY_CI_CEXEC_LOCATION_ON_HOST --strip-components=1
    rm -rf $cexec_tar_file
  popd

  # Download and extract reports bin file into a path that cexec expects it in
  local reports_dir="$LEGACY_CI_CEXEC_LOCATION_ON_HOST/bin"
  local reports_tar_file="reports.tar.gz"
  rm -rf $reports_dir
  mkdir -p $reports_dir
  pushd $reports_dir
    wget $REPORTS_DOWNLOAD_URL -O $reports_tar_file
    tar -xf $reports_tar_file
    rm -rf $reports_tar_file
  popd
}

fetch_reqKick() {
  __process_marker "Fetching reqKick..."
  local reqKick_tar_file="reqKick.tar.gz"

  rm -rf $REQKICK_DIR
  rm -rf $reqKick_tar_file
  pushd /tmp
    wget $REQKICK_DOWNLOAD_URL -O $reqKick_tar_file
    mkdir -p $REQKICK_DIR
    tar -xzf $reqKick_tar_file -C $REQKICK_DIR --strip-components=1
    rm -rf $reqKick_tar_file
  popd
  pushd $REQKICK_DIR
    npm install
  popd
}

fetch_node_scripts() {
  rm -rf $NODE_SCRIPTS_LOCATION || true
  mkdir -p $NODE_SCRIPTS_LOCATION

  __process_msg "downloading node scripts tarball"
  wget $NODE_DOWNLOAD_URL -O $NODE_SCRIPTS_TMP_LOC

  __process_msg "extracting node scripts"
  tar -xzvf $NODE_SCRIPTS_TMP_LOC -C $NODE_SCRIPTS_LOCATION --strip-components=1
}

install_shipctl() {
  echo "Installing shipctl components"
  eval "$NODE_SHIPCTL_LOCATION/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/install.sh"
}

pull_reqProc() {
  __process_marker "Pulling reqProc..."
  docker pull $EXEC_IMAGE
}

pull_zephyr() {
  __process_marker "Pulling zephyr..."
  docker pull $ZEPHYR_IMG
}

pull_cpp_prod_image() {
  __process_marker "Pulling cpp image..."
  docker pull $CPP_IMAGE
}

before_exit() {
  __process_marker "Flushing any remaining consoles..."
  echo $1
  echo $2
}

main() {
  check_envs
  fetch_cexec
  fetch_reqKick
  fetch_node_scripts
  install_shipctl
  pull_reqProc
  pull_zephyr
  pull_cpp_prod_image
}

echo "Running execRefresh script..."
trap before_exit EXIT
main
