$ErrorActionPreference = "Stop"

$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE\node"
$REQKICK_DIR = "$env:USERPROFILE\Shippable\reqKick"
$REQPROC_MASTER_IMAGE = "drydock/w16reqproc:master"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "$env:RES_IMG_VER_NAME"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

Function clean_node_scripts() {
  if (Test-Path $NODE_SCRIPTS_LOCATION) {
    Write-Output "Cleaning node scripts at $NODE_SCRIPTS_LOCATION"
    Remove-Item -recur -force $NODE_SCRIPTS_LOCATION
  }
}

Function clone_node_scripts() {
  Write-Output "Cloning node scripts to $NODE_SCRIPTS_LOCATION"
  mkdir -p $NODE_SCRIPTS_LOCATION
  git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
}

Function clean_reqKick () {
  if (Test-Path $REQKICK_DIR) {
    Write-Output "Cleaning reqKick at $REQKICK_DIR..."
    Remove-Item -recur -force $REQKICK_DIR
  }
}

Function clone_reqKick () {
  Write-Output "Cloning reqKick to $REQKICK_DIR..."
  git clone https://github.com/Shippable/reqKick.git $REQKICK_DIR

  cd $REQKICK_DIR
  git checkout $SHIPPABLE_RELEASE_VERSION
  Write-Output "Running npm install for reqKick"
  npm install --silent
}

Function pull_reqProc () {
  Write-Output "Cloning reqProc image $REQPROC_MASTER_IMAGE"
  & docker info
  & docker pull $REQPROC_MASTER_IMAGE
}

Write-Output "RES_IMG_VER_NAME=$env:RES_IMG_VER_NAME"
#pull_reqProc
#clean_node_scripts
#clone_node_scripts
#clean_reqKick
#clone_reqKick