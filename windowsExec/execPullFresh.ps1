$ErrorActionPreference = "Stop"
$SHIPPABLE_RELEASE_VERSION = "$env:REL_VER"

Function pull_images() {
  if (Test-Path ".\images.txt") {
    foreach ($IMAGE_NAME in Get-Content ".\images.txt") {
      Write-Output "Pulling -------------------> ${IMAGE_NAME}:${SHIPPABLE_RELEASE_VERSION}"
      docker pull ${IMAGE_NAME}:${SHIPPABLE_RELEASE_VERSION}
      if ($LASTEXITCODE -ne 0) {
        throw "Exit code is $LASTEXITCODE"
      }
    }
  }
}

pull_images
