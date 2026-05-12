## infrastructure-install

Production-grade infrastructure installation using Ansible for bare metal servers and Docker for local development. One-click installation for multiple services with support for both single node and cluster deployments.

---

### Supported Services

| Service      | Single Node | Cluster | Bare Metal | Docker Dev | Status   |
|-------------|-------------|---------|------------|------------|----------|
| ClickHouse  | ✅          | ✅      | ✅         | ✅         | Ready    |
| Kafka       | ✅          | ✅      | ✅         | ✅         | Soon     |
| PostgreSQL  | ✅          | ❌      | ✅         | ✅         | Soon     |
| Redis       | ✅          | ❌      | ✅         | ✅         | Soon     |

---

### Requirements

#### Control Node (where you run ansible)
- Ubuntu 24.04 LTS
- Ansible 2.16+
- Python 3.12+
- SSH key pair

#### Target Nodes (bare metal servers)
- Ubuntu 24.04 LTS
- SSH access
- Root or sudo privileges

#### Docker Dev
- Docker
- Docker Compose

---

### Repository Structure

```
infrastructure-install/
│
├── roles/
│   ├── clickhouse/
│   │   ├── defaults/main.yml    ## Default variables
│   │   ├── tasks/
│   │   │   ├── main.yml         ## Entry point
│   │   │   ├── install.yml      ## Package installation
│   │   │   ├── single.yml       ## Single node config
│   │   │   ├── cluster.yml      ## Cluster config
│   │   │   └── configure.yml    ## Service management
│   │   ├── templates/
│   │   │   ├── config.xml.j2    ## Main config
│   │   │   ├── users.xml.j2     ## Users config
│   │   │   └── keeper.xml.j2    ## Keeper config
│   │   └── handlers/main.yml    ## Service handlers
│   └── kafka/                   ## Coming soon
│
├── playbooks/
│   ├── install_clickhouse.yml   ## Install ClickHouse
│   ├── rollback_clickhouse.yml  ## Rollback ClickHouse
│   ├── install_kafka.yml        ## Coming soon
│   └── install_all.yml          ## Coming soon
│
├── inventories/
│   ├── single/
│   │   ├── hosts.ini            ## Your servers (git ignored)
│   │   └── hosts.ini.example    ## Example (in git)
│   └── production/
│       ├── hosts.ini            ## Your servers (git ignored)
│       ├── hosts.ini.example    ## Example (in git)
│       └── group_vars/
│           └── all.yml          ## Production overrides
│
└── docker/                      ## Local dev environment (coming soon)
    ├── docker-compose.yml
    └── .env.example
```

---

### Quick Start

#### Bare Metal - Single Node

```bash
## 1. Clone repository
git clone https://github.com/sasa82/infrastructure_install.git
cd infrastructure_install

## 2. Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

## 3. For same server - add key to authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

## 4. For remote servers - copy key to target server
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@YOUR_SERVER_IP

## 5. Configure inventory
cp inventories/single/hosts.ini.example inventories/single/hosts.ini
vim inventories/single/hosts.ini

## 6. Install
ansible-playbook playbooks/install_clickhouse.yml \
  -i inventories/single/hosts.ini

## 7. Rollback if needed
ansible-playbook playbooks/rollback_clickhouse.yml \
  -i inventories/single/hosts.ini
```

#### Bare Metal - Production Cluster

```bash
## 1. Clone repository
git clone https://github.com/sasa82/infrastructure_install.git
cd infrastructure_install

## 2. Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

## 3. Copy key to all cluster nodes
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@10.0.0.1
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@10.0.0.2
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@10.0.0.3

## 4. Configure inventory
cp inventories/production/hosts.ini.example inventories/production/hosts.ini
vim inventories/production/hosts.ini

## 5. Install
ansible-playbook playbooks/install_clickhouse.yml \
  -i inventories/production/hosts.ini

## 6. Rollback if needed
ansible-playbook playbooks/rollback_clickhouse.yml \
  -i inventories/production/hosts.ini
```

#### Docker - Local Development (Coming Soon)

```bash
cd docker/
cp .env.example .env

## All services
docker compose --profile all up -d

## Only ClickHouse
docker compose --profile clickhouse up -d

## Only Kafka
docker compose --profile kafka up -d
```

---

### ClickHouse

#### Architecture

## Single Node
```
Single Server
└── ClickHouse Server
    └── No replication
    └── No Keeper needed
    └── For testing/development
```

## Cluster (Production)
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

#### Inventory Setup

## Single Node (inventories/single/hosts.ini)
```ini
[clickhouse]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[clickhouse_keeper]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[kafka]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

## Production Cluster (inventories/production/hosts.ini)
```ini
[clickhouse]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.2 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[clickhouse_keeper]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.2 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.3 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[kafka]
10.0.0.4 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.5 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.6 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

#### How Node Lists Work

Node IPs are defined **only** in `hosts.ini`. Ansible derives everything else dynamically. No need to repeat IPs anywhere else!

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

#### Configuration Variables

All variables have sensible defaults in `roles/clickhouse/defaults/main.yml`.
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

#### Verify Installation

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

---

### License
MIT
