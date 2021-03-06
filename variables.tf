variable "sleep" {
  default = false
}

variable "enable_vpc" {
}

variable "vpc_cidr" {
}

#you can get an ssl certificate arn by verifying your domain with aws certificate manager.
variable "cert_arn" {
}

variable "aws_region" {
}

variable "softnas_skip_update" {
}

variable "softnas_instance_type" {
  default = "m4.xlarge"
}


variable "azs" {
  default = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "node_centos_volume_size" {
  default = 20
}

variable "node_centos_volume_type" {
  default = "gp2"
}

# once you setup an ssl certificate with your domain, it will have a route zone id.
variable "route_zone_id" {
}

variable "firehawk_path" {}

variable "public_domain" {
}

variable "openfirehawkserver" {
}

variable "route_public_domain_name" {
}

variable "openvpn_user" {
}

variable "aws_nodes_enabled" {
  default = true
}

variable "openvpn_user_pw" {
}

variable "openvpn_admin_user" {
}

variable "openvpn_admin_pw" {
}

#generate a keypair and enter its name here.
variable "aws_key_name" {
}

#the path to the key stored locally where terraform is run.
variable "aws_private_key_path" {
}

variable "pgp_key_path" {
}

#the remote_ip_cidr is the public remote static ip address of the site that will access the vpc
#see this page for more undewrstanding on ip ranges reserved for this purpose
#https://openvpn.net/community-resources/how-to/
variable "remote_ip_cidr" {
}

#the vpn cidr is the range the client will assign addresses to remote hosts with dhcp in this cidr block.
variable "vpn_cidr" {
}

#the remote subnet cidr block is the subnet range that your remote site is in.  use this if you intend to use the openvpn client
#as a router / gateway for other nodes on your remote network to access the EC2 private subnet.
variable "remote_subnet_cidr" {
}

variable "node_wakeable" {
  default = false
}

variable "softnas_ssh_user" {
}

variable "softnas1_cloudformation_role_name" {
  default = "FCB-Softnas1Role"
}

variable "softnas2_cloudformation_role_name" {
  default = "FCB-Softnas2Role"
}

variable "envtier" {
}

variable "remote_mounts_on_local" {
}

variable "softnas_storage" {
  default = true
}

variable "softnas1_private_ip1" {
}

variable "softnas_mailserver" {
}

variable "softnas_smtp_port" {
}

variable "softnas_smtp_username" {
}

variable "softnas_smtp_password" {
}

variable "softnas_smtp_from" {
}

variable "smtp_encryption" {
}

variable "deadline_proxy_root_dir" {
}

variable "houdini_license_server_address" {
}

variable "workstation_enabled" {
}

variable "node_centos_instance_type" {
}

variable "pgp_public_key" {
}

variable "provision_deadline_spot_plugin" {
}

variable "install_deadline_db" {}

variable "install_deadline_worker" {}

variable "install_deadline_rcs" {}

variable "install_houdini" {}

variable "softnas_volatile" {}