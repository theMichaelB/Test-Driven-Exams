
resource "azurerm_resource_group" "ansible" {
  name     = var.ansible_resource_group_name
  location = var.resource_group_location
}

resource "azurerm_resource_group" "network" {
  name     = var.network_resource_group_name
  location = var.resource_group_location
}

resource "azurerm_resource_group" "kubernetes" {
  name     = var.kubernetes_resource_group_name
  location = var.resource_group_location
}


module "vnet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = var.network_name
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["192.168.0.0/16"]
  subnet_prefixes     = ["192.168.0.0/24", "192.168.1.0/24"]
  subnet_names        = ["ansible", "kubernetes"]

  nsg_ids = {
    ansible    = azurerm_network_security_group.ssh.id
    kubernetes = azurerm_network_security_group.kubernetes.id
  }

  depends_on = [azurerm_resource_group.network]
  tags = {
    environment = "PoC"
    purpose     = "ansible"
  }
}

resource "azurerm_network_security_group" "ssh" {
  name                = "ssh"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location

  security_rule {
    name                       = "Outside_Allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "Kubernetes_Deny"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "192.168.1.0/24"
    destination_address_prefix = "*"
  }


}

resource "azurerm_network_security_group" "kubernetes" {
  name                = "kubernetes"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP-Kube"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS-Kube"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}


resource "azurerm_network_interface" "ansible-nic" {
  name                = "ansible-nic"
  location            = azurerm_resource_group.ansible.location
  resource_group_name = azurerm_resource_group.ansible.name
  tags = {
    environment = "dev"
    costcenter  = "it"
  }
  ip_configuration {
    name                          = "internal"
    public_ip_address_id          = azurerm_public_ip.ansible-pip.id
    subnet_id                     = module.vnet.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "ansible-pip" {
  name                = "ansible-pip"
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location
  allocation_method   = "Static"

}

resource "azurerm_user_assigned_identity" "ansible_identity" {
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location
  name                = "ansible-identity"
}
resource "azurerm_role_assignment" "ansible_identity" {
  scope                = azurerm_resource_group.kubernetes.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.ansible_identity.principal_id
}


data "azurerm_key_vault_secret" "sshkey1" {
  name         = var.key_vault_sshkey_id
  key_vault_id = var.key_vault_id
}

data "template_file" "init" {
  template = file("ansible/cloud-init-ansible.yaml")
  vars = {
    ssh_key     = data.azurerm_key_vault_secret.sshkey1.value
    kubeworker  = base64gzip(file("ansible/group_vars/kubeworker.yml"))
    kubemaster  = base64gzip(file("ansible/group_vars/kubemaster.yml"))
    kubedeploy  = base64gzip(file("ansible/kubedeploy.yml"))
    azure_rm    = base64gzip(file("ansible/azure_rm.yml"))
    ansible_cfg = base64gzip(file("ansible/ansible.cfg"))
  }
}


data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init.rendered
  }

}

resource "azurerm_linux_virtual_machine" "ansible" {
  name                = "ansible"
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location
  size                = "Standard_B2s"
  admin_username      = "ubuntu"
  user_data           = sensitive(data.template_cloudinit_config.config.rendered)
  network_interface_ids = [
    azurerm_network_interface.ansible-nic.id,
  ]

  admin_ssh_key {
    username   = var.ansible_ssh_username
    public_key = var.ansible_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ansible_identity.id]
  }

}


resource "azurerm_public_ip" "kubernetes" {
  name                = "kubernetes-pip"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "PoC"
    purpose     = "kubernetes"

  }
}

resource "azurerm_lb" "kubernetes" {
  name                = "kubernetes-lb"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.kubernetes.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.kubernetes.id
  name            = "BackEndAddressPool"
}


resource "azurerm_lb_probe" "kubernetes" {
  loadbalancer_id = azurerm_lb.kubernetes.id
  name            = "http-probe"
  protocol        = "Http"
  request_path    = "/"
  port            = 30080
}

resource "azurerm_lb_rule" "http-rule-https" {
  loadbalancer_id                = azurerm_lb.kubernetes.id
  name                           = "LBRule-https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 30443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  probe_id                       = azurerm_lb_probe.kubernetes-https.id
}


resource "azurerm_lb_probe" "kubernetes-https" {
  loadbalancer_id = azurerm_lb.kubernetes.id
  name            = "https-probe"
  protocol        = "Https"
  request_path    = "/"
  port            = 30443
}

resource "azurerm_lb_rule" "http-rule" {
  loadbalancer_id                = azurerm_lb.kubernetes.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 30080
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  probe_id                       = azurerm_lb_probe.kubernetes.id
}


resource "azurerm_linux_virtual_machine_scale_set" "kubernetes" {
  name                = "kubernetes-vmss"
  resource_group_name = azurerm_resource_group.kubernetes.name
  location            = azurerm_resource_group.kubernetes.location
  sku                 = "Standard_B2s"
  instances           = 3
  admin_username      = "ubuntu"
  overprovision       = false
  tags = {
    environment = "PoC"
    purpose     = "kubernetes"

  }
  admin_ssh_key {
    username   = var.kubernetes_ssh_username
    public_key = var.kubernetes_ssh_public_key
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "kubernetes-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = module.vnet.vnet_subnets[1]
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }
}


resource "azurerm_dns_a_record" "Ansible" {
  name                = "ansible"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 60
  records             = [azurerm_public_ip.ansible-pip.ip_address]
  depends_on = [azurerm_linux_virtual_machine.ansible]
}

resource "azurerm_dns_a_record" "kubernetes" {
  name                = "lb"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 60
  records             = [azurerm_public_ip.kubernetes.ip_address]
  depends_on = [azurerm_linux_virtual_machine_scale_set.kubernetes]
}