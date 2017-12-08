#!/bin/bash -e
pull_images() {
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$RES_IMG_VER_NAME"
    sudo docker pull $IMAGE_NAME:$RES_IMG_VER_NAME
  done
}

# TODO: commented out for testing. should be removed once done
# pull_images
