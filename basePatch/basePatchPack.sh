#!/bin/bash -e

set -o pipefail

export CURR_JOB="patch_baseami"
export RES_AWS_CREDS="aws_bits_access"
export RES_PARAMS="baseami_params"
export RES_REPO="bldami_repo"
export RES_BASE_AMI="build_baseami"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

# set the base-ami path
export RES_BASE_AMI_UP=$(echo $RES_BASE_AMI | awk '{print toupper($0)}')
export RES_BASE_AMI_PATH=$(eval echo "$"$RES_BASE_AMI_UP"_PATH")

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

  # getting propertyBag values
  pushd $RES_BASE_AMI_PATH
  export RES_IMG_VER_NAME=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME' version.json)
  export RES_IMG_VER_NAME_DASH=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME_DASH' version.json)
  export IMAGE_NAMES_SPACED=$(jq -r '.version.propertyBag.IMAGE_NAMES_SPACED' version.json)
  popd

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"
  echo "RES_REPO=$RES_REPO"
  echo "RES_BASE_AMI=$RES_BASE_AMI"
  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_BASE_AMI_UP=$RES_BASE_AMI_UP"
  echo "RES_BASE_AMI_PATH=$RES_BASE_AMI_PATH"

  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "AMI_ID=$AMI_ID"
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"
  echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH"
}

build_ami() {
  pushd "$RES_REPO_STATE/basePatch"
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
    -var RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH \
    basePatchAMI.json 2>&1 | tee output.txt

    #putting AMI-ID as the versionName of this job
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env" #adding version state

    echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
    cat "$JOB_STATE/$CURR_JOB.env"

  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  build_ami
}

main
