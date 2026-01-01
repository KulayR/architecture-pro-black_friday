#!/bin/bash
echo "Сборка кластера..."

# 1. Инициализация Config Servers
echo "Инициализация Config RS..."
docker compose exec configsvr1 mongosh --port 27017 --eval '
  rs.initiate({
    _id: "configRS",
    configsvr: true,
    members: [
      {_id: 0, host: "configsvr1:27017"},
      {_id: 1, host: "configsvr2:27017"}
    ]
  })
'

# 2. Инициализация Shard 1 (3 узла)
echo "Инициализация Shard 1 RS..."
docker compose exec shard1-1 mongosh --port 27017 --eval '
  rs.initiate({
    _id: "shard1RS",
    members: [
      {_id: 0, host: "shard1-1:27017"},
      {_id: 1, host: "shard1-2:27017"},
      {_id: 2, host: "shard1-3:27017"}
    ]
  })
'

# 3. Инициализация Shard 2 (3 узла)
echo "Инициализация Shard 2 RS..."
docker compose exec shard2-1 mongosh --port 27017 --eval '
  rs.initiate({
    _id: "shard2RS",
    members: [
      {_id: 0, host: "shard2-1:27017"},
      {_id: 1, host: "shard2-2:27017"},
      {_id: 2, host: "shard2-3:27017"}
    ]
  })
'

# 4. Перезапуск роутеров
echo "Перезапуск mongos..."
docker compose restart mongos1 mongos2
echo "Ждем 20 сек для выбора Primary узлов и старта роутеров..."
sleep 20

# 5. Добавление шардов в роутер
echo "Добавление шардов в кластер..."
docker compose exec mongos1 mongosh --port 27017 --eval '
  sh.addShard("shard1RS/shard1-1:27017,shard1-2:27017,shard1-3:27017");
  sh.addShard("shard2RS/shard2-1:27017,shard2-2:27017,shard2-3:27017");
  sh.enableSharding("somedb");
'

echo "Кластер инициализирован."
