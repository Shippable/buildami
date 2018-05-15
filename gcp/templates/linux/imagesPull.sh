#!/bin/bash -e
pull_images() {
  echo "IMG_VER=$IMG_VER"

  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < /tmp/images.txt))
  echo $IMAGE_NAMES_SPACED

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$IMG_VER"
    sudo docker pull $IMAGE_NAME:$IMG_VER
  done
}

pull_images
