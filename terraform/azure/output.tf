output "ansible_rg_id" {
  value = azurerm_resource_group.ansible.id
}

output "network_rg_id" {
  value = azurerm_resource_group.network.id
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "subnet_id" {
    value = module.vnet.vnet_subnets
}




output "Ansible_IP" {
    value = azurerm_public_ip.ansible-pip.ip_address
}