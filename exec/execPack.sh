#!/bin/bash -e

set -o pipefail

export CURR_JOB="build_finalami"
export RES_REL="rel_prod"
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
export RES_BASE_AMI_PATH=$(eval echo "$"$RES_BASE_AMI_UP"_PATH")

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
  # getting propertyBag values
  pushd $RES_BASE_AMI_PATH
  export RES_IMG_VER_NAME=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME' version.json)
  export RES_IMG_VER_NAME_DASH=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME_DASH' version.json)
  export IMAGE_NAMES_SPACED=$(jq -r '.version.propertyBag.IMAGE_NAMES_SPACED' version.json)
  popd

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
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"
  echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"
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
    -var IMAGE_NAMES_SPACED="${IMAGE_NAMES_SPACED}" \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    execAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

    echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
    echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
    echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$JOB_STATE/$CURR_JOB.env"
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
