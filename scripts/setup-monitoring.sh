#!/usr/bin/env bash
set -Eeuo pipefail

SCYLLA_CONTAINER_PREFIX=${SCYLLA_CONTAINER_PREFIX:-scylla-node}
SCYLLA_NODE_COUNT=${SCYLLA_NODE_COUNT:-3}
SCYLLA_MANAGER_NAME=${SCYLLA_MANAGER_NAME:-scylla-manager}
SCYLLA_CLUSTER_NAME=${SCYLLA_CLUSTER_NAME:-my-cluster}
SCYLLA_MONITORING_DIR=${SCYLLA_MONITORING_DIR:-scylla-grafana-monitoring}
SCYLLA_MONITORING_REPOSITORY=${SCYLLA_MONITORING_REPOSITORY:-https://github.com/scylladb/scylla-grafana-monitoring.git}
SCYLLA_MONITORING_REF=${SCYLLA_MONITORING_REF:-}
SCYLLA_MONITORING_SCYLLA_VERSION=${SCYLLA_MONITORING_SCYLLA_VERSION:-3.0}
SCYLLA_MONITORING_MANAGER_VERSION=${SCYLLA_MONITORING_MANAGER_VERSION:-1.3}

log() {
  printf '[scylla-monitoring] %s\n' "$*"
}

fail() {
  printf '[scylla-monitoring] ERROR: %s\n' "$*" >&2
  exit 1
}

for command_name in docker git; do
  command -v "$command_name" >/dev/null 2>&1 || fail "Required command not found: $command_name"
done
[[ "$SCYLLA_NODE_COUNT" =~ ^[1-9][0-9]*$ ]] || fail "SCYLLA_NODE_COUNT must be a positive integer"
[[ "$SCYLLA_CLUSTER_NAME" =~ ^[A-Za-z0-9._-]+$ ]] ||
  fail "SCYLLA_CLUSTER_NAME may contain only letters, numbers, dots, underscores, and hyphens"

container_ip() {
  local ip
  ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1" 2>/dev/null) ||
    fail "Could not inspect container '$1'; start the cluster first"
  [[ -n "$ip" ]] || fail "Container '$1' has no Docker network IP"
  printf '%s' "$ip"
}

if [[ ! -d "$SCYLLA_MONITORING_DIR/.git" ]]; then
  [[ ! -e "$SCYLLA_MONITORING_DIR" ]] ||
    fail "'$SCYLLA_MONITORING_DIR' exists but is not a Git checkout"
  log "Cloning $SCYLLA_MONITORING_REPOSITORY"
  clone_args=(--depth 1)
  [[ -z "$SCYLLA_MONITORING_REF" ]] || clone_args+=(--branch "$SCYLLA_MONITORING_REF")
  git clone "${clone_args[@]}" "$SCYLLA_MONITORING_REPOSITORY" "$SCYLLA_MONITORING_DIR"
fi

prometheus_dir="$SCYLLA_MONITORING_DIR/prometheus"
[[ -d "$prometheus_dir" ]] || fail "Monitoring checkout has no prometheus/ directory"
scylla_config="$prometheus_dir/scylla_servers.yml"
manager_config="$prometheus_dir/scylla_manager_servers.yml"
[[ ! -e "$scylla_config" || -w "$scylla_config" ]] || fail "Cannot write '$scylla_config'"
[[ ! -e "$manager_config" || -w "$manager_config" ]] || fail "Cannot write '$manager_config'"

scylla_tmp=$(mktemp "${scylla_config}.XXXXXX")
manager_tmp=$(mktemp "${manager_config}.XXXXXX")
trap 'rm -f "$scylla_tmp" "$manager_tmp"' EXIT

{
  printf -- '- targets:\n'
  for index in $(seq 1 "$SCYLLA_NODE_COUNT"); do
    node_name="${SCYLLA_CONTAINER_PREFIX}-${index}"
    printf '    - "%s"\n' "$(container_ip "$node_name")"
  done
  printf '  labels:\n    cluster: "%s"\n' "$SCYLLA_CLUSTER_NAME"
} >"$scylla_tmp"
printf -- '- targets:\n    - "%s"\n' "$(container_ip "$SCYLLA_MANAGER_NAME")" >"$manager_tmp"

mv "$scylla_tmp" "$scylla_config"
mv "$manager_tmp" "$manager_config"
trap - EXIT

[[ -x "$SCYLLA_MONITORING_DIR/start-all.sh" ]] ||
  fail "Missing or non-executable $SCYLLA_MONITORING_DIR/start-all.sh"
log "Starting monitoring (Scylla $SCYLLA_MONITORING_SCYLLA_VERSION, Manager $SCYLLA_MONITORING_MANAGER_VERSION)"
(
  cd "$SCYLLA_MONITORING_DIR"
  ./start-all.sh -v "$SCYLLA_MONITORING_SCYLLA_VERSION" -M "$SCYLLA_MONITORING_MANAGER_VERSION"
)
log "Monitoring setup complete"
