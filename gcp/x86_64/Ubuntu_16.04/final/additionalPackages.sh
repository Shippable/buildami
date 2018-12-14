#!/bin/bash -e
set -e
set -o pipefail

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

before_exit() {
  ## flush any remaining console
  echo $1
  echo $2
  __process_msg "Additional packages script completed"
}

install_rngtools() {
  __process_msg "installing rng-tools for entropy"
  apt-get install -y rng-tools=5-0ubuntu3
}

__process_marker "installing additional packages"
trap before_exit EXIT
install_rngtools
