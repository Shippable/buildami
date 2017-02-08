#!/bin/bash -e

set -o pipefail

export PK_INSALL_LOCATION=/opt
export PK_VERSION=0.11.0
export PK_FILENAME=packer_"$PK_VERSION"_linux_amd64.zip
export RES_AWS_CREDS="aws-bits-access"
export REPO_RESOURCE_NAME="bldami-repo"
export RES_PARAMS=$1
export RES_AMI=$2
export AMI_TYPE=$3

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
  echo "Digesting RES_PARAMS=$RES_PARAMS"
  pushd ./IN/$RES_PARAMS
  export REGION=$(jq -r '.version.propertyBag.params.REGION' version.json)
  export VPC_ID=$(jq -r '.version.propertyBag.params.VPC_ID' version.json)
  export SUBNET_ID=$(jq -r '.version.propertyBag.params.SUBNET_ID' version.json)
  export SECURITY_GROUP_ID=$(jq -r '.version.propertyBag.params.SECURITY_GROUP_ID' version.json)
  popd

  pushd ./IN/$RES_AMI/runSh
  . AMI_ID.txt #to set AMI_ID
  popd

  echo "AMI_ID=$AMI_ID"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AMI_TYPE=$AMI_TYPE"
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
  pushd /build/IN/$REPO_RESOURCE_NAME/gitRepo/basePatch
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate basePatchAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var 'aws_access_key='$aws_access_key_id \
    -var 'aws_secret_key='$aws_secret_access_key \
    -var 'REGION='$REGION \
    -var 'VPC_ID='$VPC_ID \
    -var 'SUBNET_ID='$SUBNET_ID \
    -var 'SECURITY_GROUP_ID='$SECURITY_GROUP_ID \
    -var 'AMI_ID='$AMI_ID \
    -var 'AMI_TYPE='$AMI_TYPE \
    basePatchAMI.json 2>&1 | tee output.txt

    #putting AMI-ID as the versionName of this job
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > /build/state/$CURR_JOB.env #adding version state
    cat /build/state/$CURR_JOB.env
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
