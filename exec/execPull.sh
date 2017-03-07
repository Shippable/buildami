#!/bin/bash

set -e
set -o pipefail

readonly MESSAGE_STORE_LOCATION="/tmp/cexec"
readonly SHIPPABLE_RELEASE_VERSION="$REL_VER"
readonly KEY_STORE_LOCATION="/tmp/ssh"
readonly NODE_TYPE_CODE=7001
readonly SHIPPABLE_NODE_INIT=true
readonly NODE_DATA_LOCATION="/etc/shippable"
readonly NODE_LOGS_LOCATION="$NODE_DATA_LOCATION/logs"
readonly EXEC_REPO="https://github.com/Shippable/cexec.git"
readonly NODE_SCRIPTS_REPO="https://github.com/Shippable/node.git"
readonly COMPONENT="genExec"

readonly CEXEC_LOC="/home/shippable/cexec"
readonly NODE_SCRIPTS_LOC="/home/shippable/node"
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

validate_envs() {
  echo "Validating environment variables for AMI"

  if [ -z "$SHIPPABLE_RELEASE_VERSION" ] || [ "$SHIPPABLE_RELEASE_VERSION" == "" ]; then
    echo "SHIPPABLE_RELEASE_VERSION env not defined, exiting"
    exit 1
  else
    echo "SHIPPABLE_RELEASE_VERSION: $SHIPPABLE_RELEASE_VERSION"
  fi

  if [ -z "$SHIPPABLE_NODE_INIT_SCRIPT" ] || [ "$SHIPPABLE_NODE_INIT_SCRIPT" == "" ]; then
    echo "SHIPPABLE_NODE_INIT_SCRIPT env not defined, exiting"
    exit 1
  else
    echo "SHIPPABLE_NODE_INIT_SCRIPT: $SHIPPABLE_NODE_INIT_SCRIPT"
  fi
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
  sudo git clone $EXEC_REPO $CEXEC_LOC
}

clone_node_scripts() {
  if [ -d "$NODE_SCRIPTS_LOC" ]; then
    sudo rm -rf $NODE_SCRIPTS_LOC
  fi
  echo "Downloading Shippable node init repo"
  sudo mkdir -p $NODE_SCRIPTS_LOC
  sudo git clone $NODE_SCRIPTS_REPO $NODE_SCRIPTS_LOC
}

tag_cexec() {
  pushd $CEXEC_LOC
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  popd
}

tag_node_scripts() {
  pushd $NODE_SCRIPTS_LOC
  sudo git checkout master
  sudo git pull --tags
  sudo git checkout $REL_VER
  popd
}

update_envs() {
  local node_env_template=$NODE_SCRIPTS_LOC/usr/node.env.template
  local node_env=$NODE_DATA_LOCATION/node.env

  if [ ! -f "$node_env_template" ]; then
    echo "Node environment template file not found: $node_env_template"
    exit 1
  else
    echo "Node environment template file found: $node_env_template"
  fi

  echo "Writing node specific envs to $node_env"

  ## Setting the build time envs
  sed "s#{{NODE_TYPE_CODE}}#$NODE_TYPE_CODE#g" $node_env_template > $node_env
  sed -i "s#{{SHIPPABLE_NODE_INIT_SCRIPT}}#$SHIPPABLE_NODE_INIT_SCRIPT#g" $node_env
  sed -i "s#{{SHIPPABLE_NODE_INIT}}#$SHIPPABLE_NODE_INIT#g" $node_env
  sed -i "s#{{COMPONENT}}#$COMPONENT#g" $node_env
  sed -i "s#{{SHIPPABLE_RELEASE_VERSION}}#$SHIPPABLE_RELEASE_VERSION#g" $node_env
  sed -i "s#{{EXEC_REPO}}#$EXEC_REPO#g" $node_env

  ## Setting the runtime values to empty
  local default_value=""
  sed -i "s#{{LISTEN_QUEUE}}#$default_value#g" $node_env
  sed -i "s#{{NODE_ID}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_TOKEN}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_DEFAULT_EXCHANGE}}#$default_value#g" $node_env
  sed -i "s#{{RUN_MODE}}#$default_value#g" $node_env
  sed -i "s#{{JOB_TYPE}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_MOUNTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_OPTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_CONTAINER_NAME}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_IMAGE}}#$default_value#g" $node_env
  sed -i "s#{{IS_DOCKER_LEGACY}}#$default_value#g" $node_env

  echo "Successfully update node specific envs to $node_env"
  exec_cmd "cat $node_env"

  is_success=true
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
  clone_node_scripts
  tag_node_scripts
  update_envs
  pull_exec
}

main
echo "AMI init script completed"
