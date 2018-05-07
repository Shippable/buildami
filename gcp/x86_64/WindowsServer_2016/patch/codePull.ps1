$ErrorActionPreference = "Stop"

$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE/node"
$REQKICK_DIR = "$env:USERPROFILE/Shippable/reqKick"
$REQPROC_MASTER_IMAGE = "drydock/w16reqproc:master"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "$env:REL_VER"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"

Function clean_node_scripts() {
  if (Test-Path $NODE_SCRIPTS_LOCATION) {
    Write-Output "Cleaning node scripts"
    Remove-Item -recur -force $NODE_SCRIPTS_LOCATION
    start-sleep 5
  }
}

Function clone_node_scripts() {
  mkdir -p $NODE_SCRIPTS_LOCATION
  git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
  start-sleep 5
}

Function clean_reqKick () {
  if (Test-Path $REQKICK_DIR) {
    Write-Output "Cleaning reqKick..."
    Remove-Item -recur -force $REQKICK_DIR
    start-sleep 5
  }
}

Function clone_reqKick () {
  Write-Output "Cloning reqKick..."
  git clone https://github.com/Shippable/reqKick.git $REQKICK_DIR
  start-sleep 5

  Push-Location $REQKICK_DIR
    git checkout $SHIPPABLE_RELEASE_VERSION
    npm install
  Pop-Location
}

Function pull_reqProc () {
  docker pull $REQPROC_MASTER_IMAGE
}

Write-Output "REL_VER=$env:REL_VER"
clean_node_scripts
clone_node_scripts
clean_reqKick
clone_reqKick
pull_reqProc