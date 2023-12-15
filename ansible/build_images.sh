#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

ansible-playbook -i hosts --private-key ../key.pem -u ubuntu\
 -e "src_dir=\"$1\" build_command=\"$2\""\
 build_images.yaml

cd "$OLD_DIR" || exit