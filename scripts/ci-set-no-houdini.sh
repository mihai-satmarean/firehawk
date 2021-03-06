#!/bin/bash

to_abs_path() {
  python -c "import os; print os.path.abspath('$1')"
}

config_override=$(to_abs_path $TF_VAR_firehawk_path/../secrets/config-override-$TF_VAR_envtier) # ...Config Override path $config_override.
echo "config_override path- $config_override"
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'allow_interrupt=' 'true' # destroy before deploy
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_enable_vpc=' 'true' # ...Enable the vpc.
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_softnas_storage=' 'true' # ...On first apply, don't create softnas instance until vpn is working.
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_aws_nodes_enabled=' 'true' # ...Site mounts will not be mounted in cloud.  currently this will disable provisioning any render node or remote workstation until vpn is confirmed to function after this step.

# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_remote_mounts_on_local=' 'true' # ...Softnas nfs exports will not be mounted on local site
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_provision_deadline_spot_plugin=' 'true' # Don't provision the deadline spot plugin for this stage

python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_houdini_license_server_address=' 'none' # remove the ip address
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_install_houdini=' 'false' # install houdini

# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_install_deadline_db=' 'true' # install deadline
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_install_deadline_rcs=' 'true' # install deadline
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_install_deadline_worker=' 'true' # install deadline
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_workstation_enabled=' 'false' # install deadline
# python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_tf_destroy_before_deploy=' 'false' # destroy before deploy
python $TF_VAR_firehawk_path/scripts/replace_value.py -f $config_override 'TF_VAR_taint_single=' '' # taint vpn