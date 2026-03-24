#!/usr/bin/env bash

# Platform variables
OS=$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')
ARCH=$(uname -m | sed 's/x86_64/amd64/g' | sed 's/aarch64/arm64/g')
PLATFORM=${OS}-${ARCH}

# Current directory
CURRENT_DIR=$(pwd)

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Default base path
DEFAULT_BASE_PATH="${CURRENT_DIR}/.default"

# Source base path
SOURCE_BASE_PATH="${CURRENT_DIR}/env"

# Cache directory
CACHE_DIR="${CURRENT_DIR}/.cache"

# Templates directory
TEMPLATES_DIR="${CURRENT_DIR}/.templates"

# Certificates directory
CERTS_DIR="${CURRENT_DIR}/step-certs"

# Channel artifacts directory
CHANNEL_ARTIFACTS_DIR="${CURRENT_DIR}/channel-artifacts"
