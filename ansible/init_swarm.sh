#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

ansible-playbook -i hosts --private-key ../key.pem -u ubuntu swarm_init.yaml

cd "$OLD_DIR" || exit