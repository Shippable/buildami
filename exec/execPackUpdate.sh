#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_REL=$2
export AMI_ID=$3
export AMI_TYPE=$4
export KERNEL_DOWN=$6
export RES_AWS_CREDS=$7

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

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REL=$RES_REL"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"

  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"

  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"

  echo "REGION=$REGION"
  echo "VPC_ID=$VPC_ID"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "AMI_ID=$AMI_ID"
  echo "AMI_TYPE=$AMI_TYPE"
  echo "KERNEL_DOWN=$KERNEL_DOWN"
}

build_ami() {
  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate execAMITmp.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var AMI_ID=$AMI_ID \
    -var AMI_TYPE=$AMI_TYPE \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    -var KERNEL_DOWN=$KERNEL_DOWN \
    execAMITmp.json 2>&1 | tee output.txt

  #this is to get the ami from output
  echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
  | cut -d':' -f 2) > /build/state/$CURR_JOB.env

  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> /build/state/$CURR_JOB.env
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> /build/state/$CURR_JOB.env
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  build_ami
}

main
