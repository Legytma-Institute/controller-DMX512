#!/usr/bin/env bash

#
# Print a table separator line
#
function print_table_separator_line() {
    local COLLS_WIDTH
    local COLLS_COUNT
    local ROW
    local I

    COLLS_WIDTH=("$@")
    COLLS_COUNT=${#COLLS_WIDTH[@]}

    ROW="+"

    for ((I=0; I<COLLS_COUNT; I++)); do
        # Add a string with cell width repetitions of "-" to the row
        ROW+="\033[90m$(printf "%-$((COLLS_WIDTH[I]+2))s" "-" | sed 's/ /-/g')\033[0m"
        ROW+="+"
    done

    echo -e "${ROW}"
}

export -f print_table_separator_line
