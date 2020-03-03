#!/bin/bash
echo "ssh init-firehawk.sh"
echo "hostname $1"
echo "port $2"
echo "tier $3"
# ssh deployuser@$1 -p $2 -i .vagrant/machines/ansiblecontrol/virtualbox/private_key -t "/deployuser/scripts/init-firehawk.sh $3"
ssh deployuser@$1 -p $2 -i ../secrets/keys/ansible_control_private_key -o StrictHostKeyChecking=no -t "/deployuser/scripts/init-firehawk.sh $3"