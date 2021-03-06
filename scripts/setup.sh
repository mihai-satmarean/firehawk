#!/usr/bin/env bash

# this wizard will reuse existing encrypted settings if they exist as environment vars.
# it will regenerate an encrypted settings file based on the secrets.template file.
# if values dont exist, the user will be prompted to initialise a value.
# if values are already defined in the encrypted settings they will be skipped.

export RED='\033[0;31m' # Red Text
export GREEN='\033[0;32m' # Green Text
export BLUE='\033[0;34m' # Blue Text
export NC='\033[0m' # No Color


if [ ! -z $HISTFILE ]; then
    echo "HISTFILE = $HISTFILE"
    print 'HISTFILE is still set, this var should not normally be passed through to the shell please create a ticket alerting us to this issue.  If you wish to continue you can unset HISTFILE and continue.  Exiting.'
    exit
fi

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

# This is the directory of the current script, it should not be relied upon as a global.
export SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
printf "\n...Checking scripts directory at $SCRIPTDIR\n\n"

# These paths and vars are necesary to locating other scripts.
export TF_VAR_firehawk_path=$(to_abs_path "$SCRIPTDIR/../")
echo_if_not_silent "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"

export TEMPDIR="$TF_VAR_firehawk_path/tmp"
mkdir -p "$TEMPDIR"

export configure=

function define_config_settings() {
    clear
    PS3='Configure each of these options without secrets.  If you are running in the VM, configure secrets (To be done from within the Openfirehawk Server Vagrant VM when available): '
    options=("Configure Vagrant" "Configure General Config" "Configure Resources - Grey" "Configure Resources - Blue" "Configure Resources - Green" "Configure Secrets (Only from within Vagrant VM)" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Configure Vagrant")
                export TF_VAR_resourcetier=
                printf "\nThe OpenFirehawk Server is launched with Vagrant.  Some environment variables must be configured uniquely to your environment.\n\n"
                export configure='vagrant'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/vagrant.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/vagrant-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/vagrant)
                break
                ;;
            "Configure General Config")
                export TF_VAR_resourcetier=
                printf "\nSome general Config like IP addresses of your hosts is needed.  Some environment variables here must be configured uniquely to your environment.\n\n"
                export configure='config'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/config.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/config-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config)
                break
                ;;
            "Configure Resources - Grey")
                export TF_VAR_resourcetier='grey'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your dev environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Resources - Blue")
                export TF_VAR_resourcetier='blue'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your production $TF_VAR_resourcetier environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Resources - Green")
                export TF_VAR_resourcetier='green'
                printf "\nThe $TF_VAR_resourcetier resource file uses resources generally unique to your production $TF_VAR_resourcetier environment.\n\n"
                export configure='resources'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/resources-$TF_VAR_resourcetier.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/resources-$TF_VAR_resourcetier-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/resources-$TF_VAR_resourcetier)
                break
                ;;
            "Configure Secrets (Only from within Vagrant VM)")
                export TF_VAR_resourcetier=
                printf "\nThis should only be done within the Ansible Control Vagrant VM. Provisioning infrastructure requires configuration using secrets based on the secrets.template file.  These will be queried for your own unique values and should always be encrypted before you commit them in your private repository.\n\n"
                export configure='secrets'
                export input=$(to_abs_path $TF_VAR_firehawk_path/config/templates/secrets-general.template)
                export output_tmp=$(to_abs_path $TF_VAR_firehawk_path/tmp/secrets-general-tmp)
                export output_complete=$(to_abs_path $TF_VAR_firehawk_path/../secrets/secrets-general)
                break
                ;;
            "Quit")
                echo "You selected $REPLY to $opt"
                configure=
                # echo "Sourcing vars..."
                # source ./update_vars.sh --dev --var-file=$configure --force --save-template=false
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
    if [[ ! -z "$configure" ]]; then
        echo "...Configuring $configure"
        $TF_VAR_firehawk_path/scripts/configure.sh
        write_output
    else
        echo "...Exiting"
        exit
    fi
}

function ensure_encryption() {
    echo "Sourcing vagrant vars for vault key..."
    source ./update_vars.sh --dev --var-file='vagrant' --force --save-template=false # always source vagrant file since it has the vault key
    if [ -f $output_complete ]; then
        echo "Sourcing $configure vars and ensuring encryption if necesary..."
        source ./update_vars.sh --dev --var-file=$configure --force --save-template=false
    fi
}

# trap ctrl-c and call ctrl_c()
trap write_output INT

function write_output() {
    # if [[ -f "$output_complete" ]]; then
    # if an existing config exists, then prompt to overwrite
    printf "\nYour new initialised configuration has been stored at temp path-\n$output_tmp\nTo use this configuration do you wish to overwrite any existing configuration at-\n$output_complete?\n\n"
    PS3="Save and overwrite configuration settings?"
    options=("Yes, save my configuration and continue or exit from main menu" "No / Quit without saving")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes, save my configuration and continue or exit from main menu")
                printf "\Saving config... \n\n"
                mv -fv $output_tmp $output_complete || echo "ERROR: Save failed.  Check permissions."
                ensure_encryption
                define_config_settings
                break
                ;;
            "No / Quit without saving")
                # printf "\nIf you wish to later you can manually move \n$output_tmp \nto \n$output_complete\nto apply the configuration\n\nExiting... \n\n"
                echo "Removing temp file"
                rm -f $output_tmp
                ensure_encryption
                exit
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
    # else
    #     printf '\n...Saving configuration\n'
    #     mv -fv $output_tmp $output_complete || echo "Failed to move temp file.  Check permissions."
    #     define_config_settings
    # fi

}

# function ctrl_c() {
#         printf "\n** CTRL-C ** EXITING...\n"
#         if [[ "$configure" == 'secrets' ]]; then
#             printf "\nWARNING: PARTIALLY COMPLETED INSTALLATIONS MAY LEAVE UNENCRYPTED SECRETS.\n"
#             PS3='Do you want to Encrypt, Remove, or Leave the resulting temp file on disk? '
#             options=("Encrypt And Quit" "Remove And Quit" "Leave And Quit (NOT RECOMMENDED)")
#             select opt in "${options[@]}"
#             do
#                 case $opt in
#                     "Encrypt And Quit")
#                         source ./update_vars.sh --dev --var-file='vagrant' --force --save-template=false
#                         printf "\nEncrypting temp configuration file with key: $vault_key.\n\n"
#                         if [ ! -f $vault_key ]; then
#                             printf "\nFailed: vault key not present.\nThis file should have been created during source ./update_vars.sh --dev --init: $vault_key\n\n"
#                             exit
#                         fi
#                         ansible-vault encrypt --vault-id $vault_key@prompt $output_tmp
#                         exit
#                         ;;
#                     "Remove And Quit")
#                         printf "\nRemoving temp configuration file\n\n"
#                         rm -v $output_tmp || echo "ERROR / WARNING: couldn't remove the temp file, probably due to permissions.  Do this immediately."
#                         exit
#                         ;;
#                     "Leave And Quit (NOT RECOMMENDED)")
#                         echo "You selected $REPLY to $opt"
#                         exit
#                         ;;
#                     *) echo "invalid option $REPLY";;
#                 esac
#             done
#         fi
#         write_output
#         # exit
# }

define_config_settings