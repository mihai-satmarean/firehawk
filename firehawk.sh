#!/bin/bash
# This script is a first stage install that takes a password and uses it to handle encryption in future stages
# echo "Enter Secrets Decryption Password..."
unset HISTFILE

printf "\nRunning ansiblecontrol with $1...\n"

tier () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing tier option: '--${opt}', value: '${val}'" >&2;
    fi
    export TF_VAR_envtier=$val
}

box_file_in=
box_file_in () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing box_file_in option: '--${opt}', value: '${val}'" >&2;
    fi
    export box_file_in="${val}"
}

box_file_out=
box_file_out () {
    if [[ "$verbose" == true ]]; then
        echo "Parsing box_file_out option: '--${opt}', value: '${val}'" >&2;
    fi
    export box_file_out="${val}"
    export ansiblecontrol_box_out="ansiblecontrol-${val}.box"
    export firehawkgateway_box_out="firehawkgateway-${val}.box"
}


function to_abs_path {
    local target="$1"
    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}

function help {
    echo "usage: ./firehawk.sh [--dev/prod] [--box-file-in[=]010] [--box-file-out[=]010] [--test-vm]" >&2
    printf "\nUse this to start all infrastructure, optionally creating VM's for testing stages.\n" &&
    failed=true
}

# IFS must allow us to iterate over lines instead of words seperated by ' '
IFS='
'
optspec=":hv-:t:"

test_vm=false

parse_opts () {
    local OPTIND
    OPTIND=0
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    box-file-in)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        box_file_in
                        ;;
                    box-file-in=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        box_file_in
                        ;;
                    box-file-out)
                        val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        box_file_out
                        ;;
                    box-file-out=*)
                        val=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        box_file_out
                        ;;
                    dev)
                        val="dev";
                        opt="${OPTARG}"
                        tier
                        ;;
                    prod)
                        val="prod";
                        opt="${OPTARG}"
                        tier
                        ;;
                    test-vm)
                        test_vm=true
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                        ;;
                esac;;
            h)
                help
                ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                    echo "Non-option argument: '-${OPTARG}'" >&2
                fi
                ;;
        esac
    done
}
parse_opts "$@"

# if not buildinging a package (.box file) and we specify a box file, then it must be the basis to start from
# else if we are building a package, it will be a post process .

if [[ "$test_vm" = false ]] ; then
    echo -n Password:
    read -s password
fi

# if box file in is defined, then vagrant will use this file in place of the standard image.
if [[ ! -z "$box_file_in" ]] ; then
    source ./update_vars.sh --$TF_VAR_envtier --box-file-in "$box_file_in" --vagrant
else
    source ./update_vars.sh --$TF_VAR_envtier --vagrant
fi

echo "Vagrant box in $ansiblecontrol_box"
echo "Vagrant box in $firehawkgateway_box"
vagrant up

if [[ ! -z "$box_file_out" ]] ; then
    # if a box_file_out is defined, then we package the images for each box out to files.
    echo "Set Vagrant box out $ansiblecontrol_box_out"
    echo "Set Vagrant box out $firehawkgateway_box_out"
    [ ! -e $ansiblecontrol_box_out ] || rm $ansiblecontrol_box_out
    [ ! -e $firehawkgateway_box_out ] || rm $firehawkgateway_box_out
    vagrant package ansiblecontrol --output $ansiblecontrol_box_out &
    vagrant package firehawkgateway --output $firehawkgateway_box_out
fi

if [ "$test_vm" = false ] ; then
    hostname=$(vagrant ssh-config ansiblecontrol | grep -Po '.*HostName\ \K(\d*.\d*.\d*.\d*)')
    port=$(vagrant ssh-config ansiblecontrol | grep -Po '.*Port\ \K(\d*)')

    use expect to pipe through the password aquired initially.
    ./scripts/expect-firehawk.sh $hostname $port $1 $password
fi