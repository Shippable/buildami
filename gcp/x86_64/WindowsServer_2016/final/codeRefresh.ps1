$ErrorActionPreference = "Stop"

$NODE_ARCHITECTURE="$env:ARCHITECTURE"
$NODE_OPERATING_SYSTEM="$env:OS"
$NODE_DOWNLOAD_URL="$env:NODE_DOWNLOAD_URL"
$EXEC_IMAGE="$env:REQPROC_IMAGE"
$REQKICK_DOWNLOAD_URL="$env:REQKICK_DOWNLOAD_URL"
$IMG_VER = "$env:IMG_VER"

$NODE_SCRIPTS_TMP_LOC="$env:TEMP/node.zip"
$REQKICK_TMP_LOC="$env:TEMP/reqKick.zip"
$NODE_SCRIPTS_LOCATION="/root/node"
$NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOCATION/shipctl"
$REQKICK_LOCATION="/var/lib/shippable/reqKick"

Function get_node_scripts {
  if (Test-Path $NODE_SCRIPTS_LOCATION) {
    Write-Output "Cleaning node scripts dir..."
    Remove-Item -recur -force $NODE_SCRIPTS_LOCATION
  }
  Write-Output "|___creating node scripts dir"
  mkdir -p $NODE_SCRIPTS_LOCATION

  Write-Output "|___downloading node scripts zip package"
  Invoke-RestMethod "$NODE_DOWNLOAD_URL" -OutFile $NODE_SCRIPTS_TMP_LOC

  Write-Output "|___extracting node scripts"
  Expand-Archive $NODE_SCRIPTS_TMP_LOC -DestinationPath $NODE_SCRIPTS_LOCATION
}

Function install_shipctl() {
  Write-Output "Installing shipctl components"
  Invoke-Expression "$NODE_SHIPCTL_LOCATION/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/install.ps1"
}

Function get_reqKick {
  if (Test-Path $REQKICK_LOCATION) {
    Write-Output "Cleaning reqKick dir..."
    Remove-Item -recur -force $REQKICK_LOCATION
  }
  Write-Output "|___creating reqKick dir"
  mkdir -p $REQKICK_LOCATION

  Write-Output "|___downloading reqKick zip package"
  Invoke-RestMethod "$REQKICK_DOWNLOAD_URL" -OutFile $REQKICK_TMP_LOC

  Write-Output "|___extracting reqKick"
  Expand-Archive $REQKICK_TMP_LOC -DestinationPath $REQKICK_LOCATION
}

Function pull_images() {
  $imgList = (Get-Content images.txt) -join " "
  Write-Output "IMAGE_LIST=$imgList"

  foreach ($IMG in $imgList.Split(" ")) {
    Write-Output "Pulling -------------------> ${IMG}:${IMG_VER}"
    docker pull "${IMG}:${IMG_VER}"
  }
}

Function pull_reqproc() {
  Write-Output "pulling tagged reqproc image: $EXEC_IMAGE"
  docker pull $EXEC_IMAGE
}

get_node_scripts
install_shipctl
get_reqKick
pull_images
pull_reqproc
