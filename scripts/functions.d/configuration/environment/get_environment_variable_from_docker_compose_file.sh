#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../format/get_value_from_json_or_yaml.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../text/find_line_number_of_value_in_text.sh"

#
# Get environment variable from a docker compose file
#
function get_environment_variable_from_docker_compose_file() {
    local DOCKER_COMPOSE_FILE
    local SERVICE_NAME
    local ENVIRONMENT_VARIABLE
    local ENVIRONMENT
    local INDEX
    local VALUE

    DOCKER_COMPOSE_FILE=$1
    SERVICE_NAME=$2
    ENVIRONMENT_VARIABLE=$3

    ENVIRONMENT="$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment")"
    INDEX=$(find_line_number_of_value_in_text "${ENVIRONMENT_VARIABLE}" "${ENVIRONMENT}")

    # If the index is different from -1, return the environment variable
    if [ "${INDEX}" != "-1" ]; then
        VALUE=$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment[${INDEX}]")

        echo "${VALUE}" | cut -d'=' -f2
    fi
}

export -f get_environment_variable_from_docker_compose_file
