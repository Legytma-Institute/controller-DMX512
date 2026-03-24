#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../format/get_value_from_json_or_yaml.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../text/find_line_number_of_value_in_text.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../format/replace_field_values_in_json_or_yaml.sh"

#
# Replace a environment variable in a docker compose file
#
function replace_environment_variable_in_docker_compose_file() {
    local DOCKER_COMPOSE_FILE
    local SERVICE_NAME
    local ENVIRONMENT_VARIABLE
    local VALUE
    local ENVIRONMENT
    local INDEX

    DOCKER_COMPOSE_FILE=$1
    SERVICE_NAME=$2
    ENVIRONMENT_VARIABLE=$3
    VALUE=$4

    ENVIRONMENT="$(get_value_from_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment")"
    INDEX=$(find_line_number_of_value_in_text "${ENVIRONMENT_VARIABLE}" "${ENVIRONMENT}")

    # If the index is different from -1, replace the environment variable
    if [ "${INDEX}" != "-1" ]; then
        replace_field_values_in_json_or_yaml "${DOCKER_COMPOSE_FILE}" ".services.\"${SERVICE_NAME}\".environment[${INDEX}]" "${ENVIRONMENT_VARIABLE}=${VALUE}"
    else
        # Add the environment variable to the end of the environment array
        yq eval ".services.\"${SERVICE_NAME}\".environment += \"${ENVIRONMENT_VARIABLE}=${VALUE}\"" -i "${DOCKER_COMPOSE_FILE}"
    fi
}

export -f replace_environment_variable_in_docker_compose_file
