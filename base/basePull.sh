#!/bin/bash -e

export IMAGE_NAMES="drydock/u14nod:prod \
  drydock/u14nodall:prod \
  drydock/u14pyt:prod \
  drydock/u12nod:prod \
  drydock/u12nodpls:prod \
  drydock/u14pytall:prod \
  drydock/u14rub:prod \
  drydock/u12nodall:prod \
  drydock/u14jav:prod \
  drydock/u14pytpls:prod \
  drydock/u12pyt:prod \
  drydock/u12pls:prod \
  drydock/u14golall:prod \
  drydock/u14gol:prod \
  drydock/u12:prod \
  drydock/u14nodpls:prod \
  drydock/u12pytpls:prod \
  drydock/u12pytall:prod \
  drydock/u12rub:prod \
  drydock/u12ruball:prod \
  drydock/u14:prod \
  drydock/u14pls:prod \
  drydock/u12javpls:prod \
  drydock/u14scapls:prod \
  drydock/u14rubpls:prod \
  drydock/u14sca:prod \
  drydock/u14javall:prod \
  drydock/u14ruball:prod \
  drydock/u12javall:prod \
  drydock/u14php:prod \
  drydock/u12jav:prod \
  drydock/u14all:prod \
  drydock/u12rubpls:prod \
  drydock/u12golpls:prod \
  drydock/u14golpls:prod \
  drydock/u12golall:prod \
  drydock/u12all:prod \
  drydock/u14javpls:prod \
  drydock/u14phpall:prod \
  drydock/u12phppls:prod \
  drydock/u14phppls:prod \
  drydock/u14clo:prod \
  drydock/u12phpall:prod \
  drydock/u12scaall:prod \
  drydock/u12sca:prod \
  drydock/u14cloall:prod \
  drydock/u12gol:prod \
  drydock/u14scaall:prod \
  drydock/u12scapls:prod \
  drydock/u12php:prod \
  drydock/u12cloall:prod \
  drydock/u12clopls:prod \
  drydock/u14clopls:prod \
  drydock/u12clo:prod \
  drydock/u12cpp:prod \
  drydock/u14cpp:prod "


pull_images() {
echo "DRYDOCK_TAG=$DRYDOCK_TAG"
#  for image in $IMAGE_NAMES; do
#    echo "Pulling -------------------> $image"
#    sudo docker pull $image
#  done
}

pull_images
