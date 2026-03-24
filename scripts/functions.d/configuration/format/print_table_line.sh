#!/usr/bin/env bash

#
# Print a table line
#
function print_table_line() {
    local COLLS_WIDTH
    local COLLS_COUNT
    local ROW
    local I

    COLLS_WIDTH=("$@")
    COLLS_COUNT=${#COLLS_WIDTH[@]}

    ROW="+"

    for ((I=0; I<COLLS_COUNT; I++)); do
        # Add a string with cell width repetitions of "-" to the row
        ROW+="$(printf "%-$((COLLS_WIDTH[I]+2))s" "-" | sed 's/ /-/g')"
        ROW+="+"
    done

    echo "${ROW}"
}

export -f print_table_line
