#!/usr/bin/env bash

set -euxo pipefail

source="$(git rev-parse --show-toplevel)"

cat <<EOF > "${source}/.env"
UID=$(id -u)
GID=$(id -g)
SOURCE_DIRECTORY=$source
COMPOSE_PROFILES=local
EOF

cat <<EOF > environment.local.sh
source environment.sh
EOF

ln -s environment.local.sh .envrc
