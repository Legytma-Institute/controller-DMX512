#!/usr/bin/env bash

#
# Add host entries to /etc/hosts
#
function add_hosts() {
    local IP_ADDRESS
    local HOSTS
    local HOST

    IP_ADDRESS=$1
    shift 1

    HOSTS=("$@")

    for HOST in "${HOSTS[@]}"; do
        TMP_FILE=$(mktemp)

        awk -v ip="${IP_ADDRESS}" -v host="${HOST}" '
            BEGIN { replaced = 0 }
            {
                if ($0 ~ "^[[:space:]]*[0-9A-Fa-f:\\.]+[[:space:]]+" host "([[:space:]]+|$)") {
                    if (!replaced) { print ip " " host; replaced = 1 }
                    next
                }
                print
            }
            END {
                if (!replaced) { print ip " " host }
            }
        ' /etc/hosts > "${TMP_FILE}"

        sudo cp "${TMP_FILE}" /etc/hosts
        rm -f "${TMP_FILE}"
    done
}

export -f add_hosts
