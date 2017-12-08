#!/bin/bash
set -e
set -o pipefail

readonly NODE_ARCHITECTURE="x86_64"
readonly NODE_OPERATING_SYSTEM="Ubuntu_14.04"
readonly LEGACY_CI_CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly SHIPPABLE_RELEASE_VERSION="master"
readonly EXEC_IMAGE="drydock/reqproc:master"
readonly REQKICK_DIR="/var/lib/shippable/reqKick"
readonly NODE_SCRIPTS_LOCATION="/root/node"
readonly NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOCATION/shipctl"
readonly INIT_SCRIPT_NAME="Docker_17.06.sh"

check_envs() {
  expected_envs=$1
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

__process_msg "cloning node repo"
git clone "https://github.com/Shippable/node" $NODE_SCRIPTS_LOCATION

__process_msg "Initializing node"
source "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
