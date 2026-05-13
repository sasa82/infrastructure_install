## ClickHouse Role

Ansible role for ClickHouse installation and configuration on bare metal Ubuntu servers. Supports both single node and cluster deployments using ClickHouse Keeper for coordination.

---

### Architecture

#### Single Node
```
Single Server
└── ClickHouse Server
    └── No replication
    └── No Keeper needed
    └── For testing/development
```

#### Cluster (Production)
```
ClickHouse Cluster (Masterless!)
│
├── Node 1 (Shard 1, Replica 1)  ← ClickHouse + Keeper
├── Node 2 (Shard 1, Replica 2)  ← ClickHouse + Keeper
└── Node 3 (Dedicated Keeper)    ← Keeper only (quorum)

Important:
- ClickHouse has NO master node!
- All data nodes are equal
- Keeper handles replication coordination
- Minimum 3 Keeper nodes required for quorum
- 2 data nodes + 1 dedicated Keeper = minimum HA setup
```

---

### Inventory Setup

#### Single Node (inventories/single/hosts.ini)
```ini
[clickhouse]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[clickhouse_keeper]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

#### Production Cluster (inventories/production/hosts.ini)
```ini
[clickhouse]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.2 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[clickhouse_keeper]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.2 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.3 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

### How Node Lists Work

Node IPs are defined **only** in `hosts.ini`. Ansible derives everything else dynamically.

```
hosts.ini (single source of truth)
        │
        ▼
Ansible reads inventory groups
        │
        ▼
cluster.yml builds node lists dynamically
        │
        ▼
Jinja2 templates render configs per node
        │
        ▼
Each node gets correct config automatically
```

---

### Configuration Variables

All variables have sensible defaults in `defaults/main.yml`.
Only override what you need in `inventories/*/group_vars/all.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `deployment_mode` | `single` | `single` or `cluster` |
| `clickhouse_version` | `26.4.2.10` | ClickHouse version |
| `clickhouse_cluster_name` | `my_cluster` | Cluster name |
| `clickhouse_shards` | `1` | Number of shards |
| `clickhouse_replicas` | `1` | Number of replicas |
| `clickhouse_http_port` | `8123` | HTTP port |
| `clickhouse_tcp_port` | `9000` | TCP port |
| `clickhouse_interserver_port` | `9009` | Interserver port |
| `clickhouse_keeper_port` | `9181` | Keeper port |
| `clickhouse_keeper_raft_port` | `9234` | Keeper Raft port |
| `clickhouse_data_path` | `/var/lib/clickhouse` | Data directory |
| `clickhouse_log_path` | `/var/log/clickhouse-server` | Log directory |
| `clickhouse_admin_user` | `admin` | Admin username |
| `clickhouse_admin_password` | `changeme` | Admin password |
| `clickhouse_max_memory_usage` | `10000000000` | Max memory in bytes |
| `clickhouse_max_connections` | `4096` | Max connections |

---

### Install & Rollback

```bash
## Install single node
ansible-playbook playbooks/install_clickhouse.yml \
  -i inventories/single/hosts.ini

## Install production cluster
ansible-playbook playbooks/install_clickhouse.yml \
  -i inventories/production/hosts.ini

## Rollback single node
ansible-playbook playbooks/rollback_clickhouse.yml \
  -i inventories/single/hosts.ini

## Rollback production cluster
ansible-playbook playbooks/rollback_clickhouse.yml \
  -i inventories/production/hosts.ini
```

---

### Verify Installation

```bash
## Check version
clickhouse-client --query "SELECT version()"

## Check cluster (cluster mode only)
clickhouse-client --query "SELECT * FROM system.clusters"

## Check databases
clickhouse-client --query "SHOW DATABASES"

## Connect with admin user
clickhouse-client \
  --user admin \
  --password changeme \
  --query "SELECT 1"
```
