#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_android_sdk.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../setup/installation/install_chrome.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/sourcing/add_export.sh"

#
# Install Flutter SDK
#
function install_flutter() {
    local FLUTTER_VERSION

    FLUTTER_VERSION=$1

    if ! command -v flutter &> /dev/null; then
        install_android_sdk
        install_chrome

        debug "Installing Flutter SDK..."

        sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build libgtk-3-dev liblzma-dev mesa-utils

        if [ -z "${FLUTTER_VERSION}" ]; then
            FLUTTER_VERSION="3.38.6"
        fi

        curl -o /tmp/flutter_linux.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

        mkdir -p "${HOME}/develop/"

        tar -xf /tmp/flutter_linux.tar.xz -C "${HOME}/develop/"

        rm -rf /tmp/flutter_linux.tar.xz

        add_export "PATH=\"\${HOME}/develop/flutter/bin:\${PATH}\""

        export PATH="${HOME}/develop/flutter/bin:${PATH}"

        flutter --suppress-analytics --disable-analytics
        flutter doctor --android-licenses << EOF
y
y
y
y
y
y
y
y
EOF

        flutter doctor
        flutter --version
        dart --version

        debug "Flutter SDK installed successfully"
    fi
}

export -f install_flutter
