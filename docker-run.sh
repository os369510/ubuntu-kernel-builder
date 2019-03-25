#!/bin/bash
set -x
function usage()
{
    echo "Usage: $(basename "$0") [Optional] Mandatory"
    echo ""
    echo "Mandatory:"
    echo "  --img   Specify docker image."
    echo ""
    echo "Optional:"
    echo "  --debug Keep STDIN open."
    echo "  --pkg   Package to build."
    echo ""
    exit 1
}
function check_docker_installed()
{
    local ret=$1
    local ver=""
    local installed='255'

    echo "# Step.$STEPS Check docker whether already installed?"

    ver=`docker --version`
    installed=`echo $?`
    if [ "$installed" -eq '0' ]; then
        echo "-- $ver"
    else
        echo "-- not found docker."
    fi
    STEPS=$(($STEPS+1))

    eval $ret="'$installed'"
}
function check_docker_image_exist()
{
    local ret=$1
    local id=""
    local existed='255'

    echo "# Step.$STEPS Check docker image of arch whether existed?"
    echo "-- Required docker image: $DOCKER_IMG"

    id=`docker images -q $DOCKER_IMG| head -n 1`
    if [ "$id" != "" ]; then
        echo "--- Image ID - $id"
        existed=0
    else
        echo "-- not found $DOCKER_IMG"
    fi
    STEPS=$(($STEPS+1))

    eval $ret="'$existed'"
}
function get_same_container_num()
{
    local ret=$1
    local count='0'

    echo "# Step.$STEPS Get the number of same container."

    count=`docker ps -a| grep $2| wc -l`
    STEPS=$(($STEPS+1))

    eval $ret="'$count'"
}
STEPS=1

WORK_DIR="Workspace"
VOL_NAME="ubuntu-kernle-builder-work-area"
DEBUG="no"

while [ -n "$1" ]; do
    case "$1" in
        --img)
            IMG="$2"
            shift 2;;
        --pkg)
            PKG="$2"
            shift 2;;
        --debug)
            DEBUG="yes"
            shift 1;;
        *)
            echo "ERROR: unknown option $1"
            echo ""
            usage;;
    esac
done

if [ -z "$IMG" ]; then usage; fi

DOCKER_BASE_NAME=${IMG#*/}
DOCKER_IMG=$IMG
VOL="$HOME/$WORK_DIR/$VOL_NAME"
order=0

if [ ! -d $VOL ]; then
    mkdir $VOL
fi

if [ -f "$PKG" ]; then
    cp "$PKG" "$VOL"
fi

check_docker_installed res
[ "$res" -ne 0 ] && exit -1

check_docker_image_exist res
[ "$res" -ne 0 ] && exit -1

get_same_container_num order $DOCKER_BASE_NAME
order=$(($order+1))
DOCKER_NAME="${DOCKER_IMG//\//-}-$order"

if [ "$DEBUG" == "yes" ]; then
    docker run -it --rm -w /home/jeremysu -v $VOL:/home/jeremysu --name $DOCKER_NAME $DOCKER_IMG
else
    docker run -it --rm -w /home/jeremysu -v $VOL:/home/jeremysu --name $DOCKER_NAME $DOCKER_IMG
fi
