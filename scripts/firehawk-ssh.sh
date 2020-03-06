#!/bin/bash
echo "ssh init-firehawk.sh"
echo "hostname $1"
echo "port $2"
echo "tier $3"

# This is the directory of the current script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTDIR=$(to_abs_path $SCRIPTDIR)
printf "\n...checking scripts directory at $SCRIPTDIR\n\n"
# source an exit test to bail if non zero exit code is produced.
. $SCRIPTDIR/exit_test.sh

# ssh deployuser@$1 -p $2 -i .vagrant/machines/ansiblecontrol/virtualbox/private_key -t "/deployuser/scripts/init-firehawk.sh $3"
ssh deployuser@$1 -p $2 -i ../secrets/keys/ansible_control_private_key -o StrictHostKeyChecking=no -t "/deployuser/scripts/init-firehawk.sh $3"; exit_test.sh