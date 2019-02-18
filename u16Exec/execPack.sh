#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_REL=$2
export RES_BASE_AMI=$3
export RES_AWS_CREDS=$4
export DRYDOCK_REL=$5

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_REL_VER_NAME=$(shipctl get_resource_version_name "$RES_REL")
export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}

# since resources here have dashes Shippable replaces them and UPPER cases them
export DRYDOCK_REL_VER_NAME=$(shipctl get_resource_version_name "$DRYDOCK_REL")
export DRYDOCK_REL_VER_NAME_DASH=${DRYDOCK_REL_VER_NAME//./-}

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

export CURR_JOB_ENV="$JOB_STATE/$CURR_JOB.env"

set_context(){
  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_ACCESSKEY")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_SECRETKEY")

  # get AMI_ID
  export AMI_ID=$(shipctl get_resource_version_name "$RES_BASE_AMI")

  export RES_BASE_AMI_UP=$(echo $RES_BASE_AMI | awk '{print toupper($0)}')
  export RES_BASE_AMI_PATH=$(eval echo "$"$RES_BASE_AMI_UP"_PATH")
  # getting propertyBag values
  pushd $RES_BASE_AMI_PATH
    export RES_IMG_VER_NAME=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME' version.json)
    export RES_IMG_VER_NAME_DASH=$(jq -r '.version.propertyBag.RES_IMG_VER_NAME_DASH' version.json)
    export IMAGE_NAMES_SPACED=$(jq -r '.version.propertyBag.IMAGE_NAMES_SPACED' version.json)
  popd

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REL=$RES_REL"
  echo "DRYDOCK_REL=$DRYDOCK_REL"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_BASE_AMI=$RES_BASE_AMI"

  echo "RES_REL_VER_NAME=$RES_REL_VER_NAME"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"

  echo "DRYDOCK_REL_VER_NAME=$DRYDOCK_REL_VER_NAME"
  echo "DRYDOCK_REL_VER_NAME_DASH=$DRYDOCK_REL_VER_NAME_DASH"

  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_BASE_AMI_UP=$RES_BASE_AMI_UP"

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
  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate execAMI.json
  echo "building AMI"
  echo "-----------------------------------"

  if [ "$RES_REL_VER_NAME" == "$DRYDOCK_REL_VER_NAME" ]; then
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
    | cut -d':' -f 2) > "$CURR_JOB_ENV"

    echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> "$CURR_JOB_ENV"
    echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> "$CURR_JOB_ENV"
    echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME" >> "$CURR_JOB_ENV"
    echo "RES_IMG_VER_NAME_DASH=$RES_IMG_VER_NAME_DASH" >> "$CURR_JOB_ENV"
    echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$CURR_JOB_ENV"
    cat "$CURR_JOB_ENV"
  else
    echo "SHIPPABLE_RELEASE not same as DRYDOCK_RELEASE, skipping Machine Image creation"
    shipctl copy_file_from_prev_state "$CURR_JOB.env" "$CURR_JOB_ENV"
    cat "$CURR_JOB_ENV"
  fi
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  build_ami
}

main
