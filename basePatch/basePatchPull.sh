#!/bin/bash -e

exec_patch() {
  sudo docker pull shippable/minv2:latest
}

exec_patch
