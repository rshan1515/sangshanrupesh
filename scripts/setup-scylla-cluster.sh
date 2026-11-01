#!/usr/bin/env bash
set -Eeuo pipefail

SCYLLA_CONTAINER_PREFIX=${SCYLLA_CONTAINER_PREFIX:-scylla-node}
SCYLLA_NETWORK=${SCYLLA_NETWORK:-scylla-net}
SCYLLA_NODE_COUNT=${SCYLLA_NODE_COUNT:-3}
SCYLLA_IMAGE=${SCYLLA_IMAGE:-scylladb/scylla:latest}
SCYLLA_SMP=${SCYLLA_SMP:-1}
SCYLLA_MEMORY=${SCYLLA_MEMORY:-750M}
SCYLLA_MANAGER_DB_NAME=${SCYLLA_MANAGER_DB_NAME:-scylla-manager-db}
SCYLLA_MANAGER_NAME=${SCYLLA_MANAGER_NAME:-scylla-manager}
SCYLLA_MANAGER_IMAGE=${SCYLLA_MANAGER_IMAGE:-scylladb/scylla-manager:latest}
SCYLLA_CLUSTER_NAME=${SCYLLA_CLUSTER_NAME:-my-cluster}
SCYLLA_STARTUP_TIMEOUT=${SCYLLA_STARTUP_TIMEOUT:-600}
SCYLLA_POLL_INTERVAL=${SCYLLA_POLL_INTERVAL:-10}

log() {
  printf '[scylla-setup] %s\n' "$*"
}

fail() {
  printf '[scylla-setup] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

is_positive_integer "$SCYLLA_NODE_COUNT" || fail "SCYLLA_NODE_COUNT must be a positive integer"
is_positive_integer "$SCYLLA_STARTUP_TIMEOUT" || fail "SCYLLA_STARTUP_TIMEOUT must be a positive integer"
is_positive_integer "$SCYLLA_POLL_INTERVAL" || fail "SCYLLA_POLL_INTERVAL must be a positive integer"
[[ "$SCYLLA_CLUSTER_NAME" =~ ^[A-Za-z0-9._-]+$ ]] ||
  fail "SCYLLA_CLUSTER_NAME may contain only letters, numbers, dots, underscores, and hyphens"

require_command docker

container_exists() {
  docker container inspect "$1" >/dev/null 2>&1
}

container_ip() {
  docker inspect --format="{{with index .NetworkSettings.Networks \"$SCYLLA_NETWORK\"}}{{.IPAddress}}{{end}}" "$1"
}

ensure_container_name_available() {
  local name=$1
  if container_exists "$name"; then
    fail "Container '$name' already exists. Run scripts/cleanup-scylla.sh first."
  fi
}

if ! docker network inspect "$SCYLLA_NETWORK" >/dev/null 2>&1; then
  log "Creating Docker network '$SCYLLA_NETWORK'"
  docker network create "$SCYLLA_NETWORK" >/dev/null
fi

for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
  ensure_container_name_available "${SCYLLA_CONTAINER_PREFIX}-${index}"
done
ensure_container_name_available "$SCYLLA_MANAGER_DB_NAME"
ensure_container_name_available "$SCYLLA_MANAGER_NAME"

seed_name="${SCYLLA_CONTAINER_PREFIX}-1"
log "Starting $SCYLLA_NODE_COUNT Scylla node(s) using $SCYLLA_IMAGE"
for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
  node_name="${SCYLLA_CONTAINER_PREFIX}-${index}"
  args=(--smp "$SCYLLA_SMP" --memory "$SCYLLA_MEMORY" --overprovisioned 1 --api-address 0.0.0.0)
  if (( index > 1 )); then
    seed_ip=$(container_ip "$seed_name")
    [[ -n "$seed_ip" ]] || fail "Could not determine the seed node IP address"
    args+=(--seeds "$seed_ip")
  fi
  log "Starting $node_name"
  docker run --detach --name "$node_name" --network "$SCYLLA_NETWORK" \
    --restart unless-stopped "$SCYLLA_IMAGE" "${args[@]}" >/dev/null
done

log "Waiting for all nodes to report UN in nodetool status"
deadline=$((SECONDS + SCYLLA_STARTUP_TIMEOUT))
while (( SECONDS < deadline )); do
  status=$(docker exec "$seed_name" nodetool status 2>/dev/null || true)
  healthy_count=$(awk '$1 == "UN" { count++ } END { print count+0 }' <<<"$status")
  if (( healthy_count == SCYLLA_NODE_COUNT )); then
    printf '%s\n' "$status"
    break
  fi
  sleep "$SCYLLA_POLL_INTERVAL"
done
(( healthy_count == SCYLLA_NODE_COUNT )) || fail "Timed out waiting for $SCYLLA_NODE_COUNT healthy nodes"

log "Starting Scylla Manager database and Manager"
docker run --detach --name "$SCYLLA_MANAGER_DB_NAME" --network "$SCYLLA_NETWORK" \
  --restart unless-stopped "$SCYLLA_IMAGE" \
  --smp "$SCYLLA_SMP" --memory "$SCYLLA_MEMORY" --overprovisioned 1 >/dev/null
docker run --detach --name "$SCYLLA_MANAGER_NAME" --network "$SCYLLA_NETWORK" \
  --link "$SCYLLA_MANAGER_DB_NAME" --restart unless-stopped "$SCYLLA_MANAGER_IMAGE" >/dev/null

log "Waiting for Scylla Manager to become available"
deadline=$((SECONDS + SCYLLA_STARTUP_TIMEOUT))
manager_ready=false
while (( SECONDS < deadline )); do
  if docker exec "$SCYLLA_MANAGER_NAME" sctool version >/dev/null 2>&1; then
    manager_ready=true
    break
  fi
  sleep "$SCYLLA_POLL_INTERVAL"
done
[[ "$manager_ready" == true ]] || fail "Timed out waiting for Scylla Manager"
docker exec "$SCYLLA_MANAGER_NAME" sctool version

seed_ip=$(container_ip "$seed_name")
[[ -n "$seed_ip" ]] || fail "Could not determine the seed node IP address"
log "Registering '$SCYLLA_CLUSTER_NAME' with Scylla Manager"
docker exec "$SCYLLA_MANAGER_NAME" sctool cluster add \
  --host="$seed_ip" --name "$SCYLLA_CLUSTER_NAME"

log "Scylla node addresses:"
for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
  node_name="${SCYLLA_CONTAINER_PREFIX}-${index}"
  printf '  %s %s\n' "$node_name" "$(container_ip "$node_name")"
done
printf '  %s %s\n' "$SCYLLA_MANAGER_NAME" "$(container_ip "$SCYLLA_MANAGER_NAME")"
log "Setup complete. Run scripts/setup-monitoring.sh to configure monitoring."
