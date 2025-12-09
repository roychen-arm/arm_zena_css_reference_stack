#!/bin/bash -i
#
#
#
BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Usage
usage() { 
    echo "Usage: $0 " 1>&2
    echo "   -s|--share_folder   : relative path to folder you want to share with docker container" 1>&2
    exit 1 
}

COMMAND=/bin/bash
SHARE_FOLDER=''

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--share_folder) SHARE_FOLDER="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

pushd ${BASEDIR}

if [ "$SHARE_FOLDER" != '' ];
then
    mkdir -p $PWD/${SHARE_FOLDER}
    SHARE_COMMAND="-v $PWD/${SHARE_FOLDER}:/home/docker/share:rw"
fi

#enable X11 on host side
xhost local:

docker run \
    ${SHARE_COMMAND} \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -e DISPLAY=$DISPLAY \
    -e ARMLMD_LICENSE_FILE=$ARMLMD_LICENSE_FILE \
    -e ARM_TOOL_VARIANT=$ARM_TOOL_VARIANT \
    --network host -it --rm --privileged multiarch/ubuntu-core:arm-auto-sw $COMMAND

popd

