#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../files/manage/create_directory.sh"

function generate_postgres_database_init_script() {
    local POSTGRES_SCRIPTS=$1
    local NEW_DATABASE=$2
    local NEW_USER=$3
    local NEW_PASSWORD=$4
    local FILE_NAME=$5
    local WITH_CREATE_DATABASE=$6

    create_directory ${POSTGRES_SCRIPTS}

    local TEMP_FILE_PATH=/tmp/${FILE_NAME}
    local CURRENT_FILE_PATH=${POSTGRES_SCRIPTS}/${FILE_NAME}
    local WITH_OPTIONS=""

    if [ "${WITH_CREATE_DATABASE}" = "WITH_CREATE_DATABASE" ]; then
        WITH_OPTIONS=" WITH CREATEDB"
    fi

    echo "set -e" > ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" --dbname \"\$POSTGRES_DB\" -tc \"SELECT 1 FROM pg_database WHERE datname = '${NEW_DATABASE}'\" | grep -q 1 || psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" --dbname \"\$POSTGRES_DB\" -c \"CREATE DATABASE ${NEW_DATABASE}\"" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" --dbname \"\$POSTGRES_DB\" <<-EOSQL" >> ${TEMP_FILE_PATH}
    echo "DO" >> ${TEMP_FILE_PATH}
    echo '\$do\$' >> ${TEMP_FILE_PATH}
    echo "BEGIN" >> ${TEMP_FILE_PATH}
    echo "   IF NOT EXISTS (" >> ${TEMP_FILE_PATH}
    echo "      SELECT FROM pg_catalog.pg_roles" >> ${TEMP_FILE_PATH}
    echo "         WHERE  rolname = '${NEW_USER}'" >> ${TEMP_FILE_PATH}
    echo "   ) THEN" >> ${TEMP_FILE_PATH}
    echo "      BEGIN   -- nested block" >> ${TEMP_FILE_PATH}
    echo "         CREATE ROLE ${NEW_USER} LOGIN PASSWORD '${NEW_PASSWORD}'${WITH_OPTIONS};" >> ${TEMP_FILE_PATH}
    echo "      EXCEPTION" >> ${TEMP_FILE_PATH}
    echo "         WHEN duplicate_object THEN" >> ${TEMP_FILE_PATH}
    echo "            RAISE NOTICE 'Role ${NEW_USER} was just created by a concurrent transaction. Skipping.';" >> ${TEMP_FILE_PATH}
    echo "      END;" >> ${TEMP_FILE_PATH}
    echo "   END IF;" >> ${TEMP_FILE_PATH}
    echo "END" >> ${TEMP_FILE_PATH}
    echo '\$do\$;' >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "REVOKE ALL PRIVILEGES ON DATABASE postgres FROM ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL ON DATABASE ${NEW_DATABASE} TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT CONNECT ON DATABASE ${NEW_DATABASE} TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL ON SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT USAGE ON SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT CREATE ON SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL PRIVILEGES ON SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${NEW_USER};" >> ${TEMP_FILE_PATH}
    echo "EOSQL" >> ${TEMP_FILE_PATH}
    echo "" >> ${TEMP_FILE_PATH}
    echo "psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" --dbname \"\$POSTGRES_DB\" -tc \"ALTER DATABASE ${NEW_DATABASE} OWNER TO ${NEW_USER}\"" >> ${TEMP_FILE_PATH}

    chmod +x ${TEMP_FILE_PATH}

    if [ ! -f "${CURRENT_FILE_PATH}" ] || [ "$(cat ${CURRENT_FILE_PATH})" != "$(cat ${TEMP_FILE_PATH})" ]; then
        mv ${TEMP_FILE_PATH} ${CURRENT_FILE_PATH}
    fi
}

export -f generate_postgres_database_init_script
