$ErrorActionPreference = "Stop"

$NODE_ARCHITECTURE = "$env:ARCHITECTURE"
$NODE_OPERATING_SYSTEM = "$env:OS"
$INIT_SCRIPT_NAME = "Docker_$env:DOCKER_VER.ps1"
$NODE_DOWNLOAD_URL = "$env:NODE_DOWNLOAD_URL"

$NODE_SCRIPTS_TMP_LOC = "$env:TEMP/node.zip"
$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE/node"
$NODE_SHIPCTL_LOCATION = "$env:NODE_SCRIPTS_LOCATION/shipctl"

$install_docker_only = $true


$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE\node"
$REQKICK_DIR = "$env:USERPROFILE\Shippable\reqKick"
$REQPROC_MASTER_IMAGE = "drydock/w16reqproc:master"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "$env:REL_VER"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

Function clean_node_scripts() {
  if (Test-Path $NODE_SCRIPTS_LOCATION) {
    Write-Output "Cleaning node scripts"
    Remove-Item -recur -force $NODE_SCRIPTS_LOCATION
  }
}

Function clone_node_scripts() {
  mkdir -p $NODE_SCRIPTS_LOCATION
  git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
}

Function clean_reqKick () {
  if (Test-Path $REQKICK_DIR) {
    Write-Output "Cleaning reqKick..."
    Remove-Item -recur -force $REQKICK_DIR
  }
}

Function clone_reqKick () {
  Write-Output "Cloning reqKick..."
  git clone https://github.com/Shippable/reqKick.git $REQKICK_DIR

  cd $REQKICK_DIR
  git checkout $SHIPPABLE_RELEASE_VERSION
  node -v
  npm -v
  npm install
}

Function pull_reqProc () {
  docker pull $REQPROC_MASTER_IMAGE
}

Write-Output "REL_VER=$env:REL_VER"
clean_node_scripts
clone_node_scripts
pull_reqProc
clean_reqKick
clone_reqKick

