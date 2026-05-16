## Docker Development Environment

Local development environment for the full infrastructure stack using Docker Compose. All services run as containers with health checks and persistent volumes.

---

### Services

| Service      | Version   | Port  | Status |
|-------------|-----------|-------|--------|
| ClickHouse  | 26.4.2.10 | 8123, 9000 | ✅ |
| Kafka       | 4.2.0     | 9092, 9093 | ✅ |
| PostgreSQL  | 16        | 5432  | ✅ |
| Redis       | 8         | 6379  | ✅ |

---

### Requirements

- Docker 24+
- Docker Compose v2+

---

### Quick Start

```bash
## 1. Navigate to docker directory
cd docker

## 2. Copy environment file
cp .env.example .env

## 3. Edit if needed
vim .env

## 4. Start all services
docker compose --profile all up -d

## 5. Check status
docker compose --profile all ps
```

---

### Selective Service Start

```bash
## Start only ClickHouse
docker compose --profile clickhouse up -d

## Start only Kafka
docker compose --profile kafka up -d

## Start only PostgreSQL
docker compose --profile postgresql up -d

## Start only Redis
docker compose --profile redis up -d

## Start multiple services
docker compose --profile clickhouse \
               --profile kafka up -d
```

---

### Stop Services

```bash
## Stop all services (keeps data)
docker compose --profile all down

## Stop specific service
docker compose --profile clickhouse down

## Stop and remove all data
docker compose --profile all down -v
```

---

### Environment Variables

All variables can be overridden in `.env` file.
Copy `.env.example` to `.env` and edit as needed.

| Variable | Default | Description |
|----------|---------|-------------|
| `CLICKHOUSE_VERSION` | `26.4.2.10` | ClickHouse version |
| `CLICKHOUSE_HTTP_PORT` | `8123` | ClickHouse HTTP port |
| `CLICKHOUSE_TCP_PORT` | `9000` | ClickHouse TCP port |
| `CLICKHOUSE_ADMIN_USER` | `admin` | ClickHouse admin user |
| `CLICKHOUSE_ADMIN_PASSWORD` | `changeme` | ClickHouse admin password |
| `KAFKA_VERSION` | `4.2.0` | Kafka version |
| `KAFKA_PORT` | `9092` | Kafka broker port |
| `KAFKA_CONTROLLER_PORT` | `9093` | Kafka controller port |
| `KAFKA_HEAP_SIZE` | `512M` | Kafka JVM heap size |
| `POSTGRESQL_VERSION` | `16` | PostgreSQL version |
| `POSTGRESQL_PORT` | `5432` | PostgreSQL port |
| `POSTGRESQL_USER` | `postgres` | PostgreSQL user |
| `POSTGRESQL_PASSWORD` | `changeme` | PostgreSQL password |
| `POSTGRESQL_DB` | `postgres` | PostgreSQL database |
| `REDIS_VERSION` | `8` | Redis version |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | `changeme` | Redis password |

---

### Verify Services

#### ClickHouse
```bash
## Check version
docker exec clickhouse clickhouse-client \
  --query "SELECT version()"

## Connect with admin user
docker exec -it clickhouse clickhouse-client \
  --user admin \
  --password changeme
```

#### Kafka
```bash
## Check broker
docker exec kafka /opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server localhost:9092 | head -3

## Create test topic
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic test-topic \
  --partitions 1 \
  --replication-factor 1

## List topics
docker exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

#### PostgreSQL
```bash
## Connect to PostgreSQL
docker exec -it postgresql psql \
  -U postgres

## Check version
docker exec postgresql psql \
  -U postgres \
  -c "SELECT version()"
```

#### Redis
```bash
## Ping Redis
docker exec redis redis-cli \
  -a changeme ping

## Set and get test key
docker exec redis redis-cli \
  -a changeme set test "hello"

docker exec redis redis-cli \
  -a changeme get test
```

---

### Data Persistence

All data is stored in Docker named volumes:

| Volume | Service | Description |
|--------|---------|-------------|
| `clickhouse_data` | ClickHouse | Database files |
| `clickhouse_logs` | ClickHouse | Log files |
| `kafka_data` | Kafka | Topic data |
| `postgresql_data` | PostgreSQL | Database files |
| `redis_data` | Redis | RDB snapshots |

---

### Configuration Files

Custom configuration files are mounted into containers:

| File | Service | Description |
|------|---------|-------------|
| `clickhouse/clickhouse-config.xml` | ClickHouse | Main config |
| `clickhouse/clickhouse-users.xml` | ClickHouse | Users config |
| `postgresql/postgresql.conf` | PostgreSQL | Main config |
| `redis/redis.conf` | Redis | Main config |

