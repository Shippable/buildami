#!/bin/bash -e
waitForApt() {
  echo "checking for the apt-get resource"
  time (while ps -opid= -C apt-get > /dev/null; do sleep 1m; echo 'waiting for apt-get resource to get free'; done);
}

waitForApt
