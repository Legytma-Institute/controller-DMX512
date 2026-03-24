#!/usr/bin/env bash

#
# Install docker
#
function install_docker() {
    if ! command -v docker &> /dev/null; then
        sudo apt update
        sudo apt install -y ca-certificates curl

        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        # shellcheck disable=SC1091
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || exit 1

        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
        sudo systemctl start containerd.service
        sudo systemctl start docker.service
    fi
}

export -f install_docker
