#!/usr/bin/env bash

#
# Print the terminal prompt with the script command, simulating the terminal
# Username in green, 2 spaces, a arrow in red, the current directory in blue, the current branch name in red surrounded by blue parentheses and after the $ symbol in white the command with its arguments
# All the text before the $ symbol is in bold color, the command and its arguments are in white
#
function print_prompt() {
    echo -e "\033[0;32m${USER}\033[0m \033[1;31m➜\033[0m \033[1;34m${CURRENT_DIR}\033[0m \033[1;34m(\033[0m\033[1;31m$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")\033[1;34m)\033[0m $ $*"
}

export -f print_prompt
