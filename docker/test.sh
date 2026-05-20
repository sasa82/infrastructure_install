##!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; }

echo "=== Infrastructure Health Check ==="
echo ""

### ─── ClickHouse ──────────────────────────────────────────────
echo "--- ClickHouse ---"

## node1
if docker exec ch-node1 clickhouse-client --user admin --password changeme --query "SELECT 1" &>/dev/null; then
    pass "ch-node1 is up"
else
    fail "ch-node1 is down"
fi

## node2
if docker exec ch-node2 clickhouse-client --user admin --password changeme --query "SELECT 1" &>/dev/null; then
    pass "ch-node2 is up"
else
    fail "ch-node2 is down"
fi

## cluster
CLUSTER=$(docker exec ch-node1 clickhouse-client --user admin --password changeme --query "SELECT count() FROM system.clusters WHERE cluster='my_cluster'")
if [ "$CLUSTER" -eq 2 ]; then
    pass "ClickHouse cluster has 2 nodes"
else
    fail "ClickHouse cluster nodes: $CLUSTER"
fi

## replication test
docker exec ch-node1 clickhouse-client --user admin --password changeme --query "
    CREATE DATABASE IF NOT EXISTS test ON CLUSTER my_cluster;
" &>/dev/null

docker exec ch-node1 clickhouse-client --user admin --password changeme --query "
    CREATE TABLE IF NOT EXISTS test.replication_check ON CLUSTER my_cluster (
        id UInt64,
        ts DateTime DEFAULT now()
    ) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/replication_check', '{replica}')
    ORDER BY id;
" &>/dev/null

docker exec ch-node1 clickhouse-client --user admin --password changeme --query "
    INSERT INTO test.replication_check (id) VALUES (1);
" &>/dev/null

sleep 2

NODE2_COUNT=$(docker exec ch-node2 clickhouse-client --user admin --password changeme --query "SELECT count() FROM test.replication_check")
if [ "$NODE2_COUNT" -eq 1 ]; then
    pass "ClickHouse replication working"
else
    fail "ClickHouse replication failed - node2 count: $NODE2_COUNT"
fi

## cleanup
docker exec ch-node1 clickhouse-client --user admin --password changeme --query "
    DROP DATABASE IF EXISTS test ON CLUSTER my_cluster
" &>/dev/null

echo ""

### ─── Kafka ───────────────────────────────────────────────────
echo "--- Kafka ---"

## broker1
if docker exec kafka1 /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server kafka1:9092 &>/dev/null; then
    pass "kafka1 is up"
else
    fail "kafka1 is down"
fi

## broker2
if docker exec kafka2 /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server kafka2:9095 &>/dev/null; then
    pass "kafka2 is up"
else
    fail "kafka2 is down"
fi

## cluster - both brokers visible from kafka1
BROKERS=$(docker exec kafka1 /opt/kafka/bin/kafka-broker-api-versions.sh \
    --bootstrap-server kafka1:9092 2>/dev/null | grep "id:" | wc -l)
if [ "$BROKERS" -eq 2 ]; then
    pass "Kafka cluster has 2 brokers"
else
    fail "Kafka cluster brokers: $BROKERS"
fi

## topic replication test
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server kafka1:9092 \
    --create --topic health-check \
    --partitions 2 \
    --replication-factor 2 &>/dev/null

TOPIC=$(docker exec kafka1 /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server kafka1:9092 \
    --describe --topic health-check 2>/dev/null | grep "ReplicationFactor: 2" | wc -l)
if [ "$TOPIC" -gt 0 ]; then
    pass "Kafka replication factor 2 working"
else
    fail "Kafka replication check failed"
fi

## cleanup
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server kafka1:9092 \
    --delete --topic health-check &>/dev/null

echo ""

### ─── PostgreSQL ──────────────────────────────────────────────
echo "--- PostgreSQL ---"

if docker exec postgresql pg_isready -U postgres &>/dev/null; then
    pass "PostgreSQL is up"
else
    fail "PostgreSQL is down"
fi

PGRESULT=$(docker exec postgresql psql -U postgres -t -c "SELECT 1" 2>/dev/null | tr -d ' ')
if [ "$PGRESULT" -eq 1 ]; then
    pass "PostgreSQL query working"
else
    fail "PostgreSQL query failed"
fi

echo ""

### ─── Redis ───────────────────────────────────────────────────
echo "--- Redis ---"

if docker exec redis redis-cli -a changeme ping 2>/dev/null | grep -q "PONG"; then
    pass "Redis is up"
else
    fail "Redis is down"
fi

docker exec redis redis-cli -a changeme SET health-check "ok" &>/dev/null
REDIS_VAL=$(docker exec redis redis-cli -a changeme GET health-check 2>/dev/null)
if [ "$REDIS_VAL" = "ok" ]; then
    pass "Redis set/get working"
else
    fail "Redis set/get failed"
fi

docker exec redis redis-cli -a changeme DEL health-check &>/dev/null

echo ""
echo "=== Done ==="
