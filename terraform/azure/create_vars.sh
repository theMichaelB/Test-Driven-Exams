#!/bin/bash

cat > terraform/azure/terraform.tfvars << EOF
ansible_ssh_username   = "ubuntu"
ansible_ssh_public_key = "${ANSIBLE_SSH_PUBLIC_KEY}"
key_vault_sshkey_id    = "${KEY_VAULT_SSHKEY_ID}"
key_vault_id           = "${KEY_VAULT_ID}"

kubernetes_ssh_public_key = "${KUBERNETES_SSH_PUBLIC_KEY}"
kubernetes_ssh_username   = "ubuntu"
dns_zone_name = ${DNS_ZONE_NAME}
dns_zone_resource_group = ${DNS_ZONE_RESOURCE_GROUP}
EOF

