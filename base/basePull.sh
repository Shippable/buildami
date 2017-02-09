#!/bin/bash -e
pull_images() {
  echo "DRYDOCK_TAG=$DRYDOCK_TAG"

  for IMAGE_NAME in $IMAGE_NAMES; do
    echo "Pulling -------------------> $IMAGE_NAME:$DRYDOCK_TAG"
    sudo docker pull $IMAGE_NAME:$DRYDOCK_TAG
  done
}

pull_images
