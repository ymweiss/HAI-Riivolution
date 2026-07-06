#!/bin/bash
#
# Build HAI-Riivolution inside Docker.
#
# Uses the pinned devkitpro/devkitppc:20210726 image (same as CI) so devkitARM
# release 56 stays fixed. Do not upgrade devkitARM via dkp-pacman.
#

set -e

DOCKER_IMAGE="devkitpro/devkitppc:20210726"

echo "Running build script for HAI-Riivolution..."
echo ""

if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Docker is required to build HAI-Riivolution"
    exit 1
fi

if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
    echo "Pulling $DOCKER_IMAGE container..."
    docker pull "$DOCKER_IMAGE"
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)

echo "Building HAI-Riivolution with devkitPPC + devkitARM (pinned image)..."
echo "Project directory: $PROJECT_ROOT"
echo ""

if docker run --rm -v "$PROJECT_ROOT:/mnt" "$DOCKER_IMAGE" bash -c "
    # Buster apt mirrors are EOL; use the snapshot URLs already present in the image.
    sed -i 's|^# deb http://snapshot|deb http://snapshot|' /etc/apt/sources.list
    sed -i '/^deb http:\/\/deb\.debian\.org/d' /etc/apt/sources.list
    sed -i '/^deb http:\/\/security\.debian\.org/d' /etc/apt/sources.list
    rm -f /etc/apt/sources.list.d/buster-backports.list
    echo 'Acquire::Check-Valid-Until \"false\";' > /etc/apt/apt.conf.d/99no-check-valid-until

    dpkg --add-architecture i386
    apt-get update
    apt-get install -y --no-install-recommends \
        g++ libgcc1:i386 zlib1g:i386 python3 python3-yaml

    cd /mnt
    make -j\$(nproc)
"; then
    echo ""
    echo "Build successful"
    echo ""
    exit 0
else
    echo ""
    echo "Build failed"
    echo ""
    exit 1
fi
