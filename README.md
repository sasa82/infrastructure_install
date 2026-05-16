## infrastructure-install

Production-grade infrastructure installation using Ansible for bare metal servers and Docker for local development. One-click installation for multiple services with support for both single node and cluster deployments.

---

### Supported Services

| Service      | Single Node | Cluster | Bare Metal | Docker Dev | Status   |
|-------------|-------------|---------|------------|------------|----------|
| ClickHouse  | ✅          | ✅      | ✅         | ✅         | Ready    |
| Kafka       | ✅          | ✅      | ✅         | ✅         | Ready    |
| PostgreSQL  | ✅          | ❌      | ✅         | ✅         | Ready    |
| Redis       | ✅          | ❌      | ✅         | ✅         | Ready    |

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
│   ├── clickhouse/          ## ClickHouse role → see roles/clickhouse/README.md
│   └── kafka/               ## Kafka role → see roles/kafka/README.md
│
├── playbooks/
│   ├── install_clickhouse.yml
│   ├── rollback_clickhouse.yml
│   ├── install_kafka.yml
│   └── rollback_kafka.yml
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

#### 1. Clone Repository
```bash
git clone https://github.com/sasa82/infrastructure_install.git
cd infrastructure_install
```

#### 2. Generate SSH Key
```bash
## Generate ED25519 key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

## Same server installation
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

## Remote servers
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@YOUR_SERVER_IP
```

#### 3. Configure Inventory
```bash
## Single node
cp inventories/single/hosts.ini.example inventories/single/hosts.ini
vim inventories/single/hosts.ini

## Production cluster
cp inventories/production/hosts.ini.example inventories/production/hosts.ini
vim inventories/production/hosts.ini
```

#### 4. Install

```bash
## Single node
ansible-playbook playbooks/install_clickhouse.yml -i inventories/single/hosts.ini
ansible-playbook playbooks/install_kafka.yml -i inventories/single/hosts.ini

## Production cluster
ansible-playbook playbooks/install_clickhouse.yml -i inventories/production/hosts.ini
ansible-playbook playbooks/install_kafka.yml -i inventories/production/hosts.ini
```

#### 5. Rollback
```bash
## Single node
ansible-playbook playbooks/rollback_clickhouse.yml -i inventories/single/hosts.ini
ansible-playbook playbooks/rollback_kafka.yml -i inventories/single/hosts.ini

## Production cluster
ansible-playbook playbooks/rollback_clickhouse.yml -i inventories/production/hosts.ini
ansible-playbook playbooks/rollback_kafka.yml -i inventories/production/hosts.ini
```

#### Docker - Local Development (Coming Soon)
```bash
cd docker/
cp .env.example .env
docker compose --profile all up -d
```

---

### Documentation

- [ClickHouse Role](roles/clickhouse/README.md)
- [Kafka Role](roles/kafka/README.md)
- [PostgreSQL Role](roles/postgresql/README.md)
- [Redis Role](roles/redis/README.md)
- [Docker Development Environment](docker/README.md)


