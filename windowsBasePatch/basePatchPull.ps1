$ErrorActionPreference = "Stop"

$NODE_SCRIPTS_LOCATION = "/root/node"
$BASE_DIR = "/var/lib/shippable"
$REQKICK_DIR = "$BASE_DIR/reqKick"
$REQPROC_MASTER_IMAGE = "drydock/w16reqproc:master"
$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "master"
$REPORTS_DOWNLOAD_URL = "https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"


Function clean_node_scripts() {
  rm -rf $NODE_SCRIPTS_LOCATION
}

Function clone_node_scripts() {
  mkdir -p $NODE_SCRIPTS_LOCATION
  git clone https://github.com/Shippable/node.git $NODE_SCRIPTS_LOCATION
}

Function clean_reqKick () {
  echo "Cleaning reqKick..."
  rm -rf $REQKICK_DIR || true
}

Function clone_reqKick () {
  echo "Cloning reqKick..."
  git clone https://github.com/Shippable/reqKick.git $REQKICK_DIR

  pushd $REQKICK_DIR
    git checkout $SHIPPABLE_RELEASE_VERSION
    npm install
  popd
}

Function pull_reqProc () {
  docker pull $REQPROC_MASTER_IMAGE
}

clean_node_scripts
clone_node_scripts
clean_reqKick
clone_reqKick
pull_reqProc
