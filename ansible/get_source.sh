#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

ansible-playbook -i hosts --private-key ../key.pem -u ubuntu\
  -e "repo=$1 repo_dest=$2 branch=$3"\
  get_source.yaml

cd "$OLD_DIR" || exit