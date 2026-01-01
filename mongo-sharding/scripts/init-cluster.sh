#!/bin/bash
echo "Сборка кластера..."

# 1. Инициализация Config Servers
echo "Инициализация Config RS..."
docker compose exec configsvr1 mongosh --port 27017 --eval 'rs.initiate({_id: "configRS", configsvr: true, members: [{_id: 0, host: "configsvr1:27017"}, {_id: 1, host: "configsvr2:27017"}]})'

# 2. Инициализация Shards
echo "Инициализация Shards RS..."
docker compose exec shard1 mongosh --port 27017 --eval 'rs.initiate({_id: "shard1RS", members: [{_id: 0, host: "shard1:27017"}]})'
docker compose exec shard2 mongosh --port 27017 --eval 'rs.initiate({_id: "shard2RS", members: [{_id: 0, host: "shard2:27017"}]})'

# 3. Перезапуск роутеров
echo "Перезапуск mongos (чтобы подхватили конфиг)..."
docker compose restart mongos1 mongos2

echo "Ждем 15 сек, пока mongos поднимутся и соединятся..."
sleep 15

# 4. Добавление шардов и включение шардинга
echo "Добавление шардов в кластер..."
docker compose exec mongos1 mongosh --port 27017 --eval '
  sh.addShard("shard1RS/shard1:27017");
  sh.addShard("shard2RS/shard2:27017");
  sh.enableSharding("somedb");
'

echo "Кластер инициализирован."