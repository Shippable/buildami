#!/bin/bash -e
set -e
set -o pipefail

readonly NODE_ARCHITECTURE="$ARCHITECTURE"
readonly NODE_OPERATING_SYSTEM="$OS"
readonly NODE_DOWNLOAD_URL="$NODE_DOWNLOAD_URL"
readonly INIT_SCRIPT_NAME="Docker_$DOCKER_VER.sh"
readonly EXEC_IMAGE="$REQPROC_IMAGE"
readonly REQKICK_DOWNLOAD_URL="$REQKICK_DOWNLOAD_URL"
readonly CEXEC_DOWNLOAD_URL="$CEXEC_DOWNLOAD_URL"
readonly REPORTS_DOWNLOAD_URL="$REPORTS_DOWNLOAD_URL"

readonly NODE_SCRIPTS_TMP_LOC="/tmp/node.tar.gz"
readonly NODE_SCRIPTS_LOCATION="/root/node"
readonly NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOCATION/shipctl"
readonly LEGACY_CI_CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly REQKICK_DIR="/var/lib/shippable/reqKick"

readonly IS_SWAP_ENABLED=false
export install_docker_only=false

#temporary zephyr build speed up....
readonly ZEPHYR_IMG="zephyrprojectrtos/ci:v0.2"

check_envs() {
    local expected_envs=(
    'ARCHITECTURE'
    'OS'
    'DOCKER_VER'
    'REQPROC_IMAGE'
    'REQKICK_DOWNLOAD_URL'
    'CEXEC_DOWNLOAD_URL'
    'REPORTS_DOWNLOAD_URL'
  )

  for env in "${expected_envs[@]}"
  do
    env_value=$(eval "echo \$$env")
    if [ -z "$env_value" ]; then
      echo "Missing ENV: $env"
      exit 1
    fi
  done
}

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
  echo -e "     $error"
}

before_exit() {
  ## flush any remaining console
  echo $1
  echo $2
  echo "AMI build script completed"
}

fetch_node_scripts() {
  rm -rf $NODE_SCRIPTS_LOCATION || true
  mkdir -p $NODE_SCRIPTS_LOCATION

  __process_msg "downloading node scripts tarball"
  wget $NODE_DOWNLOAD_URL -O $NODE_SCRIPTS_TMP_LOC

  __process_msg "extracting node scripts"
  tar -xzvf $NODE_SCRIPTS_TMP_LOC -C $NODE_SCRIPTS_LOCATION --strip-components=1
}

pull_zephyr() {
  docker pull $ZEPHYR_IMG
}

main() {
  check_envs
  fetch_node_scripts
#  pull_zephyr
}

echo "Running execRefresh script..."
trap before_exit EXIT

__process_msg "Initializing node"
source "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"

main
