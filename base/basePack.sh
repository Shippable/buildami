#!/bin/bash -e

set -o pipefail

export CURR_JOB="build_baseami"
export RES_AWS_CREDS="aws_bits_access"
export RES_PARAMS="baseami_params"
export RES_REPO="bldami_repo"
export RES_IMG="u16_img"
export SHIPPABLE_RELEASE_VERSION="master"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

# set the drydock tag path
export RES_IMG_UP=$(echo $RES_IMG | awk '{print toupper($0)}')
export RES_IMG_VER_NAME=$(eval echo "$"$RES_IMG_UP"_VERSIONNAME")
export RES_IMG_VER_NAME_DASH=${RES_IMG_VER_NAME//./-}

set_context(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$RES_PARAMS_STR"_SECURITY_GROUP_ID")
  export SOURCE_AMI=$(eval echo "$"$RES_PARAMS_STR"_SOURCE_AMI")
  export SHIPPABLE_NODE_INIT_SCRIPT=$(eval echo "$"$RES_PARAMS_STR"_SHIPPABLE_NODE_INIT_SCRIPT")

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"
  echo "RES_REPO=$RES_REPO"
  echo "RES_IMG=$RES_IMG"
  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_IMG_UP=$RES_IMG_UP"

  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"
  echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH"
  echo "SHIPPABLE_NODE_INIT_SCRIPT=$SHIPPABLE_NODE_INIT_SCRIPT"
}

get_image_list() {
  pushd "$RES_REPO_STATE/base"
  export IMAGE_NAMES=$(cat images.txt)
  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < images.txt))
  popd

  echo "IMAGE_NAMES=$IMAGE_NAMES"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"
}

build_ami() {
  pushd "$RES_REPO_STATE/base"
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate baseAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var SOURCE_AMI=$SOURCE_AMI \
    -var IMAGE_NAMES_SPACED="${IMAGE_NAMES_SPACED}" \
    -var RES_IMG_VER_NAME=$RES_IMG_VER_NAME \
    -var RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH \
    -var SHIPPABLE_RELEASE_VERSION=$SHIPPABLE_RELEASE_VERSION \
    -var SHIPPABLE_NODE_INIT_SCRIPT=$SHIPPABLE_NODE_INIT_SCRIPT \
    baseAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

    echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
    echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$JOB_STATE/$CURR_JOB.env"
    echo "SHIPPABLE_NODE_INIT_SCRIPT=$SHIPPABLE_NODE_INIT_SCRIPT" >> "$JOB_STATE/$CURR_JOB.env"
    cat "$JOB_STATE/$CURR_JOB.env"
  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  get_image_list
  build_ami
}

main
