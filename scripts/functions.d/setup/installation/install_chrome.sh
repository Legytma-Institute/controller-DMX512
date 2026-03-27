#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/logging/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"

#
# Install Chrome browser
#
function install_chrome() {
    if ! command -v google-chrome &> /dev/null; then
        debug "Installing Chrome browser..."

        install_packages curl

        curl -o /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

        sudo apt install -y /tmp/google-chrome.deb

        rm -rf /tmp/google-chrome.deb

        sudo ln -s /usr/bin/google-chrome /usr/local/bin/chrome

        debug "Chrome browser installed successfully"
    fi
}

export -f install_chrome
