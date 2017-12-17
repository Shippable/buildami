#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_AWS_CREDS=$2
export RES_AWS_AMI_CREDS=$3
export RES_REL=$4
export RES_REL_VER_NAME="master"

# TODO update standards Now get ECR keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# TODO update standards Now get keys for building AMI
export RES_AWS_AMI_CREDS_UP=$(echo $RES_AWS_AMI_CREDS | awk '{print toupper($0)}')
export RES_AWS_AMI_CREDS_INT=$RES_AWS_AMI_CREDS_UP"_INTEGRATION"

set_context(){
  # get release
  if [ -z "$RES_REL" ] || [ "$RES_REL" == "" ]; then
    export RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME
  else
    export RES_REL_VER_NAME=$(shipctl get_resource_version_name "$RES_REL")
    export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}
  fi

  # now get the ECR keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_ACCESSKEY")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_SECRETKEY")

  # now get the AMI build keys
  export AWS_AMI_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_AMI_CREDS_INT"_ACCESSKEY")
  export AWS_AMI_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_AMI_CREDS_INT"_SECRETKEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"
  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME"

  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  echo "AWS_AMI_ACCESS_KEY_ID=${#AWS_AMI_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_AMI_SECRET_ACCESS_KEY=${#AWS_AMI_SECRET_ACCESS_KEY}" #print only length not value
}

build_ami() {

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
    -var SOURCE_AMI=$SOURCE_AMI \
    admiralAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

    cat "$JOB_STATE/$CURR_JOB.env"
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  build_ami
}

main
