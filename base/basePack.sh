#!/bin/bash -e

set -o pipefail

export PK_INSALL_LOCATION=/opt
export PK_VERSION=0.11.0
export PK_FILENAME=packer_"$PK_VERSION"_linux_amd64.zip
export RES_AWS_CREDS="aws-bits-access"
export RES_PARAMS="baseami-params"
export REPO_RESOURCE_NAME="bldami-repo"
export DRY_TAG_RES="push-dry-tag"

# since resources here have dashes Shippable replaces them and UPPER cases them
export AMI_PARAMS=$(echo ${RES_PARAMS//-/} | awk '{print toupper($0)}')
export AMI_STRING=$AMI_PARAMS"_PARAMS"

# Now get AWS keys
export AWS_INT=$(echo ${RES_AWS_CREDS//-/} | awk '{print toupper($0)}')
export AWS_STRING=$AWS_INT"_INTEGRATION"

# set the repo path
export REPO_NAME=$(echo ${REPO_RESOURCE_NAME//-/} | awk '{print toupper($0)}')
export REPO_STR=$REPO_NAME"_PATH"

# set the drydock tag path
export DRYDOCK_TAG_STR=$(echo ${DRY_TAG_RES//-/} | awk '{print toupper($0)}')

setup_ssh(){
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  ls -al ~/.ssh/
  which ssh-agent
}

setup_params(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$AMI_STRING"_REGION")
  export VPC_ID=$(eval echo "$"$AMI_STRING"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$AMI_STRING"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$AMI_STRING"_SECURITY_GROUP_ID")
  export SOURCE_AMI=$(eval echo "$"$AMI_STRING"_SOURCE_AMI")

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$AWS_STRING"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$AWS_STRING"_AWS_SECRET_ACCESS_KEY")

  # get repo path
  export REPO_PATH=$(eval echo "$"$REPO_STR"/gitRepo")

  # get DRY DOCK tag
  export DRYDOCK_TAG=$(eval echo "$"$DRYDOCK_TAG_STR"_VERSIONNAME")

  # getting propertyBag values
  pushd $(eval echo "$"$DRYDOCK_TAG_STR"_PATH")
  export IMAGE_NAMES=$(jq -r '.version.propertyBag.IMAGE_NAMES' version.json)
  popd

  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "REPO_PATH=$REPO_PATH"
  echo "DRYDOCK_TAG=$DRYDOCK_TAG"

  echo "Images to be pulled --------->"
  for IMAGE_NAME in $IMAGE_NAMES; do
    echo $IMAGE_NAME
  done
  echo "end of images to be pulled --------->"
}

install_packer() {
  pushd $PK_INSALL_LOCATION
  echo "Fetching packer"
  echo "-----------------------------------"

  rm -rf $PK_INSALL_LOCATION/packer
  mkdir -p $PK_INSALL_LOCATION/packer

  wget -q https://releases.hashicorp.com/packer/$PK_VERSION/"$PK_FILENAME"
  apt-get install unzip
  unzip -o $PK_FILENAME -d $PK_INSALL_LOCATION/packer
  export PATH=$PATH:$PK_INSALL_LOCATION/packer
  echo "downloaded packer successfully"
  echo "-----------------------------------"
  
  local pk_version=$(packer version)
  echo "Packer version: $pk_version"
  popd
}

build_ami() {
  pushd $REPO_PATH/base
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate baseAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var 'aws_access_key='$AWS_ACCESS_KEY_ID \
    -var 'aws_secret_key='$AWS_SECRET_ACCESS_KEY \
    -var 'REGION='$REGION \
    -var 'VPC_ID='$VPC_ID \
    -var 'SUBNET_ID='$SUBNET_ID \
    -var 'SECURITY_GROUP_ID='$SECURITY_GROUP_ID \
    -var 'SOURCE_AMI='$SOURCE_AMI \
    -var 'DRYDOCK_TAG='$DRYDOCK_TAG \
    -var 'IMAGE_NAMES='$IMAGE_NAMES \
    baseAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo AMI_ID=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > /build/state/AMI_ID.txt
    cat /build/state/AMI_ID.txt
  popd
}

main() {
  setup_ssh
  setup_params
  install_packer
  build_ami
}

main
