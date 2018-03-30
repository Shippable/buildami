#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_REL=$2
export RES_BASE_AMI=$3
export RES_AWS_CREDS=$4

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_REL_VER_NAME=$(shipctl get_resource_version_name "$RES_REL")
export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"


set_context(){

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_ACCESSKEY")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_SECRETKEY")

  # get the AMI ID
  export AMI_ID=$(shipctl get_resource_version_name "$RES_BASE_AMI")

  export RES_BASE_AMI_UP=$(echo $RES_BASE_AMI | awk '{print toupper($0)}')
  export RES_BASE_AMI_PATH=$(eval echo "$"$RES_BASE_AMI_UP"_PATH")

  # get propertyBag values
  pushd $RES_BASE_AMI_PATH
    export RES_IMG_VER_NAME=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME' version.json)
    export RES_IMG_VER_NAME_DASH=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME_DASH' version.json)
    export IMAGE_NAMES_SPACED=$(jq -r '.version.propertyBag.IMAGE_NAMES_SPACED' version.json)
  popd

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_BASE_AMI=$RES_BASE_AMI"

  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_BASE_AMI_UP=$RES_BASE_AMI_UP"
  echo "RES_BASE_AMI_PATH=$RES_BASE_AMI_PATH"

  echo "REGION=$REGION"
  echo "AMI_ID=$AMI_ID"
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"
  echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH"
  echo "WINRM_USERNAME=${#WINRM_USERNAME}" #print only length not value
  echo "WINRM_PASSWORD=${#WINRM_PASSWORD}" #print only length not value
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

build_ami() {
  echo "-----------------------------------"
  echo "validating AMI template"
  echo "-----------------------------------"

  packer validate -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var WINRM_USERNAME=$WINRM_USERNAME \
    -var WINRM_PASSWORD=$WINRM_PASSWORD \
    -var AMI_ID=$AMI_ID \
    -var IMAGE_NAMES_SPACED="${IMAGE_NAMES_SPACED}" \
    execAMI.json

  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var AMI_ID=$AMI_ID \
    -var IMAGE_NAMES_SPACED="${IMAGE_NAMES_SPACED}" \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    -var WINRM_USERNAME=$WINRM_USERNAME \
    -var WINRM_PASSWORD=$WINRM_PASSWORD \
    execAMI.json 2>&1 | tee output.txt

  # this is to get the ami from output
  echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME" >> "$JOB_STATE/$CURR_JOB.env"
  echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH" >> "$JOB_STATE/$CURR_JOB.env"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$JOB_STATE/$CURR_JOB.env"
  cat "$JOB_STATE/$CURR_JOB.env"
}

main() {
  set_context
  build_ami
}

main
