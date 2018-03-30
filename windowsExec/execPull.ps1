$ErrorActionPreference = "Stop"

$MESSAGE_STORE_LOCATION = "/tmp/cexec"
$SHIPPABLE_RELEASE_VERSION = "$env:REL_VER"
$KEY_STORE_LOCATION = "/tmp/ssh"
$NODE_TYPE_CODE = 7001
$SHIPPABLE_NODE_INIT = true
$NODE_DATA_LOCATION = "/etc/shippable"
$NODE_LOGS_LOCATION = "$NODE_DATA_LOCATION/logs"
$EXEC_REPO = "https://github.com/Shippable/cexec.git"
$NODE_SCRIPTS_REPO = "https://github.com/Shippable/node.git"

$CEXEC_LOC = "/home/shippable/cexec"
$NODE_SCRIPTS_LOC = "/root/node"

$REQPROC_IMG = "drydock/w16reqproc"
$REQKICK_DIR = "/var/lib/shippable/reqKick"
$REQKICK_REPO = "https://github.com/Shippable/reqKick.git"
$NODE_SHIPCTL_LOCATION = "$NODE_SCRIPTS_LOC/shipctl"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$REL_VER/reports-$REL_VER-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

Function set_context() {
  echo "Setting context for AMI"

  echo "REL_VER=$env:REL_VER"
  echo "REQPROC_IMG=$REQPROC_IMG"
  echo "CEXEC_LOC=$CEXEC_LOC"
  echo "IMAGE_NAMES_SPACED=$env:IMAGE_NAMES_SPACED"

  $REQPROC_IMG_WITH_TAG = "${REQPROC_IMG}:${SHIPPABLE_RELEASE_VERSION}"
}

Function validate_envs() {
  echo "Validating environment variables for AMI"

  if (!$SHIPPABLE_RELEASE_VERSION) {
    echo "SHIPPABLE_RELEASE_VERSION env not defined, exiting"
    exit 1
  }
  echo "SHIPPABLE_RELEASE_VERSION: $SHIPPABLE_RELEASE_VERSION"

  if (!$KERNEL_DOWN) {
    echo "KERNEL_DOWN env not defined, setting it to false"
    export KERNEL_DOWN="false"
  } else {
    echo "KERNEL_DOWN: $KERNEL_DOWN"
  }
}

Function pull_images() {
  foreach ($IMAGE_NAME in $env:IMAGE_NAMES_SPACED.Split(" ")) {
    echo "Pulling -------------------> ${IMAGE_NAME}:${SHIPPABLE_RELEASE_VERSION}"
    docker pull ${IMAGE_NAME}:${SHIPPABLE_RELEASE_VERSION}
  }
}

Function clone_cexec() {
  if (Test-Path $CEXEC_LOC) {
    Write-Output "Cleaning cexec..."
    Remove-Item -recur -force $CEXEC_LOC
  }
  git clone $EXEC_REPO $CEXEC_LOC
}

Function tag_cexec() {
  pushd $CEXEC_LOC
    git checkout master
    git pull --tags
    git checkout $SHIPPABLE_RELEASE_VERSION
  popd
}

Function fetch_reports() {
  $reports_dir = "$CEXEC_LOC/bin"
  $reports_tar_file = "reports.tar.gz"
  if (Test-Path $reports_dir) {
    Write-Output "Cleaning reports dir..."
    Remove-Item -recur -force $reports_dir
  } else {
    mkdir -p $reports_dir
  }
  
  pushd $reports_dir
    wget $REPORTS_DOWNLOAD_URL -O $reports_tar_file
    tar -xf $reports_tar_file
    Remove-Item -force $reports_tar_file
  popd
}

Function clone_node_scripts() {
  if (Test-Path $NODE_SCRIPTS_LOC) {
    Write-Output "Cleaning node scripts dir..."
    Remove-Item -recur -force $NODE_SCRIPTS_LOC
  }
  echo "Downloading Shippable node init repo"
  mkdir -p $NODE_SCRIPTS_LOC
  git clone $NODE_SCRIPTS_REPO $NODE_SCRIPTS_LOC
}

Function tag_node_scripts() {
  pushd $NODE_SCRIPTS_LOC
    git checkout master
    git pull --tags
    git checkout $SHIPPABLE_RELEASE_VERSION
  popd
}

Function update_envs() {
  $node_env_template = "$NODE_SCRIPTS_LOC/usr/node.env.template"
  $node_env = "$NODE_DATA_LOCATION/node.env"

  if (!(Test-Path $node_env_template)) {
    echo "Node environment template file not found: $node_env_template"
    exit 1
  }
  echo "Node environment template file found: $node_env_template"

  echo "Writing node specific envs to $node_env"
  if (!(Test-Path $NODE_DATA_LOCATION)) {
    mkdir -p $NODE_DATA_LOCATION
  }
  ## Setting the build time envs
  sed "s#{{NODE_TYPE_CODE}}#$NODE_TYPE_CODE#g" $node_env_template | sudo tee $node_env
  sed -i "s#{{SHIPPABLE_NODE_INIT}}#$SHIPPABLE_NODE_INIT#g" $node_env
  
  sed -i "s#{{SHIPPABLE_RELEASE_VERSION}}#$SHIPPABLE_RELEASE_VERSION#g" $node_env
  sed -i "s#{{EXEC_REPO}}#$EXEC_REPO#g" $node_env

  ## Setting the runtime values to empty
  $default_value = ""
  sed -i "s#{{COMPONENT}}#$default_value#g" $node_env
  sed -i "s#{{LISTEN_QUEUE}}#$default_value#g" $node_env
  sed -i "s#{{SUBSCRIPTION_ID}}#$default_value#g" $node_env
  sed -i "s#{{NODE_ID}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_URL}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_API_TOKEN}}#$default_value#g" $node_env
  sed -i "s#{{SHIPPABLE_AMQP_DEFAULT_EXCHANGE}}#$default_value#g" $node_env
  sed -i "s#{{RUN_MODE}}#$default_value#g" $node_env
  sed -i "s#{{JOB_TYPE}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_MOUNTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_OPTS}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_CONTAINER_NAME}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_CONTAINER_NAME_PATTERN}}#$default_value#g" $node_env
  sed -i "s#{{EXEC_IMAGE}}#$default_value#g" $node_env
  sed -i "s#{{IS_DOCKER_LEGACY}}#$default_value#g" $node_env

  echo "Successfully update node specific envs to $node_env"
  cat $node_env
}

Function install_nodejs() {
  pushd /tmp
    echo "Installing node 4.8.5"
    wget "https://nodejs.org/dist/v4.8.5/node-v4.8.5-linux-x64.tar.xz"
    tar -xf "node-v4.8.5-linux-x64.tar.xz"
    cp -Rf "node-v4.8.5-linux-x64/{bin,include,lib,share}" "/usr/local"

    echo "Checking node version"
    node -v
  popd
}

Function install_shipctl() {
  echo "Installing shipctl components"
  eval "$NODE_SHIPCTL_LOCATION/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/install.sh"
}

Function clone_reqKick() {
  echo "cloning reqKick"
  if (Test-Path $REQKICK_DIR) {
    Write-Output "Cleaning reqKick..."
    Remove-Item -recur -force $REQKICK_DIR
  }
  git clone $REQKICK_REPO $REQKICK_DIR
}

Function tag_reqKick() {
  echo "tagging reqKick"
  pushd $REQKICK_DIR
    git checkout master
    git pull --tags
    git checkout $SHIPPABLE_RELEASE_VERSION
    npm install
  popd
}

Function pull_tagged_reqproc() {
  echo "pulling tagged reqproc image: $REQPROC_IMG_WITH_TAG"
  docker pull $REQPROC_IMG_WITH_TAG
}


set_context
validate_envs
pull_images
clone_cexec
tag_cexec
fetch_reports
clone_node_scripts
tag_node_scripts
update_envs
install_nodejs
install_shipctl
clone_reqKick
tag_reqKick
pull_tagged_reqproc
