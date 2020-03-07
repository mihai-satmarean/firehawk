#!/bin/bash
echo "ssh init-firehawk.sh"
echo "hostname $1"
echo "port $2"
echo "tier $3"

# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at: $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
echo "TF_VAR_firehawk_path: $TF_VAR_firehawk_path"
echo "TF_VAR_secrets_path: $TF_VAR_secrets_path"
ls $TF_VAR_firehawk_path/scripts

. $TF_VAR_firehawk_path/scripts/exit_test.sh

echo "firehawksecret=$firehawksecret"
# test pass through var firehawksecret=$firehawksecret
ssh deployuser@$1 -p $2 -i ../secrets/keys/ansible_control_private_key -o StrictHostKeyChecking=no -t "export firehawksecret=$firehawksecret; /deployuser/scripts/init-firehawk.sh $3"; exit_test