$ErrorActionPreference = "Stop"

Function pull_images() {
  Write-Output "IMG_VER=$env:IMG_VER"
  $imgList = (Get-Content images.txt) -join " "
  Write-Output "IMAGE_LIST=$imgList"

  foreach ($IMG in $imgList.Split(" ")) {
    Write-Output "Pulling -------------------> ${IMG}:${env:IMG_VER}"
    docker pull "${IMG}:${env:IMG_VER}"
  }
}

pull_images
