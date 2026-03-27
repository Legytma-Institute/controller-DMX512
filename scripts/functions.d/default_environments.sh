#!/usr/bin/env bash

# Platform variables
export OS=$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')
export ARCH=$(uname -m | sed 's/x86_64/amd64/g' | sed 's/aarch64/arm64/g')
export PLATFORM=${OS}-${ARCH}

# Current directory
export CURRENT_DIR=$(pwd)

# Script directory
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. > /dev/null 2>&1 && pwd)"

# Default base path
export DEFAULT_BASE_PATH="${CURRENT_DIR}/.default"

# Source base path
export SOURCE_BASE_PATH="${CURRENT_DIR}/env"

# Cache directory
export CACHE_DIR="${CURRENT_DIR}/.cache"

# Templates directory
export TEMPLATES_DIR="${CURRENT_DIR}/.templates"

# Certificates directory
export CERTS_DIR="${CURRENT_DIR}/step-certs"

# Channel artifacts directory
export CHANNEL_ARTIFACTS_DIR="${CURRENT_DIR}/channel-artifacts"
