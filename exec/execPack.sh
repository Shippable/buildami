#!/bin/bash -e

set -o pipefail

export PK_INSALL_LOCATION=/opt
export PK_VERSION=0.11.0
export PK_FILENAME=packer_"$PK_VERSION"_linux_amd64.zip

export CURR_JOB=$1
export RES_REL=$2
export RES_REPO="bldami_repo"
export RES_AWS_CREDS="aws_bits_access"
export RES_BASE_AMI="patch_baseami"
export RES_PARAMS="baseami_params"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_REL_UP=$(echo $RES_REL | awk '{print toupper($0)}')
export RES_REL_VER_NAME=$(eval echo "$"$RES_REL_UP"_VERSIONNAME")
export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# set the base-ami path
export RES_BASE_AMI_UP=$(echo $RES_BASE_AMI | awk '{print toupper($0)}')

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

set_context(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$RES_PARAMS_STR"_SECURITY_GROUP_ID")

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  # get AMI_ID
  export AMI_ID=$(eval echo "$"$RES_BASE_AMI_UP"_VERSIONNAME")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REL=$RES_REL"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_BASE_AMI=$RES_BASE_AMI"
  echo "RES_PARAMS=$RES_PARAMS"

  echo "RES_REL_UP=$RES_REPO_UP"
  echo "RES_REL_VER_NAME=$RES_REPO_STATE"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_BASE_AMI_UP=$RES_BASE_AMI_UP"
  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"

  echo "REGION=$REGION"
  echo "VPC_ID=$VPC_ID"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "AMI_ID=$AMI_ID"
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
  pushd "$RES_REPO_STATE/exec"
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate execAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$aws_access_key_id \
    -var aws_secret_key=$aws_secret_access_key \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var AMI_ID=$AMI_ID \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    execAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > /build/state/$CURR_JOB.env

    echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> /build/state/$CURR_JOB.env
    echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> /build/state/$CURR_JOB.env
  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  #install_packer
  #build_ami
}

main
