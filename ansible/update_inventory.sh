#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

# Get the Bastion DNS name
BASTION_IP=$(cat ./bastion_ip)

# Setup how Ansible is going to use the Bastion to communicate with the nodes
echo "[vms:vars]" > ./hosts
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -i ../key.pem -W %h:%p ubuntu@$BASTION_IP\"'" >> ./hosts

# List all instances, obtain their private IP and add those to the inventory
echo "[vms]" >> ./hosts
gcloud compute instances list --project tpf-concurrent-benchmarks --filter="name~^vm-" --format="value(networkInterfaces[0].networkIP)" >> ./hosts

cd "$OLD_DIR" || exit