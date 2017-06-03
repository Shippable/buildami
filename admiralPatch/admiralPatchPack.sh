#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_PARAMS=$2
export RES_REL=$3
export RES_AWS_CREDS="aws_bits_access"
export RES_AWS_AMI_CREDS="aws_prod_access"

export RES_REPO="bldami_repo"
export REL_DASH_VER="master"
export RES_ADMIRAL_AMI="build_admiral_ami"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

# Now get ECR keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# Now get keys for building AMI
export RES_AWS_AMI_CREDS_UP=$(echo $RES_AWS_AMI_CREDS | awk '{print toupper($0)}')
export RES_AWS_AMI_CREDS_INT=$RES_AWS_AMI_CREDS_UP"_INTEGRATION"

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

# set the base-ami path
export RES_ADMIRAL_AMI_UP=$(echo $RES_ADMIRAL_AMI | awk '{print toupper($0)}')
export RES_ADMIRAL_AMI_PATH=$(eval echo "$"$RES_ADMIRAL_AMI_UP"_PATH")

set_context(){
  # get release
  if [ -z "$RES_REL" ] || [ "$RES_REL" == "" ]; then
    export RES_REL_VER_NAME=master
    export RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME
  else
    export RES_REL_UP=$(echo $RES_REL | awk '{print toupper($0)}')
    export RES_REL_VER_NAME=$(eval echo "$"$RES_REL_UP"_VERSIONNAME")
    export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}
  fi

  # get AMI_ID
  export AMI_ID=$(eval echo "$"$RES_ADMIRAL_AMI_UP"_VERSIONNAME")

  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")

  # now get the ECR keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  # now get the AMI build keys
  export AWS_AMI_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_AMI_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_AMI_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_AMI_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"
  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"
  echo "RES_REPO=$RES_REPO"
  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"

  echo "AMI_ID=$AMI_ID"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  echo "AWS_AMI_ACCESS_KEY_ID=${#AWS_AMI_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_AMI_SECRET_ACCESS_KEY=${#AWS_AMI_SECRET_ACCESS_KEY}" #print only length not value

}

build_ami() {
  pushd "$RES_REPO_STATE/admiral"
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer --version || true
  packer validate admiralAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var aws_ami_access_key=$AWS_AMI_ACCESS_KEY_ID \
    -var aws_ami_secret_key=$AWS_AMI_SECRET_ACCESS_KEY \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var AMI_ID=$AMI_ID \
    -var REL_DASH_VER=$REL_DASH_VER \
    admiralPatchAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

    cat "$JOB_STATE/$CURR_JOB.env"
  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  #build_ami
}

main
