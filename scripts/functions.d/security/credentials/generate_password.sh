#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_docker.sh"

# # Create a volume and copy initial files
# function createVolume {
#     local SOURCE_PATH=$1
#     local VOLUME_NAME=$2

#     install_docker

#     echo "Creating '${VOLUME_NAME}' volume and copying initial configuration..."

#     docker run --rm -v ${SOURCE_PATH}:/source -v ${VOLUME_NAME}:/destination alpine sh -c "cp -af /source/* /destination"
# }

# export -f createVolume

# Generate a random password
function generate_password() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w40 | head -n 1
}

export -f generate_password
