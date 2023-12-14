#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

# Upload docker images to the VMs
# This only uploads images that cannot be pulled from Docker Hub
ansible-playbook -i hosts --private-key ../key.pem -u ubuntu upload_images.yaml

cd "$OLD_DIR" || exit