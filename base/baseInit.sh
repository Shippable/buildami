#!/bin/bash
set -e
set -o pipefail

readonly MESSAGE_STORE_LOCATION="/tmp/cexec"
readonly KEY_STORE_LOCATION="/tmp/ssh"
readonly NODE_TYPE_CODE=7001
readonly SHIPPABLE_NODE_INIT=true
readonly SCRIPTS_DOWNLOAD_URL="https://github.com/Shippable/node/archive/master.tar.gz"
readonly NODE_SCRIPTS_DOWNLOAD_LOCATION="/tmp/shippable/node.tar.gz"
readonly NODE_SCRIPTS_LOCATION="/home/shippable/node"
readonly NODE_DATA_LOCATION="/etc/shippable"
readonly NODE_LOGS_LOCATION="$NODE_DATA_LOCATION/logs"
readonly EXEC_REPO="https://github.com/Shippable/cexec"
readonly COMPONENT="genExec"

# Indicates whether the script has succeeded
export is_success=false

########################### HEADERS SECTION ############################
__process_marker() {
  local prompt="$@"
  echo ""
  echo "# $(date +"%T") #######################################"
  echo "# $prompt"
  echo "##################################################"
}

__process_msg() {
  local message="$@"
  echo "|___ $@"
}

__process_error() {
  local message="$1"
  local error="$2"
  local bold_red_text='\e[91m'
  local reset_text='\033[0m'

  echo -e "$bold_red_text|___ $message$reset_text"
  echo -e "     $error"
}

before_exit() {
  ## flush any remaining console
  echo $1
  echo $2

  if [ "$is_success" == true ]; then
    echo "AMI build script executed successfully"
  else
    echo "Error while building AMI"
  fi
}

exec_cmd() {
  local cmd=$@
  __process_msg "Running $cmd"
  eval $cmd
  cmd_status=$?
  if [ "$2" ]; then
    echo $2;
  fi

  if [ $cmd_status == 0 ]; then
    __process_msg "Completed $cmd"
    return $cmd_status
  else
    __process_error "Failed $cmd"
    exit 99
  fi
}

exec_grp() {
  local group_name=$1
  __process_marker "Starting $group_name"
  eval "$group_name"
  group_status=$?
  __process_marker "Completed $group_name"
}

########################### END HEADERS SECTION #########################

validate_envs() {
  is_success=false
  __process_msg "Validating environment variables for AMI"

  if [ -z "$SHIPPABLE_RELEASE_VERSION" ] || [ "$SHIPPABLE_RELEASE_VERSION" == "" ]; then
    __process_error "SHIPPABLE_RELEASE_VERSION env not defined, exiting"
    exit 1
  else
    __process_msg "SHIPPABLE_RELEASE_VERSION: $SHIPPABLE_RELEASE_VERSION"
  fi

  if [ -z "$SHIPPABLE_NODE_INIT_SCRIPT" ] || [ "$SHIPPABLE_NODE_INIT_SCRIPT" == "" ]; then
    __process_error "SHIPPABLE_NODE_INIT_SCRIPT env not defined, exiting"
    exit 1
  else
    __process_msg "SHIPPABLE_NODE_INIT_SCRIPT: $SHIPPABLE_NODE_INIT_SCRIPT"
  fi

  if [ -z "$SCRIPTS_DOWNLOAD_URL" ] || [ "$SCRIPTS_DOWNLOAD_URL" == "" ]; then
    __process_error "SCRIPTS_DOWNLOAD_URL env not defined, exiting"
    exit 1
  else
    __process_msg "SCRIPTS_DOWNLOAD_URL: $SCRIPTS_DOWNLOAD_URL"
  fi

  is_success=true
}

check_dependencies() {
  is_success=false
  __process_msg "Checking node dependencies"

  command -v curl >/dev/null 2>&1
  local ret=$?
  if [ $? -ne 0 ]; then
    __process_msg "curl not installed on host machine. Shippable nodes require curl to be installed"
    is_success=false
  else
    __process_msg "curl installed, continuing..."
    exec_cmd "curl --version"
    is_success=true
  fi

  command -v tar >/dev/null 2>&1
  local ret=$?
  if [ $? -ne 0 ]; then
    __process_msg "tar not installed on host machine. Shippable nodes require tar to be installed"
    is_success=false
  else
    __process_msg "tar installed, continuing..."
    exec_cmd "tar --version"
    is_success=true
  fi
}

get_repo() {
  is_success=false
  __process_msg "Downloading Shippable node init repo"

  exec_cmd "mkdir -p $NODE_SCRIPTS_LOCATION"
  exec_cmd "mkdir -p $NODE_DATA_LOCATION"
  exec_cmd "mkdir -p $NODE_LOGS_LOCATION"
  exec_cmd "mkdir -p /tmp/shippable"

  __process_msg "Pulling scripts from api"
  exec_cmd "curl -LkSs \
    --connect-timeout 60 \
    --max-time 120 \
    '$SCRIPTS_DOWNLOAD_URL' \
    -o $NODE_SCRIPTS_DOWNLOAD_LOCATION"

  __process_msg "Un-taring Shippable node init repo"
  exec_cmd "tar -xvzf \
    '$NODE_SCRIPTS_DOWNLOAD_LOCATION' \
    -C $NODE_SCRIPTS_LOCATION \
    --strip-components=1"

  is_success=true
}

update_envs() {
  is_success=false

  local node_env_template=$NODE_SCRIPTS_LOCATION/usr/node.env.template
  local node_env=$NODE_DATA_LOCATION/node.env

  if [ ! -f "$node_env_template" ]; then
    __process_error "Node environment template file not found: $node_env_template"
    is_success=false
    return
  else
    __process_msg "Node environment template file found: $node_env_template"
  fi

  __process_msg "Writing node specific envs to $node_env"

  ## Setting the build time envs
  sed "s#{{NODE_TYPE_CODE}}#$NODE_TYPE_CODE#g" $node_env_template > $node_env
  sed -i "s#{{SHIPPABLE_NODE_INIT_SCRIPT}}#$SHIPPABLE_NODE_INIT_SCRIPT#g" $node_env
  sed -i "s#{{SHIPPABLE_NODE_INIT}}#$SHIPPABLE_NODE_INIT#g" $node_env
  sed -i "s#{{COMPONENT}}#$COMPONENT#g" $node_env
  sed -i "s#{{SHIPPABLE_RELEASE_VERSION}}#$SHIPPABLE_RELEASE_VERSION#g" $node_env
  sed -i "s#{{EXEC_REPO}}#$EXEC_REPO#g" $node_env

  ## Setting the runtime values to empty
  local default_value=""
  sed -i "s#{{LISTEN_QUEUE}}#$default_value#g" $node_env
  sed -i "s#{{NODE_ID}}#$default_value#g" $node_env
  sed -i "s#{{SUBSCRIPTION_ID}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_TOKEN}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_DEFAULT_EXCHANGE}}#$default_value#g" $node_env
  sed -i "s#{{RUN_MODE}}#$default_value#g" $node_env
  sed -i "s#{{JOB_TYPE}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_MOUNTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_OPTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_CONTAINER_NAME}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_IMAGE}}#$default_value#g" $node_env
  sed -i "s#{{IS_DOCKER_LEGACY}}#$default_value#g" $node_env

  __process_msg "Successfully update node specific envs to $node_env"
  exec_cmd "cat $node_env"

  is_success=true
}

initialize() {
  is_success=false

  __process_msg "Initializing node"
  exec_cmd "/bin/bash $NODE_SCRIPTS_LOCATION/boot.sh"

  is_success=true
}

trap before_exit EXIT
exec_grp "validate_envs"

trap before_exit EXIT
exec_grp "check_dependencies"

trap before_exit EXIT
exec_grp "get_repo"

trap before_exit EXIT
exec_grp "update_envs"

trap before_exit EXIT
exec_grp "initialize"
