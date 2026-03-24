#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/print_table_line.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/print_table_separator_line.sh"

#
# This function prints a table with the given columns and rows drawing lines between columns and around the table.
# The first argument is the count of columns, the next arguments are the color of each column, the next arguments are the headers of the table and the rest of the arguments are the content of the table.
#
# Example:
# print_table "3" "\033[90m" "\033[94m" "\033[92m" "Col 1" "C2" "Column 3" "Row 1" "Row 2" "Row 3" " " " " " " "Row 4" "Row 5" "Row 6" "-" "-" "-" "Row 7" "Row 8" "Row 9"
#
# Output:
# +----------+----------+----------+
# |   Col 1  |    C2    | Column 3 |
# +----------+----------+----------+
# | Row 1    | Row 2    | Row 3    |
# |          |          |          |
# | Row 4    | Row 5    | Row 6    |
# +----------+----------+----------+
# | Row 7    | Row 8    | Row 9    |
# +----------+----------+----------+
#
function print_table() {
    local COLUMN_COUNT
    local HEADERS
    local COLORS
    local DATA
    local COLUMN_WIDTHS
    local MAX_WIDTH
    local I
    local J
    local CELL_WIDTH
    local HEADER_ROW
    local DATA_ROW

    # First argument is the number of columns
    COLUMN_COUNT=$1
    shift

    # Next arguments are colors
    COLORS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        COLORS+=("$1")
        shift
    done

    # Next arguments are headers
    HEADERS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        HEADERS+=("$1")
        shift
    done

    # Remaining arguments are data
    DATA=("$@")

    # Calculate column widths
    COLUMN_WIDTHS=()
    for ((I=0; I<COLUMN_COUNT; I++)); do
        MAX_WIDTH=${#HEADERS[I]}

        # Check data cells for this column
        for ((J=I; J<${#DATA[@]}; J+=COLUMN_COUNT)); do
            CELL_WIDTH=${#DATA[J]}
            if [ "${CELL_WIDTH}" -gt "${MAX_WIDTH}" ]; then
                MAX_WIDTH="${CELL_WIDTH}"
            fi
        done

        # Store the column width
        COLUMN_WIDTHS+=("${MAX_WIDTH}")
    done

    # Print top border
    print_table_line "${COLUMN_WIDTHS[@]}"

    # Print header row
    HEADER_ROW="|"
    for ((I=0; I<COLUMN_COUNT; I++)); do
        # Calculate padding for centering
        HEADER_LENGTH=${#HEADERS[I]}
        TOTAL_WIDTH=${COLUMN_WIDTHS[I]}
        LEFT_PAD=$(( (TOTAL_WIDTH - HEADER_LENGTH) / 2 ))
        RIGHT_PAD=$(( TOTAL_WIDTH - HEADER_LENGTH - LEFT_PAD ))

        # Create centered header with padding
        CENTERED_HEADER="$(printf "%*s%s%*s" ${LEFT_PAD} "" "${HEADERS[I]}" ${RIGHT_PAD} "")"
        HEADER_ROW+=" \033[1m${CENTERED_HEADER}\033[0m |"
    done
    echo -e "${HEADER_ROW}"

    # Print separator line after header
    print_table_line "${COLUMN_WIDTHS[@]}"

    # Print data rows
    for ((I=0; I<${#DATA[@]}; I+=COLUMN_COUNT)); do
        # Check if this row is a separator row (all cells contain "-")
        IS_SEPARATOR=true
        for ((J=0; J<COLUMN_COUNT; J++)); do
            if [ "${DATA[I+J]}" != "-" ]; then
                IS_SEPARATOR=false
                break
            fi
        done

        if [ "${IS_SEPARATOR}" = true ]; then
            # Print separator line
            print_table_separator_line "${COLUMN_WIDTHS[@]}"
        else
            # Print normal data row
            DATA_ROW="|"
            for ((J=0; J<COLUMN_COUNT; J++)); do
                DATA_ROW+=" ${COLORS[J]}$(printf "%-${COLUMN_WIDTHS[J]}s" "${DATA[I+J]}")\033[0m |"
            done
            echo -e "${DATA_ROW}"
        fi
    done

    # Print bottom border
    print_table_line "${COLUMN_WIDTHS[@]}"
}

export -f print_table
