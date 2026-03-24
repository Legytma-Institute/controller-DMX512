#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../files/manage/create_directory.sh"

function generate_doltdb_database_init_script() {
    local DOLTDB_SCRIPTS=$1
    local NEW_DATABASE=$2
    local NEW_USER=$3
    local NEW_PASSWORD=$4
    local FILE_NAME=$5
    local WITH_CREATE_DATABASE=$6

    create_directory ${DOLTDB_SCRIPTS}

    local TEMP_FILE_PATH=/tmp/${FILE_NAME}
    local CURRENT_FILE_PATH=${DOLTDB_SCRIPTS}/${FILE_NAME}

    echo "CREATE DATABASE IF NOT EXISTS ${NEW_DATABASE} /*\!40100 DEFAULT CHARACTER SET utf8 */;" > ${TEMP_FILE_PATH}
    echo "CREATE USER ${NEW_USER} IDENTIFIED BY '${NEW_PASSWORD}';" >> ${TEMP_FILE_PATH}
    echo "GRANT USAGE ON *.* TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL PRIVILEGES ON ${NEW_DATABASE}.* TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_add TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_commit TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_backup TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_clone TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_fetch TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_undrop TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_purge_dropped_databases TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_gc TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_pull TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_push TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_remote TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_branch TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    echo "GRANT EXECUTE ON PROCEDURE ${NEW_DATABASE}.dolt_merge TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}

    if [ "${WITH_CREATE_DATABASE}" = "WITH_CREATE_DATABASE" ]; then
        echo "GRANT CREATE, DROP, REFERENCES, ALTER ON *.* TO '${NEW_USER}'@'%';" >> ${TEMP_FILE_PATH}
    fi

    echo "FLUSH PRIVILEGES;" >> ${TEMP_FILE_PATH}

    if [ ! -f "${CURRENT_FILE_PATH}" ] || [ "$(cat ${CURRENT_FILE_PATH})" != "$(cat ${TEMP_FILE_PATH})" ]; then
       sudo mv ${TEMP_FILE_PATH} ${CURRENT_FILE_PATH}
    fi
}

export -f generate_doltdb_database_init_script
