#!/bin/bash -i
#
#
# Check docker images exist.
DOCKER_IMAGE=`docker images | grep "arm-auto-sw" | sed -r 's/(.{21}).*/\1/'`
if [ $DOCKER_IMAGE = "multiarch/ubuntu-core" ]; then
  echo -n "Docker images exists, delete the existed docker image and rebuild te image?(y/n):"
  read -r DEL
  if [ $DEL = "y" ] || [ $DEL = "yes" ]; then
    docker image rm multiarch/ubuntu-core:arm-auto-sw
    echo "Old docker mimage deleted."
    echo "Rebuild docker image."
    docker build --rm -t multiarch/ubuntu-core:arm-auto-sw .
    docker image prune -f
    exit
  fi
  echo "Do nothing."
  exit
fi

# Docker image does not exist.
echo "Build docker image."
docker build --rm -t multiarch/ubuntu-core:arm-auto-sw .
docker image prune -f
