$ErrorActionPreference = "Stop"

Function pull_images() {
  Write-Output "REL_VER=$env:REL_VER"
  $imgList = (Get-Content images.txt) -join " "
  Write-Output "IMAGE_LIST=$imgList"

  foreach ($IMG in $imgList.Split(" ")) {
    Write-Output "Pulling -------------------> ${IMG}:${env:REL_VER}"
    docker pull "${IMG}:${env:REL_VER}"
  }
}

pull_images
