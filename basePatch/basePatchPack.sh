#!/bin/bash -e

set -o pipefail

export PK_INSALL_LOCATION=/opt
export PK_VERSION=0.12.2
export PK_FILENAME=packer_"$PK_VERSION"_linux_amd64.zip

export CURR_JOB="patch-baseami"
export RES_AWS_CREDS="aws-bits-access"
export RES_PARAMS="baseami-params"
export RES_REPO="bldami-repo"
export RES_BASE_AMI="build-baseami"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo ${RES_PARAMS//-/} | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo ${RES_AWS_CREDS//-/} | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# set the repo path
export RES_REPO_UP=$(echo ${RES_REPO//-/} | awk '{print toupper($0)}')
export RES_REPO_PATH=$RES_REPO_UP"_PATH"

# set the base-ami path
export RES_BASE_AMI_UP=$(echo ${RES_BASE_AMI//-/} | awk '{print toupper($0)}')

setup_ssh(){
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  ls -al ~/.ssh/
  which ssh-agent
}

setup_params(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$RES_PARAMS_STR"_SECURITY_GROUP_ID")

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  # get repo path
  export REPO_PATH=$(eval echo "$"$RES_REPO_PATH"/gitRepo")

  # get AMI_ID
  export AMI_ID=$(eval echo "$"$RES_BASE_AMI_UP"_VERSIONNAME")

  # getting propertyBag values
  pushd $(eval echo "$"$RES_BASE_AMI_UP"_PATH")
  export DRYDOCK_TAG=$(jq -r '.version.propertyBag.DRYDOCK_TAG' version.json)
  export DRYDOCK_TAG_DASH=$(jq -r '.version.propertyBag.DRYDOCK_TAG_DASH' version.json)
  popd

  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "REPO_PATH=$REPO_PATH"
  echo "AMI_ID=$AMI_ID"
  echo "DRYDOCK_TAG=$DRYDOCK_TAG"
  echo "DRYDOCK_TAG_DASH=$DRYDOCK_TAG_DASH"
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
  pushd /build/IN/$RES_REPO/gitRepo/basePatch
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate basePatchAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var AMI_ID=$AMI_ID \
    -var DRYDOCK_TAG=$DRYDOCK_TAG \
    -var DRYDOCK_TAG_DASH=$DRYDOCK_TAG_DASH \
    basePatchAMI.json 2>&1 | tee output.txt

    #putting AMI-ID as the versionName of this job
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > /build/state/$CURR_JOB.env #adding version state

    echo "DRYDOCK_TAG=$DRYDOCK_TAG" >> /build/state/$CURR_JOB.env
    echo "DRYDOCK_TAG_DASH=$DRYDOCK_TAG_DASH" >> /build/state/$CURR_JOB.env

    cat /build/state/$CURR_JOB.env
  popd
}

main() {
  setup_ssh
  setup_params
  install_packer
  build_ami
}

main
