#!/usr/bin/env bash

#
# Generate a random username
#
function generate_username() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n 1 | tr '[:upper:]' '[:lower:]'
}

export -f generate_username
