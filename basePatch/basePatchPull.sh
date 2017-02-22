#!/bin/bash -e

readonly CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"

clean_cexec() {
  if [ -d "$CEXEC_LOCATION_ON_HOST" ]; then
    exec_cmd "sudo rm -rf $CEXEC_LOCATION_ON_HOST"
  fi
}

clone_cexec() {
  mkdir -p $CEXEC_LOCATION_ON_HOST
  sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOCATION_ON_HOST
}

main() {
  clean_cexec
  clone_cexec
}

main
