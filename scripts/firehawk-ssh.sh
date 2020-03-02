#!/bin/bash
echo "ssh init-firehawk.sh"
echo "hostname $1"
echo "port $2"
echo "tier $3"
# ssh deployuser@$1 -p $2 -i .vagrant/machines/ansiblecontrol/virtualbox/private_key -t "/deployuser/scripts/init-firehawk.sh $3"
ssh deployuser@$1 -p $2 -i /home/gitlab-runner/.vagrant.d/boxes/ansiblecontrol-010.box/0/virtualbox/vagrant_private_key -o StrictHostKeyChecking=no -t "/deployuser/scripts/init-firehawk.sh $3"