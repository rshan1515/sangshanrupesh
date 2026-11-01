# Scylla cluster setup and management

These scripts create a local Docker-based Scylla cluster, register it with
Scylla Manager, configure the Scylla Grafana monitoring repository, and check
the resulting deployment. They are intended for development and evaluation,
not production.

## Prerequisites

- Docker Engine with enough memory and CPU for the requested nodes.
- Bash, `git`, and the Docker CLI.
- Docker Compose v2 only if using `docker-compose.yml`.
- Outbound access to pull the Scylla images and clone the monitoring repository.

The default configuration allocates 750 MB and one CPU shard per Scylla
container. Adjust these values to suit the host; Scylla may require more
resources for useful workloads.

## Quick start

From the repository root:

```bash
chmod +x scripts/*.sh tests/scylla-cluster.test.sh
scripts/setup-scylla-cluster.sh
tests/scylla-cluster.test.sh
scripts/setup-monitoring.sh
```

The setup script waits for all nodes to appear as `UN` in `nodetool status`,
starts the Manager database and service, and registers the cluster. It prints
the container IP addresses for use by other tools. Startup can take several
minutes on a constrained host.

To remove the script-created containers and network:

```bash
scripts/cleanup-scylla.sh
```

Cleanup also removes the named data volumes used by the Compose configuration.
Back up any data you want to keep before running it.

## Configuration

The scripts accept environment variables; defaults are shown below.

| Variable | Default | Description |
| --- | --- | --- |
| `SCYLLA_NODE_COUNT` | `3` | Number of nodes started and checked |
| `SCYLLA_CONTAINER_PREFIX` | `scylla-node` | Node container name prefix |
| `SCYLLA_NETWORK` | `scylla-net` | Docker network shared by the services |
| `SCYLLA_IMAGE` | `scylladb/scylla:latest` | Scylla image |
| `SCYLLA_SMP` | `1` | CPU shards per Scylla container |
| `SCYLLA_MEMORY` | `750M` | Memory limit passed to Scylla |
| `SCYLLA_MANAGER_DB_NAME` | `scylla-manager-db` | Manager database container |
| `SCYLLA_MANAGER_NAME` | `scylla-manager` | Manager container |
| `SCYLLA_MANAGER_IMAGE` | `scylladb/scylla-manager:latest` | Manager image |
| `SCYLLA_CLUSTER_NAME` | `my-cluster` | Name registered in Manager |
| `SCYLLA_STARTUP_TIMEOUT` | `600` | Maximum wait for nodes and Manager, in seconds |
| `SCYLLA_POLL_INTERVAL` | `10` | Health-check polling interval, in seconds |

For example:

```bash
SCYLLA_NODE_COUNT=5 SCYLLA_MEMORY=2G SCYLLA_SMP=2 \
  scripts/setup-scylla-cluster.sh
SCYLLA_NODE_COUNT=5 scripts/cleanup-scylla.sh
```

The setup script refuses to overwrite existing container names. Clean up the
deployment before changing its configuration and starting it again.

## Docker Compose alternative

Compose provides a fixed three-node cluster with named data volumes:

```bash
docker compose -f docker-compose.yml up -d
docker exec scylla-node-1 nodetool status
docker exec scylla-manager sctool version
docker exec scylla-manager sctool cluster add \
  --host=scylla-node-1 --name=my-cluster
tests/scylla-cluster.test.sh
```

Compose and `scripts/setup-scylla-cluster.sh` are alternative ways to create
the cluster; do not run both against the same container names. Compose
supports resource overrides through `SCYLLA_SMP`, `SCYLLA_MEMORY`,
`SCYLLA_IMAGE`, and `SCYLLA_MANAGER_IMAGE`. Tear it down, including data, with:

```bash
docker compose -f docker-compose.yml down --volumes
```

## Monitoring

`scripts/setup-monitoring.sh` clones
[`scylla-grafana-monitoring`](https://github.com/scylladb/scylla-grafana-monitoring)
into `SCYLLA_MONITORING_DIR` (default: `scylla-grafana-monitoring`), discovers
the node and Manager IPs, writes `prometheus/scylla_servers.yml` and
`prometheus/scylla_manager_servers.yml`, and invokes `start-all.sh`.

The monitoring script supports these additional settings:

| Variable | Default | Description |
| --- | --- | --- |
| `SCYLLA_MONITORING_DIR` | `scylla-grafana-monitoring` | Checkout location |
| `SCYLLA_MONITORING_REPOSITORY` | Scylla monitoring GitHub URL | Git repository to clone |
| `SCYLLA_MONITORING_REF` | Repository default branch | Optional branch or tag |
| `SCYLLA_MONITORING_SCYLLA_VERSION` | `3.0` | Scylla version passed to `start-all.sh -v` |
| `SCYLLA_MONITORING_MANAGER_VERSION` | `1.3` | Manager version passed to `start-all.sh -M` |

Set the version values to versions supported by the selected monitoring
checkout. Keep the Scylla, Manager, and monitoring releases compatible.

## Security notes

The containers share an isolated Docker network and publish no ports to the
host by default. The Scylla API listens on the container network so Manager can
reach it; do not add public port mappings or use `--api-address 0.0.0.0` in a
production environment without a deliberate, secured network design. Do not
expose CQL, Prometheus, or Grafana ports publicly without authentication,
firewalling, and TLS as appropriate. The default image tags use `latest`; pin
tested versions for repeatable or production deployments.

The Manager database in this development setup is separate from the managed
cluster. Do not use a production cluster as the Manager backend.

## Troubleshooting

- **A container name already exists:** run `scripts/cleanup-scylla.sh` with the
  same node count/prefix, or remove the stale container after verifying it is
  safe to do so.
- **Nodes do not become `UN`:** inspect `docker logs scylla-node-1` and
  `docker logs scylla-node-2`; verify Docker has sufficient memory and that
  all nodes are attached to `SCYLLA_NETWORK`.
- **Manager times out:** inspect `docker logs scylla-manager-db` and
  `docker logs scylla-manager`. Confirm the database and Manager can
  communicate on the shared Docker network.
- **Monitoring cannot find IPs:** ensure the node and Manager containers are
  running and joined to a Docker network before running the monitoring script.
- **Monitoring startup fails:** check the monitoring repository's release
  compatibility and its `start-all.sh` requirements. Override the version
  variables as needed.
- **Network cleanup fails:** the network may have other containers attached.
  Disconnect only containers you recognize, then retry cleanup.

Review container logs before retrying setup. A failed setup may leave
containers behind; cleanup is safe to run to remove this suite's named
containers.
