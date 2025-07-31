#!/bin/bash

echo "🔧 Инициализация конфигурационного репликасета"
docker compose exec -T configsvr mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [{_id: 0, host: "configsvr:27019"}]
})
EOF

echo "🧬 Инициализация репликации shard1"
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({_id: "shard1ReplSet", members: [{_id: 0, host: "shard1:27018"}]})
EOF

echo "🧬 Инициализация репликации shard2"
docker compose exec -T shard2 mongosh --port 27020 --quiet <<EOF
rs.initiate({_id: "shard2ReplSet", members: [{_id: 0, host: "shard2:27020"}]})
EOF

echo "⏳ Ожидание реплик..."
sleep 5

echo "📦 Добавляем шард1 и шард2"
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
sh.addShard("shard1ReplSet/shard1:27018")
sh.addShard("shard2ReplSet/shard2:27020")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { _id: "hashed" })
EOF

echo "🧪 Вставка данных (1500 документов)"
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
for (let i = 0; i < 1500; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i })
}
EOF

echo "🔎 Проверка количества документов по шард1 и шард2"
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb
print("🔹 shard1 count:")
print(db.helloDoc.countDocuments())
EOF

docker compose exec -T shard2 mongosh --port 27020 --quiet <<EOF
use somedb
print("🔹 shard2 count:")
print(db.helloDoc.countDocuments())
EOF
