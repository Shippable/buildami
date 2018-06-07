#!/bin/bash -e
pull_images() {
  echo "IMG_VER=$IMG_VER"

  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < /tmp/images.txt))
  echo $IMAGE_NAMES_SPACED

  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$IMG_VER"
    sudo docker pull $IMAGE_NAME:$IMG_VER
  done

  # Clean up master images if we are not building master.
  if [[ $IMG_VER != "master" ]]; then
    docker images | grep "master" | awk '{print $1 ":" $2}' | xargs -r docker rmi
  fi
}

pull_images
