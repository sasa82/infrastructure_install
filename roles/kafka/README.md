## Kafka Role

Ansible role for Apache Kafka installation and configuration on bare metal Ubuntu servers. Uses KRaft mode (no ZooKeeper) for both single node and cluster deployments.

---

### Architecture

#### Single Node
```
Single Server
└── Kafka Broker + Controller
    └── KRaft mode (no ZooKeeper!)
    └── For testing/development
```

#### Cluster (Production)
```
Kafka Cluster (KRaft mode!)
│
├── Node 1 (Broker + Controller)
├── Node 2 (Broker + Controller)
└── Node 3 (Broker + Controller)

Important:
- No ZooKeeper needed! KRaft is built-in
- Minimum 3 nodes for quorum
- All nodes are broker + controller
- Quorum needs (n/2 + 1) votes
- 3 nodes can survive 1 node failure
```

---

### Inventory Setup

#### Single Node (inventories/single/hosts.ini)
```ini
[kafka]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

#### Production Cluster (inventories/production/hosts.ini)
```ini
[kafka]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.2 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519
10.0.0.3 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

### How Node Lists Work

Node IPs are defined **only** in `hosts.ini`. Ansible derives everything else dynamically including broker IDs and quorum voters.

```
hosts.ini (single source of truth)
        │
        ▼
Ansible reads inventory groups
        │
        ▼
cluster.yml builds node IDs and quorum voters
        │
        ▼
Jinja2 templates render configs per node
        │
        ▼
Each node gets correct broker ID automatically
```

---

### Configuration Variables

All variables have sensible defaults in `defaults/main.yml`.
Only override what you need in `inventories/*/group_vars/all.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `deployment_mode` | `single` | `single` or `cluster` |
| `kafka_version` | `4.2.0` | Kafka version |
| `kafka_scala_version` | `2.13` | Scala version |
| `java_version` | `17` | Java version |
| `kafka_port` | `9092` | Broker port |
| `kafka_controller_port` | `9093` | Controller port |
| `kafka_data_path` | `/var/lib/kafka` | Data directory |
| `kafka_log_path` | `/var/log/kafka` | Log directory |
| `kafka_heap_size` | `1G` | JVM heap size |
| `kafka_num_partitions` | `1` | Default partitions |
| `kafka_replication_factor` | `1` | Default replication |
| `kafka_log_retention_hours` | `168` | Log retention (7 days) |
| `kafka_log_segment_bytes` | `1073741824` | Log segment size (1GB) |

---

### Install & Rollback

```bash
## Install single node
ansible-playbook playbooks/install_kafka.yml \
  -i inventories/single/hosts.ini

## Install production cluster
ansible-playbook playbooks/install_kafka.yml \
  -i inventories/production/hosts.ini

## Rollback single node
ansible-playbook playbooks/rollback_kafka.yml \
  -i inventories/single/hosts.ini

## Rollback production cluster
ansible-playbook playbooks/rollback_kafka.yml \
  -i inventories/production/hosts.ini
```

---

### Verify Installation

```bash
## Check broker API versions
/opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server localhost:9092

## Create test topic
/opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic test-topic \
  --partitions 1 \
  --replication-factor 1

## List topics
/opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### Known Compatibility Issues

```
KafkaJS (used by n8n and other tools):
└── Poor KRaft mode support
└── Last release 2022, basically abandoned
└── If using n8n with Kafka consider
    using webhooks or alternative connectors
```
