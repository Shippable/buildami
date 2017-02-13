#!/bin/bash -e

export DOCKERHUB_ORG=drydock

export CURR_JOB="push_dry_tag"
export RES_VER="ship-ver"
export RES_DH="ship_dh"
export RES_REPO="bldami_repo"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_VER_UP=$(echo ${RES_VER//-/} | awk '{print toupper($0)}')

# get dockerhub EN string
export RES_DH_UP=$(echo $RES_DH | awk '{print toupper($0)}')
export RES_DH_INT_STR=$RES_DH_UP"_INTEGRATION"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

set_context() {
  export VERSION=$(eval echo "$"$RES_VER_UP"_VERSIONNAME")
  export DH_USERNAME=$(eval echo "$"$RES_DH_INT_STR"_USERNAME")
  export DH_PASSWORD=$(eval echo "$"$RES_DH_INT_STR"_PASSWORD")
  export DH_EMAIL=$(eval echo "$"$RES_DH_INT_STR"_EMAIL")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "RES_DH=$RES_DH"
  echo "RES_REPO=$RES_REPO"
  echo "RES_VER_UP=$RES_VER_UP"
  echo "RES_DH_UP=$RES_DH_UP"
  echo "RES_DH_INT_STR=$RES_DH_INT_STR"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"

  echo "VERSION=$VERSION"
  echo "DH_USERNAME=$DH_USERNAME"
  echo "DH_PASSWORD=${#DH_PASSWORD}" #show only count
  echo "DH_EMAIL=$DH_EMAIL"
}

get_image_list() {
  pushd "$RES_REPO_STATE/tagImage"
  export IMAGE_NAMES=$(cat images.txt)
  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < images.txt))
  popd

  echo "IMAGE_NAMES=$IMAGE_NAMES"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"

  # create a state file so that next job can pick it up
  echo "versionName=$VERSION" > /build/state/$CURR_JOB.env #adding version state
  echo "IMAGE_NAMES=$IMAGE_NAMES_SPACED" >> /build/state/$CURR_JOB.env
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

  # removing the images to save space
  if [ $IMAGE_NAME!="drydock/u16all" -a $IMAGE_NAME!="drydock/u14all" \
  -a $IMAGE_NAME!="drydock/u16" -a $IMAGE_NAME!="drydock/u16" ]; then
    echo "Removing image IMAGE_NAME"
    sudo docker rmi -f $PUSH_NAME
    sudo docker rmi -f $PULL_NAME
  fi
}

main() {
  set_context
  get_image_list
  #dockerhub_login
  #pull_tag_push_images
}

main
