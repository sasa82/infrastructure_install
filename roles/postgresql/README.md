## PostgreSQL Role

Ansible role for PostgreSQL installation and configuration on bare metal Ubuntu servers. Single node deployment with secure network access control.

---

### Architecture

```
Single Server
└── PostgreSQL Server
    └── Listening on all interfaces (0.0.0.0)
    └── Access controlled by pg_hba.conf
    └── Password authentication (scram-sha-256)
    └── Private networks allowed by default
```

---

### Inventory Setup

#### Production (inventories/production/hosts.ini)
```ini
[postgresql]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

### How Network Access Works

```
Two layers of security:

Layer 1: postgresql.conf
└── listen_addresses = *
    accepts connections on all interfaces

Layer 2: pg_hba.conf
└── controls which networks can authenticate
    private networks allowed by default
    configurable via postgresql_allowed_networks
```

---

### Configuration Variables

All variables have sensible defaults in `defaults/main.yml`.
Only override what you need in `inventories/*/group_vars/all.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `postgresql_version` | `16` | PostgreSQL version |
| `postgresql_listen_addresses` | `*` | Listen addresses |
| `postgresql_port` | `5432` | PostgreSQL port |
| `postgresql_allowed_networks` | private ranges | Networks allowed to connect |
| `postgresql_max_connections` | `100` | Max connections |
| `postgresql_shared_buffers` | `256MB` | Shared buffers |
| `postgresql_effective_cache_size` | `1GB` | Effective cache size |
| `postgresql_work_mem` | `4MB` | Work memory |
| `postgresql_maintenance_work_mem` | `64MB` | Maintenance work memory |
| `postgresql_admin_user` | `postgres` | Admin username |
| `postgresql_admin_password` | `changeme` | Admin password |
| `postgresql_databases` | `[]` | Extra databases to create |
| `postgresql_users` | `[]` | Extra users to create |

---

### Creating Extra Databases And Users

Override in `inventories/production/group_vars/all.yml`:

```yaml
postgresql_databases:
  - myapp_db
  - analytics_db

postgresql_users:
  - name: myapp_user
    password: securepassword
  - name: analytics_user
    password: securepassword
```

---

### Allowed Networks

Override in `inventories/production/group_vars/all.yml`:

```yaml
postgresql_allowed_networks:
  - "127.0.0.1/32"
  - "10.0.0.0/8"
  - "192.168.0.0/16"
```

---

### Install & Rollback

```bash
## Install
ansible-playbook playbooks/install_postgresql.yml \
  -i inventories/production/hosts.ini

## Rollback
ansible-playbook playbooks/rollback_postgresql.yml \
  -i inventories/production/hosts.ini
```

---

### Verify Installation

```bash
## Check service
systemctl status postgresql@16-main

## Connect as postgres user
sudo -u postgres psql

## Check version
sudo -u postgres psql -c "SELECT version()"

## Check listening address
sudo -u postgres psql -c "SHOW listen_addresses"

## List databases
sudo -u postgres psql -c "\l"
```
