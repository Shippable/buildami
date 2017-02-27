#!/bin/bash -e

readonly CEXEC_LOC="/home/shippable/cexec"
readonly GENEXEC_IMG="shipimg/genexec"

set_context() {

  echo "REL_VER=$REL_VER"
  echo "GENEXEC_IMG=$GENEXEC_IMG"
  echo "CEXEC_LOC=$CEXEC_LOC"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"

  readonly GENEXEC_IMG_WITH_TAG="$GENEXEC_IMG:$REL_VER"
}

pull_images() {
  for IMAGE_NAME in $IMAGE_NAMES_SPACED; do
    echo "Pulling -------------------> $IMAGE_NAME:$REL_VER"
    sudo docker pull $IMAGE_NAME:$REL_VER
  done
}

tag_cexec() {
  pushd $CEXEC_LOC
  git pull --tags
  git checkout $REL_VER
  popd
}

pull_exec() {
  sudo docker pull $GENEXEC_IMG_WITH_TAG
}

main() {
  set_context
  pull_images
  tag_cexec
  pull_exec
}

main
echo "AMI init script completed"
