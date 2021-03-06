#!/bin/bash

# This script only defines the function to test if the last bash line had a non zero exit code.  it is used to interrupt terraform if local-exec ansible scripts fail.

RED='\033[0;31m' # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m' # Blue Text
NC='\033[0m' # No Color

export SECONDS=0

exit_test () {
    exit_code=$?
    set +x
    interrupt=false
    failed=false
    if [ "$exit_code" -eq 0 ]; then
        if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then printf "\n${GREEN}Command Succeeded${NC} : "; fi
        duration_block=$SECONDS
        h=$(printf "%02d" $(($duration_block / 60)))
        m=$(printf "%02d" $(($duration_block % 60)))
        if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then printf "$h:$m elapsed for block.\n"; fi
        failed=false
    else
        failed=true
        if [[ "$LIVE_TERMINAL" == "true" ]]; then
            if [[ -z "$silent" ]] || [[ "$silent" == false ]]; then printf "\n${RED}Failed command in live terminal. ${NC}\n" >&2; fi
        else
            printf "\n${RED}Failed command ...exiting${NC}\n" >&2
        fi
    fi
    if [[ "$failed" == true ]]; then
        if [[ "$SHOWCOMMANDS" == true ]]; then set -x; fi
        if [[ "$LIVE_TERMINAL" != "true" ]]; then exit 1; fi
    fi
    if [[ -z "$allow_interrupt" ]] || [[ "$allow_interrupt" == true ]]; then
        if [[ -d "/deployuser" ]] && [[ -f "/deployuser/interrupt" ]]; then
            printf "\n${RED}Interrrupt file found.  Exiting... ${NC}\n" >&2
            interrupt=true
        fi
        if [[ "$interrupt" == true ]]; then
            if [[ "$SHOWCOMMANDS" == true ]]; then set -x; fi
            if [[ "$LIVE_TERMINAL" != "true" ]]; then exit 1; fi
        fi
    fi
    if [[ "$SHOWCOMMANDS" == true ]]; then set -x; fi # After finishing the script, we enable set -x to show input again.
}