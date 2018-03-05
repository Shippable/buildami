$ErrorActionPreference = "Stop"

Function pull_images() {
  echo "RES_IMG_VER_NAME=$env:RES_IMG_VER_NAME"

  foreach ($IMAGE_NAME in $env:IMAGE_NAMES_SPACED.Split(" ")) {
    echo "Pulling -------------------> ${IMAGE_NAME}:${env:RES_IMG_VER_NAME}"
    docker pull "${IMAGE_NAME}:${env:RES_IMG_VER_NAME}"
  }
}

pull_images
