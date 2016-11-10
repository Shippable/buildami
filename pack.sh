#!/bin/bash -e

export PK_INSALL_LOCATION=/opt
export PK_VERSION=0.11.0
export PK_FILENAME=packer_"$PK_VERSION"_linux_amd64.zip
export RES_AWS_CREDS="aws-bits-access"
export REPO_RESOURCE_NAME="bldami-repo"
export RES_PARAMS=$1

echo "RES_PARAMS=$RES_PARAMS"

setup_ssh(){
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  ls -al ~/.ssh/
  which ssh-agent
}

setup_keys() {
  pushd /build/IN/$RES_AWS_CREDS
  echo "-----------------------------------"

  echo "setting AWS keys"
  echo "-----------------------------------"
  . integration.env
  popd
}

setup_params(){
  pushd ./IN/$RES_PARAMS
  export REGION=$(jq -r '.version.propertyBag.params.REGION' version.json)
  export VPC_ID=$(jq -r '.version.propertyBag.params.VPC_ID' version.json)
  export SUBNET_ID=$(jq -r '.version.propertyBag.params.SUBNET_ID' version.json)
  export SECURITY_GROUP_ID=$(jq -r '.version.propertyBag.params.SECURITY_GROUP_ID' version.json)
  export SOURCE_AMI=$(jq -r '.version.propertyBag.params.SOURCE_AMI' version.json)

  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"

  popd
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
  pushd /build/IN/$REPO_RESOURCE_NAME/gitRepo
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate testAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var 'aws_access_key='$aws_access_key_id \
    -var 'aws_secret_key='$aws_secret_access_key \
    -var 'REGION='$REGION \
    -var 'VPC_ID='$VPC_ID \
    -var 'SUBNET_ID='$SUBNET_ID \
    -var 'SECURITY_GROUP_ID='$SECURITY_GROUP_ID \
    -var 'SOURCE_AMI='$SOURCE_AMI \
    testAMI.json | awk -F, '$0 ~/artifact,0,id/ {print $6}'
  popd
}

main() {
  setup_ssh
  setup_keys
  setup_params
  install_packer
  build_ami
}

main
