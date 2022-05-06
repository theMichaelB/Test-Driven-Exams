variable "ansible_resource_group_name" {
  default     = "TDE-Ansible"
  description = "Resource Group Name for the ansible server deployment"
}
variable "network_resource_group_name" {
  default     = "TDE-Core-Network"
  description = "Resource Group Name for the network deployment"
}
variable "kubernetes_resource_group_name" {
  default     = "TDE-Core-Kubernetes"
  description = "Resource Group Name for the kubernetes deployment"
}

variable "resource_group_location" {
  default     = "ukwest"
  description = "Location of the resource group."
}
variable "network_name" {
  default     = "TDE-Core-network"
  description = "Core network name"
}


variable "ansible_ssh_username" {
}

variable "ansible_ssh_public_key" {

}
variable "kubernetes_ssh_username" {
}

variable "kubernetes_ssh_public_key" {

}

variable "key_vault_sshkey_id" {

}

variable "key_vault_id" {

}
variable "dns_zone_name" {

}

variable "dns_zone_resource_group" {}
