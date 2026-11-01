#!/usr/bin/env bash
set -Eeuo pipefail

SCYLLA_CONTAINER_PREFIX=${SCYLLA_CONTAINER_PREFIX:-scylla-node}
SCYLLA_NODE_COUNT=${SCYLLA_NODE_COUNT:-3}
SCYLLA_NETWORK=${SCYLLA_NETWORK:-scylla-net}
SCYLLA_MANAGER_DB_NAME=${SCYLLA_MANAGER_DB_NAME:-scylla-manager-db}
SCYLLA_MANAGER_NAME=${SCYLLA_MANAGER_NAME:-scylla-manager}

log() {
  printf '[scylla-cleanup] %s\n' "$*"
}

command -v docker >/dev/null 2>&1 || {
  printf '[scylla-cleanup] ERROR: Required command not found: docker\n' >&2
  exit 1
}
[[ "$SCYLLA_NODE_COUNT" =~ ^[1-9][0-9]*$ ]] || {
  printf '[scylla-cleanup] ERROR: SCYLLA_NODE_COUNT must be a positive integer\n' >&2
  exit 1
}

container_names=("$SCYLLA_MANAGER_NAME" "$SCYLLA_MANAGER_DB_NAME")
for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
  container_names+=("${SCYLLA_CONTAINER_PREFIX}-${index}")
done

for name in "${container_names[@]}"; do
  if docker container inspect "$name" >/dev/null 2>&1; then
    log "Removing container $name"
    docker rm --force "$name" >/dev/null
  fi
done

for volume in \
  "scylla-node-1-data" \
  "scylla-node-2-data" \
  "scylla-node-3-data" \
  "scylla-manager-db-data"; do
  if docker volume inspect "$volume" >/dev/null 2>&1; then
    log "Removing volume $volume"
    docker volume rm "$volume" >/dev/null
  fi
done

if docker network inspect "$SCYLLA_NETWORK" >/dev/null 2>&1; then
  log "Removing network $SCYLLA_NETWORK"
  docker network rm "$SCYLLA_NETWORK" >/dev/null ||
    log "Could not remove network '$SCYLLA_NETWORK'; check for other attached containers"
fi
log "Cleanup complete"
