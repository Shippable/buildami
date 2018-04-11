#!/bin/bash -e
pull_images() {
  echo "RES_IMG_VER_NAME=$REL_VER"

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$REL_VER"
    sudo docker pull $IMAGE_NAME:$REL_VER
  done
}

pull_images
