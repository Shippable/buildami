#!/bin/bash -e

export VERSION=""
export DOCKERHUB_ORG=drydock

export CURR_JOB=push-dry-tag
export RES_VER=ship-ver
export RES_DOCKERHUB_INTEGRATION=shipimg-dockerhub

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_VER_UP=$(echo ${RES_VER//-/} | awk '{print toupper($0)}')

# get dockerhub EN string
export RES_DH=$(echo ${RES_DOCKERHUB_INTEGRATION//-/} | awk '{print toupper($0)}')
export DH_STRING=$RES_DH"_INTEGRATION"

set_context() {
  export VERSION=$(eval echo "$"$RES_VER_UP"_VERSIONNAME")
  export DH_USERNAME=$(eval echo "$"$DH_STRING"_USERNAME")
  export DH_PASSWORD=$(eval echo "$"$DH_STRING"_PASSWORD")
  export DH_EMAIL=$(eval echo "$"$DH_STRING"_EMAIL")

  echo "VERSION=$VERSION"
  echo "DH_USERNAME=$DH_USERNAME"
  echo "DH_PASSWORD=${#DH_PASSWORD}" #show only count
  echo "DH_EMAIL=$DH_EMAIL"

  export IMAGE_NAMES="drydock/u14 \
  drydock/u16"

  # create a state file so that next job can pick it up
  echo "versionName=$VERSION" > /build/state/$CURR_JOB.env #adding version state
  echo "IMAGE_NAMES=$IMAGE_NAMES" >> /build/state/$CURR_JOB.env

}

dockerhub_login() {
  echo "Logging in to Dockerhub"
  echo "----------------------------------------------"
  sudo docker login -u $DH_USERNAME -p $DH_PASSWORD -e $DH_EMAIL
}

pull_tag_push_images() {
  for IMAGE_NAME in $IMAGE_NAMES; do
    __pull_tag_push_image $IMAGE_NAME
  done
}

__pull_tag_push_image() {
  if [[ -z "$1" ]]; then
    return 0
  fi

  IMAGE_NAME=$1
  PULL_NAME=$IMAGE_NAME":tip"
  PUSH_NAME=$IMAGE_NAME":"$VERSION

  echo "pulling image $PULL_NAME"
  sudo docker pull $PULL_NAME
  sudo docker tag -f $PULL_NAME $PUSH_NAME
  echo "pushing image $PUSH_NAME"
  sudo docker push $PUSH_NAME
}

main() {
  set_context
  dockerhub_login
  pull_tag_push_images
}

main
