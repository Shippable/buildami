$ErrorActionPreference = "Stop"

$MESSAGE_STORE_LOCATION = "/tmp/cexec"
$SHIPPABLE_RELEASE_VERSION = "$env:REL_VER"
$KEY_STORE_LOCATION = "/tmp/ssh"
$NODE_TYPE_CODE = 7001
$SHIPPABLE_NODE_INIT = $TRUE
$NODE_DATA_LOCATION = "/etc/shippable"
$NODE_LOGS_LOCATION = "$NODE_DATA_LOCATION/logs"
$EXEC_REPO = "https://github.com/Shippable/cexec.git"
$NODE_SCRIPTS_REPO = "https://github.com/Shippable/node.git"
$NODE_JS_VERSION = "4.8.5"

$CEXEC_LOC = "/home/shippable/cexec"
$NODE_SCRIPTS_LOC = "/root/node"

$REQPROC_IMG = "drydock/w16reqproc"
$REQKICK_DIR = "/var/lib/shippable/reqKick"
$REQKICK_REPO = "https://github.com/Shippable/reqKick.git"
$NODE_SHIPCTL_LOCATION = "$NODE_SCRIPTS_LOC/shipctl"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$env:REL_VER/reports-$env:REL_VER-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

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

# CI not yet supported in windows. no need for reports package
# Function fetch_reports() {
#   $reports_dir = "$CEXEC_LOC/bin"
#   $reports_tar_file = "reports.tar.gz"
#   if (Test-Path $reports_dir) {
#     Write-Output "Cleaning reports dir..."
#     Remove-Item -recur -force $reports_dir
#   }
#   mkdir -p $reports_dir

#   pushd $reports_dir
#     wget $REPORTS_DOWNLOAD_URL -O $reports_tar_file
#     tar -xf $reports_tar_file
#     Remove-Item -force $reports_tar_file
#   popd
# }

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

  $default_value = ""
  $template = (Get-Content $node_env_template)

  ## Setting the build time envs
  $template = $template.replace("{{NODE_TYPE_CODE}}", $NODE_TYPE_CODE)
  $template = $template.replace("{{SHIPPABLE_NODE_INIT}}", $SHIPPABLE_NODE_INIT)
  $template = $template.replace("{{SHIPPABLE_RELEASE_VERSION}}", $SHIPPABLE_RELEASE_VERSION)
  $template = $template.replace("{{EXEC_REPO}}", $EXEC_REPO)

  ## Setting the runtime values to empty
  $template = $template.replace("{{LISTEN_QUEUE}}", $default_value)
  $template = $template.replace("{{SUBSCRIPTION_ID}}", $default_value)
  $template = $template.replace("{{NODE_ID}}", $default_value)
  $template = $template.replace("{{SHIPPABLE_AMQP_URL}}", $default_value)
  $template = $template.replace("{{SHIPPABLE_API_URL}}", $default_value)
  $template = $template.replace("{{SHIPPABLE_API_TOKEN}}", $default_value)
  $template = $template.replace("{{SHIPPABLE_AMQP_DEFAULT_EXCHANGE}}", $default_value)
  $template = $template.replace("{{RUN_MODE}}", $default_value)
  $template = $template.replace("{{JOB_TYPE}}", $default_value)
  $template = $template.replace("{{EXEC_MOUNTS}}", $default_value)
  $template = $template.replace("{{EXEC_OPTS}}", $default_value)
  $template = $template.replace("{{EXEC_CONTAINER_NAME}}", $default_value)
  $template = $template.replace("{{EXEC_CONTAINER_NAME_PATTERN}}", $default_value)
  $template = $template.replace("{{EXEC_IMAGE}}", $default_value)
  $template = $template.replace("{{IS_DOCKER_LEGACY}}", $default_value) | Set-Content $node_env

  echo "Successfully update node specific envs to $node_env"
  cat $node_env
}

Function install_nodejs() {
  Write-Output "Checking for node.js v$NODE_JS_VERSION"
  $nodejs_package = Get-Package nodejs -provider ChocolateyGet -ErrorAction SilentlyContinue
  if (!$nodejs_package -or ($nodejs_package.Version -ne "$NODE_JS_VERSION")) {
    Write-Output "Installing node.js v$NODE_JS_VERSION"
    Install-Package -ProviderName ChocolateyGet -Name nodejs -RequiredVersion $NODE_JS_VERSION -Force
  }
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
# fetch_reports
clone_node_scripts
tag_node_scripts
update_envs
install_nodejs
install_shipctl
clone_reqKick
tag_reqKick
pull_tagged_reqproc
