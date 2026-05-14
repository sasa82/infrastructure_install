## Redis Role

Ansible role for Redis installation and configuration on bare metal Ubuntu servers. Single node deployment with password authentication and systemd integration.

---

### Architecture

```
Single Server
└── Redis Server 8.x
    └── Listening on all interfaces (0.0.0.0)
    └── Password authentication required
    └── Systemd supervised mode
    └── RDB persistence enabled
    └── Memory limit configurable
```

---

### Inventory Setup

#### Production (inventories/production/hosts.ini)
```ini
[redis]
10.0.0.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_ed25519

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

### Configuration Variables

All variables have sensible defaults in `defaults/main.yml`.
Only override what you need in `inventories/*/group_vars/all.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `redis_version` | `8` | Redis version |
| `redis_bind` | `0.0.0.0` | Bind address |
| `redis_port` | `6379` | Redis port |
| `redis_protected_mode` | `no` | Protected mode |
| `redis_password` | `changeme` | Auth password |
| `redis_data_path` | `/var/lib/redis` | Data directory |
| `redis_log_file` | `/var/log/redis/redis-server.log` | Log file |
| `redis_maxmemory` | `512mb` | Max memory |
| `redis_maxmemory_policy` | `allkeys-lru` | Eviction policy |
| `redis_appendonly` | `no` | AOF persistence |
| `redis_save` | `900 1, 300 10, 60 10000` | RDB save points |

---

### Memory Policies

```
allkeys-lru     → evict least recently used keys (recommended)
allkeys-lfu     → evict least frequently used keys
volatile-lru    → evict LRU keys with TTL set
volatile-lfu    → evict LFU keys with TTL set
allkeys-random  → evict random keys
volatile-random → evict random keys with TTL set
volatile-ttl    → evict keys with shortest TTL
noeviction      → return error when memory limit reached
```

---

### Install & Rollback

```bash
## Install
ansible-playbook playbooks/install_redis.yml \
  -i inventories/production/hosts.ini

## Rollback
ansible-playbook playbooks/rollback_redis.yml \
  -i inventories/production/hosts.ini
```

---

### Verify Installation

```bash
## Check service
systemctl status redis-server

## Ping redis
redis-cli -a changeme ping

## Set and get test key
redis-cli -a changeme set test "hello"
redis-cli -a changeme get test

## Check server info
redis-cli -a changeme info server | grep -E "redis_version|tcp_port|bind"

## Check memory
redis-cli -a changeme info memory | grep used_memory_human
```
