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
# $REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$env:REL_VER/reports-$env:REL_VER-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

Function set_context() {
  echo "Setting context for AMI"

  echo "REL_VER=$env:REL_VER"
  echo "REQPROC_IMG=$REQPROC_IMG"
  echo "CEXEC_LOC=$CEXEC_LOC"
  echo "IMAGE_NAMES_SPACED=$env:IMAGE_NAMES_SPACED"
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
  Invoke-Expression "$NODE_SHIPCTL_LOCATION/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/install.ps1"
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
  echo "pulling tagged reqproc image: ${REQPROC_IMG}:${SHIPPABLE_RELEASE_VERSION}"
  docker pull ${REQPROC_IMG}:${SHIPPABLE_RELEASE_VERSION}
}


set_context
validate_envs
pull_images
clone_cexec
tag_cexec
# fetch_reports
clone_node_scripts
tag_node_scripts
install_nodejs
install_shipctl
clone_reqKick
tag_reqKick
pull_tagged_reqproc
