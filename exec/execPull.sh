#!/bin/bash -e

readonly CEXEC_LOC="/home/shippable/cexec"
readonly GENEXEC_IMG="shipimg/genexec"
readonly CPP_IMAGE_NAME="drydock/u14cppall"
readonly CPP_IMAGE_TAG="prod"

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

pull_cpp_prod_image() {
  if [ -n "$CPP_IMAGE_NAME" ] && [ -n "$CPP_IMAGE_TAG" ]; then
    echo "CPP_IMAGE_NAME=$CPP_IMAGE_NAME"
    echo "CPP_IMAGE_TAG=$CPP_IMAGE_TAG"

    echo "Pulling -------------------> $CPP_IMAGE_NAME:$CPP_IMAGE_TAG"
    sudo docker pull $CPP_IMAGE_NAME:$CPP_IMAGE_TAG
  fi
}

clone_cexec() {
  if [ -d "$CEXEC_LOC" ]; then
    sudo rm -rf $CEXEC_LOC
  fi
  sudo git clone https://github.com/Shippable/cexec.git $CEXEC_LOC
}

tag_cexec() {
  pushd $CEXEC_LOC
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  popd
}

pull_exec() {
  sudo docker pull $GENEXEC_IMG_WITH_TAG
}

main() {
  set_context
  pull_images
  pull_cpp_prod_image
  clone_cexec
  tag_cexec
  pull_exec
}

main
echo "AMI init script completed"
