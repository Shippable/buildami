$ErrorActionPreference = "Stop"

Function pull_images() {
  echo "RES_IMG_VER_NAME=$RES_IMG_VER_NAME"

  foreach ($line in Get-Content "images.txt") {
    echo "line is $line"
  }
}

pull_images
