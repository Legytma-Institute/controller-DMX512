#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/sourcing/add_export.sh"

#
# Install Android SDK
#
function install_android_sdk() {
    local COMMAND_LINE_TOOLS_URL

    if ! command -v sdkmanager &> /dev/null; then
        COMMAND_LINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"

        install_packages curl
        install_packages unzip

        debug "Installing Android SDK..."

        mkdir -p "${HOME}/android/sdk/cmdline-tools"

        curl -o /tmp/commandlinetools-linux.zip "${COMMAND_LINE_TOOLS_URL}"

        unzip -q /tmp/commandlinetools-linux.zip -d /tmp/commandlinetools-linux

        mv /tmp/commandlinetools-linux/cmdline-tools "${HOME}/android/sdk/cmdline-tools/latest"

        rm -rf /tmp/commandlinetools-linux.zip
        rm -rf /tmp/commandlinetools-linux

        add_export "ANDROID_HOME=\"\${HOME}/android/sdk\""
        add_export "PATH=\"\${ANDROID_HOME}/cmdline-tools/latest/bin:\${PATH}\""
        add_export "PATH=\"\${ANDROID_HOME}/platform-tools:\${PATH}\""

        export ANDROID_HOME="${HOME}/android/sdk"
        export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"
        export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

        sdkmanager --licenses << EOF
y
y
y
y
y
y
y
y
EOF

        sdkmanager --install "platform-tools" "platforms;android-36.1" "build-tools;36.1.0" "cmake;4.1.2" "ndk;29.0.14206865"
        sdkmanager --update

        debug "Android SDK installed successfully"
    fi
}

export -f install_android_sdk
