#!/bin/bash
OLD_DIR="$(pwd)"
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR" || exit

gcloud compute instances list --project="tpf-concurrent-benchmarks" --filter="name~bastion" --format="value(networkInterfaces[0].accessConfigs[0].natIP)" > bastion_ip

cd "$OLD_DIR" || exit