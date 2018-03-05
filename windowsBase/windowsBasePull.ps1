$ErrorActionPreference = "Stop"

Function pull_images() {
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"

  foreach ($IMAGE_NAME in Get-Content "images.txt") {
    echo "Pulling -------------------> ${IMAGE_NAME}:${RES_IMG_VER_NAME}"
    docker pull "${IMAGE_NAME}:${RES_IMG_VER_NAME}"
  }
}

pull_images
