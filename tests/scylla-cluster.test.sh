#!/usr/bin/env bash
set -Eeuo pipefail

SCYLLA_CONTAINER_PREFIX=${SCYLLA_CONTAINER_PREFIX:-scylla-node}
SCYLLA_NODE_COUNT=${SCYLLA_NODE_COUNT:-3}
SCYLLA_NETWORK=${SCYLLA_NETWORK:-scylla-net}
SCYLLA_MANAGER_DB_NAME=${SCYLLA_MANAGER_DB_NAME:-scylla-manager-db}
SCYLLA_MANAGER_NAME=${SCYLLA_MANAGER_NAME:-scylla-manager}
SCYLLA_CLUSTER_NAME=${SCYLLA_CLUSTER_NAME:-my-cluster}

fail() {
  printf '[scylla-test] FAIL: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker is required"
[[ "$SCYLLA_NODE_COUNT" =~ ^[1-9][0-9]*$ ]] || fail "SCYLLA_NODE_COUNT must be a positive integer"

docker network inspect "$SCYLLA_NETWORK" >/dev/null 2>&1 ||
  fail "Docker network '$SCYLLA_NETWORK' is not running"

for name in "$SCYLLA_MANAGER_DB_NAME" "$SCYLLA_MANAGER_NAME"; do
  docker container inspect "$name" >/dev/null 2>&1 || fail "Container '$name' is missing"
done

nodes=()
for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
  name="${SCYLLA_CONTAINER_PREFIX}-${index}"
  docker container inspect "$name" >/dev/null 2>&1 || fail "Container '$name' is missing"
  networks=$(docker inspect --format='{{range $name, $network := .NetworkSettings.Networks}}{{println $name}}{{end}}' "$name")
  grep -Fxq "$SCYLLA_NETWORK" <<<"$networks" || fail "Container '$name' is not attached to '$SCYLLA_NETWORK'"
  nodes+=("$name")
done

for name in "$SCYLLA_MANAGER_DB_NAME" "$SCYLLA_MANAGER_NAME"; do
  networks=$(docker inspect --format='{{range $name, $network := .NetworkSettings.Networks}}{{println $name}}{{end}}' "$name")
  grep -Fxq "$SCYLLA_NETWORK" <<<"$networks" || fail "Container '$name' is not attached to '$SCYLLA_NETWORK'"
done

status=$(docker exec "${nodes[0]}" nodetool status) || fail "nodetool status failed"
healthy_count=$(awk '$1 == "UN" { count++ } END { print count+0 }' <<<"$status")
(( healthy_count == SCYLLA_NODE_COUNT )) ||
  fail "Expected $SCYLLA_NODE_COUNT UN nodes, found $healthy_count"
printf '%s\n' "$status"

docker exec "$SCYLLA_MANAGER_NAME" sctool version ||
  fail "Scylla Manager is not responding to sctool"
cluster_list=$(docker exec "$SCYLLA_MANAGER_NAME" sctool cluster list) ||
  fail "Scylla Manager could not list clusters"
grep -Fq "$SCYLLA_CLUSTER_NAME" <<<"$cluster_list" ||
  fail "Cluster '$SCYLLA_CLUSTER_NAME' is not registered with Scylla Manager"

printf '[scylla-test] PASS: %s healthy node(s), Manager operational, containers share %s\n' \
  "$SCYLLA_NODE_COUNT" "$SCYLLA_NETWORK"
