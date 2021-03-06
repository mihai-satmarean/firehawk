#!/usr/bin/env bash

# This script is a first stage install that takes a password and uses it to handle encryption in future stages
# echo "Enter Secrets Decryption Password..."
unset HISTFILE

SECONDS=0

printf "\nRunning env $1...\n"

set +x # don't echo bash commands
# # This block allows you to echo a line number for a failure.
set -eE -o functrace

err_report() { # This funciton may not port to mac os.
  local lineno=$1
  local msg=$2
  echo "$0 script Failed at $lineno: $msg"
}
trap 'err_report ${LINENO} "$BASH_COMMAND"' ERR

# Abort script with correct exit code instead of continuing if non zero exit code occurs.
set -e

if [ -z "$CI_COMMIT_REF_SLUG" ]; then echo "Launching in a non Gitlab CI environment"; export env_ci=false; else echo "Gitlab CI Environment with branch: $CI_COMMIT_REF_SLUG"; export env_ci=true; fi

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

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
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

vagrant_up=true
test_vm=false
tf_action="apply"
tf_init=true
init_vm_config=true
vagrant_halt=false
fast=false
set_softnas_volatile=false
force_plugin_install=false

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
                    sleep)
                        tf_action='sleep'
                        ;;
                    destroy)
                        tf_action='destroy'
                        echo "...will destroy"
                        ;;
                    vagrant-up)
                        vagrant_up="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "vagrant_up set $vagrant_up"
                        ;;
                    vagrant-up=*)
                        vagrant_up=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "vagrant_up set $vagrant_up"
                        ;;
                    vagrant-halt)
                        vagrant_halt="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "vagrant_halt set $vagrant_halt"
                        ;;
                    vagrant-halt=*)
                        vagrant_halt=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "vagrant_halt set $vagrant_halt"
                        ;;
                    tf-action)
                        tf_action="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "tf_action set: $tf_action"
                        ;;
                    tf-action=*)
                        tf_action=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "tf_action set: $tf_action"
                        ;;
                    tf-init)
                        tf_init="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "tf_init set: $tf_init"
                        ;;
                    tf-init=*)
                        tf_init=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "tf_init set: $tf_init"
                        ;;
                    init-vm-config)
                        init_vm_config="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "init_vm_config set: $init_vm_config"
                        ;;
                    init-vm-config=*)
                        init_vm_config=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "init_vm_config set: $init_vm_config"
                        ;;
                    softnas-destroy-volumes)
                        set_softnas_volatile="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "set_softnas_volatile set: $set_softnas_volatile"
                        ;;
                    softnas-destroy-volumes=*)
                        set_softnas_volatile=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "set_softnas_volatile set: $set_softnas_volatile"
                        ;;
                    force-plugin-install)
                        force_plugin_install="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "force_plugin_install set: $force_plugin_install"
                        ;;
                    force-plugin-install=*)
                        force_plugin_install=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "force_plugin_install set: $force_plugin_install"
                        ;;
                    fast)
                        fast="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        opt="${OPTARG}"
                        echo "fast set: $fast"
                        ;;
                    fast=*)
                        fast=${OPTARG#*=}
                        opt=${OPTARG%=$val}
                        echo "fast: $fast"
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

echo "opts $@"

if [[ "$fast" == true ]]; then
    echo "Fast start.  Disable init_vm_config"
    init_vm_config=false
fi


# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
. $SCRIPTDIR/scripts/exit_test.sh

# If not buildinging a package (.box file) and we specify a box file, then it must be the basis to start from
# else if we are building a package, it will be a post process .

time_passed () {
    duration_block=$SECONDS; printf "$(($duration_block / 60)) minutes $(($duration_block % 60)) seconds elapsed for firehawk.sh.\n"
}
time_passed

echo "Check vagrant plugins."
if [[ "$force_plugin_install" == true ]]; then # Install Vagrant Plugins
    vagrant plugin install vagrant-vbguest
    vagrant plugin install vagrant-disksize
    vagrant plugin install vagrant-reload
    vagrant plugin install vagrant-vbguest
fi

if [[ "$TF_VAR_fast" == true ]]; then # Install Vagrant Plugins
    echo "...Fast mode.  Bypassing plugin evaluation"
else
    vagrant_plugin_list="$(vagrant plugin list)"
    echo "vagrant_plugin_list: $vagrant_plugin_list"
    if echo "$vagrant_plugin_list" | grep 'vagrant-disksize' -q; then echo 'plugin vagrant-disksize installed'; else echo '...installing'; vagrant plugin install vagrant-disksize; fi
    if echo "$vagrant_plugin_list" | grep 'vagrant-reload' -q; then echo 'plugin vagrant-reload installed'; else echo '...installing'; vagrant plugin install vagrant-reload; fi
    if echo "$vagrant_plugin_list" | grep 'vagrant-vbguest' -q; then echo 'plugin vagrant-vbguest installed'; else echo '...installing'; vagrant plugin install vagrant-vbguest; fi
fi

# If box file in is defined, then vagrant will use this file in place of the standard image.
if [[ ! -z "$box_file_in" ]] ; then
    echo "...Source env vars with box file."
    source ./update_vars.sh --$TF_VAR_envtier --box-file-in "$box_file_in" --init
else
    echo "...Source env vars: source ./update_vars.sh --$TF_VAR_envtier --init"
    source ./update_vars.sh --$TF_VAR_envtier --init
fi
echo "...Finished sourcing"

if [[ "$test_vm" = false ]] ; then # If an encrypted var is provided for the vault key, test decrypt that var before proceeding
    if [[ ! -z "$firehawksecret" ]]; then
        # To manually enter an ecnrypted variable in you configuration use:
        # firehawksecret=$(echo -n "test some input that will be encrypted and stored as an env var" | ansible-vault encrypt_string --vault-id $vault_key --stdin-name firehawksecret | base64 -w 0)
        # That encrypted variable can be extracted here if specified in your environment prior to running this script.
        echo "Aquire firehawksecret..."
        password=$(./scripts/ansible-encrypt.sh --vault-id $vault_key --decrypt $firehawksecret)
        if [[ -z "$password" ]]; then
            echo "ERROR: unable to extract password from defined firehawksecret.  Either remove the firehawksecret variable, or debugging will be required for automation to continue."
            exit 1
        fi
    else
        firehawksecret='' # Set secret to an empty string if not defined.
    fi
fi

time_passed


echo "Vagrant box ansiblecontrol$TF_VAR_envtier in $ansiblecontrol_box"
echo "Vagrant box firehawkgateway$TF_VAR_envtier in $firehawkgateway_box"

if [[ "$vagrant_halt" == true ]]; then
    echo "Halting vagrant"
    echo "Warning: Doing this deadlinedb while running (firehawkgateway) may corrupt it."
    vagrant halt
fi


printf "\nvagrant_up: $vagrant_up\n"
if [[ "$vagrant_up" == true ]]; then
    echo "vagrant status:"
    vagrant_status="$(vagrant status)"
    echo "$vagrant_status"
    echo "$vagrant_status" | grep -o 'running (virtualbox)' | wc -l
    total_running_machines=$(echo "$vagrant_status" | grep -o 'running (virtualbox)' | wc -l)

    echo "total_running_machines $total_running_machines"
    # total_running_machines=$(grep -cim1 'running' $vagrant_status)
    if [ $total_running_machines -ge 2 ]; then
        echo "...Both machines are already up."
    else
        echo "...Will start machines"
        sleep 3
        if [[ "$init_vm_config" == true ]]; then
            echo "...Starting vagrant, and provisioning."
            # vagrant up --provision | ts '[%H:%M:%S]'
            echo "pwd $(pwd)"
            $TF_VAR_firehawk_path/vagrant_provision.sh | ts '[%H:%M:%S]'
        else
            echo "...Starting vagrant"
            vagrant up | ts '[%H:%M:%S]'
        fi
    fi
fi
#; exit_test # ssh reset may cause a non zero exit code, but it must be ignored

time_passed

if [ "$test_vm" = false ] ; then
    # sleep 10
    # echo "vagrant status:"
    # vagrant status
    # sleep 10
    echo "Vagrant SSH config:"
    n=0; retries=100
    until [ $n -ge $retries ]
    do
    vagrant ssh-config && break  # substitute your command here
    n=$[$n+1]
    sleep 15
    done
    if [ $n -ge $retries ]; then
        echo "Error: timed out waiting for vagrant ssh config command - failed."
        exit 1
    fi
    echo "...Get vagrant key file"
    # AFter Vagrant Hosts are up, take the SSH keys and store them in the keys folder for general use.
    ansiblecontrol_config=$(vagrant ssh-config ansiblecontrol$TF_VAR_envtier)
    firehawkgateway_config=$(vagrant ssh-config firehawkgateway$TF_VAR_envtier)
    ansiblecontrol_key=$(echo "$ansiblecontrol_config" | awk '{if($1=="IdentityFile") print $2}')
    cp -f $ansiblecontrol_key $TF_VAR_secrets_path/keys/ansible_control_private_key
    firehawkgateway_key=$(echo "$firehawkgateway_config" | awk '{if($1=="IdentityFile") print $2}')
    cp -f $firehawkgateway_key $TF_VAR_secrets_path/keys/firehawkgateway_private_key
    
    hostname="$(echo "$ansiblecontrol_config" | awk '{if($1=="HostName") print $2}')"
    port="$(echo "$ansiblecontrol_config" | awk '{if($1=="Port") print $2}')"
    
    echo "SSH to vagrant host with..."
    echo "Hostname: $hostname"
    echo "Port: $port"
    echo "tier --$TF_VAR_envtier"

    time_passed

    if [[ ! -z "$hostname" && ! -z "$port" && ! -z "$TF_VAR_envtier" ]]; then
        echo "init_vm_config: $init_vm_config"
        set -o pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
        # set -o pipefail # Allow exit status of last command to fail to catch errors after pipe for ts function.
        ssh-keygen -R [$hostname]:$port -f ~/.ssh/known_hosts # clean host keys
        if [[ "$tf_action" == "sleep" ]]; then
            echo "...Logging in to Vagrant host to set sleep on tf deployment: $hostname"
            if [[ "$env_ci" == true ]]; then
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --sleep --init-vm-config=false --softnas-destroy-volumes=$set_softnas_volatile" | ts '[%H:%M:%S]'; exit_test
            else
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --sleep --init-vm-config=false --softnas-destroy-volumes=$set_softnas_volatile"; exit_test
            fi
            echo "...End Deployment"
        elif [[ "$tf_action" == "destroy" ]]; then
            echo "...Logging in to Vagrant host to destroy tf deployment: $hostname"
            if [[ "$env_ci" == true ]]; then
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --destroy --init-vm-config=$init_vm_config --tf-init=$tf_init --softnas-destroy-volumes=$set_softnas_volatile" | ts '[%H:%M:%S]'; exit_test
            else
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --destroy --init-vm-config=$init_vm_config --tf-init=$tf_init --softnas-destroy-volumes=$set_softnas_volatile"; exit_test
            fi
            echo "...End Deployment"
        elif [[ "$tf_action" == "single_test" ]]; then
            echo "...Logging in to Vagrant host to run single test: $hostname "
            ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --init-vm-config=$init_vm_config --tf-action=$tf_action --tf-init=$tf_init --softnas-destroy-volumes=$set_softnas_volatile" | ts '[%H:%M:%S]'; exit_test
            echo "...End Deployment"        
        else
            echo "...Logging in to Vagrant host: $hostname "
            if [[ "$env_ci" == true ]]; then
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --init-vm-config=$init_vm_config --tf-action=$tf_action --tf-init=$tf_init --softnas-destroy-volumes=$set_softnas_volatile" | ts '[%H:%M:%S]'; exit_test
            else
                ssh deployuser@$hostname -p $port -i $TF_VAR_secrets_path/keys/ansible_control_private_key -o StrictHostKeyChecking=no -tt "export firehawksecret=${firehawksecret}; /deployuser/scripts/init-firehawk.sh --$TF_VAR_envtier --init-vm-config=$init_vm_config --tf-action=$tf_action --tf-init=$tf_init --softnas-destroy-volumes=$set_softnas_volatile"; exit_test
            fi
            echo "...End Deployment"
        fi
    fi
fi

if [[ ! -z "$box_file_out" ]]; then
    # If a box_file_out is defined, then we package the images for each box out to files.  The vm will be stopped to eprform this step.
    echo "Set Vagrant box out $ansiblecontrol_box_out"
    echo "Set Vagrant box out $firehawkgateway_box_out"
    [ ! -e $ansiblecontrol_box_out ] || rm $ansiblecontrol_box_out
    [ ! -e $firehawkgateway_box_out ] || rm $firehawkgateway_box_out
    vagrant package "ansiblecontrol$TF_VAR_envtier" --output $ansiblecontrol_box_out &
    vagrant package "firehawkgateway$TF_VAR_envtier" --output $firehawkgateway_box_out
fi