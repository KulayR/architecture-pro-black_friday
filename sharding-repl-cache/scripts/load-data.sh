#!/bin/bash
echo "Заливка данных в somedb.helloDoc..."

docker compose exec -T mongos1 mongosh --quiet <<EOF
use somedb

// 1. Создаем индекс для ключа шардирования (Hashed)
db.helloDoc.createIndex({ name: "hashed" })

// 2. Включаем шардирование коллекции
// Данные будут распределяться по хешу поля 'name'
sh.shardCollection("somedb.helloDoc", { name: "hashed" })

// 3. Генерируем 1000 документов
var bulk = db.helloDoc.initializeUnorderedBulkOp();
for(var i = 0; i < 1000; i++) {
    bulk.insert({ age: i, name: "ly" + i });
}
bulk.execute();

print("1000 документов вставлено.")
print("Распределение по шардам:")
db.helloDoc.getShardDistribution()
EOF