#!/bin/bash -e
pull_images() {
  echo "RES_DRY_TAG_VER_NAME=$RES_DRY_TAG_VER_NAME"

  for IMAGE_NAME in $IMAGE_NAMES; do
    echo "Pulling -------------------> $IMAGE_NAME:$RES_DRY_TAG_VER_NAME"
    sudo docker pull $IMAGE_NAME:$RES_DRY_TAG_VER_NAME
  done
}

pull_images
