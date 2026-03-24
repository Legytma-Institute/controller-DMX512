#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/debug.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../shell/sourcing/add_export.sh"

#
# Install GraalVM
#
function install_graalvm() {
    local JDK_MAJOR_VERSION
    local FILES
    local FILE

    JDK_MAJOR_VERSION=$1

    if [ -z "${JDK_MAJOR_VERSION}" ]; then
        JDK_MAJOR_VERSION=25
    fi

    GRAALVM_HOME="${GRAALVM_HOME:-/opt/graalvm-jdk-${JDK_MAJOR_VERSION}}"

    if ! command -v native-image &> /dev/null; then
        debug "Installing GraalVM..."

        install_packages curl

        curl -L -o /tmp/graalvm-jdk-${JDK_MAJOR_VERSION}_linux-x64_bin.tar.gz https://download.oracle.com/graalvm/${JDK_MAJOR_VERSION}/latest/graalvm-jdk-${JDK_MAJOR_VERSION}_linux-x64_bin.tar.gz

        sudo tar -xzf /tmp/graalvm-jdk-${JDK_MAJOR_VERSION}_linux-x64_bin.tar.gz -C /opt/

        rm -rf /tmp/graalvm-jdk-${JDK_MAJOR_VERSION}_linux-x64_bin.tar.gz

        sudo mv "$(ls -d --group-directories-first /opt/graalvm-jdk-* | head --lines 1)" "${GRAALVM_HOME}"

        FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")

        for FILE in "${FILES[@]}"; do
            add_export "GRAALVM_HOME=${GRAALVM_HOME}" "${FILE}"
            add_export "PATH=\"\$GRAALVM_HOME/bin:\$PATH\"" "${FILE}"
        done

        export GRAALVM_HOME="${GRAALVM_HOME}"
        export PATH="${GRAALVM_HOME}/bin:${PATH}"

        debug "GraalVM installed successfully"
    fi
}

export -f install_graalvm
