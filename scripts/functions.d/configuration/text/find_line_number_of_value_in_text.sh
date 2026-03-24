#!/usr/bin/env bash

#
# Find line number of the first line containing the value in a text
#
function find_line_number_of_value_in_text() {
    local VALUE
    local TEXT
    local LINE_NUMBER

    VALUE=$1
    TEXT=$2

    # find the line number of the first line containing the value in the text
    LINE_NUMBER=$(echo "${TEXT}" | grep -n "${VALUE}" | cut -d: -f1)

    # return the line number minus 1
    echo "$((LINE_NUMBER - 1))"
}

export -f find_line_number_of_value_in_text
