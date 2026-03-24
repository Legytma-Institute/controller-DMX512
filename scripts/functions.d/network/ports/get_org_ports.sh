#!/usr/bin/env bash

#
# Get organization port mapping
#
get_org_ports() {
    local ORG_NAME=$1
    case "${ORG_NAME}" in
        "legytma")
            echo "7010 5000 5110"
            ;;
        "aquaslides")
            echo "7011 5001 5210"
            ;;
        *)
            echo "7000 5000 5100"
            ;;
    esac
}

export -f get_org_ports
