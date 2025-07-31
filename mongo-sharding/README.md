# 🛠 Настройка MongoDB с шардированием

В этом проекте реализуется MongoDB-шардирование с двумя шардами, одним конфигурационным сервером и маршрутизатором `mongos`.
После запуска всех контейнеров необходимо выполнить следующие шаги.



## 🧩 Схема компонентов

* `configsvr` — конфигурационный сервер (порт `27019`)
* `shard1`, `shard2` — шарды (порты `27018`, `27020`)
* `mongos` — маршрутизатор (порт `27017`)
* База данных: `somedb`
* Коллекция: `helloDoc`



## 🚀 Шаги инициализации кластера

### 💻 Windows PowerShell

```powershell
# 1. Инициализировать config сервер
docker compose exec configsvr mongosh --port 27019 --eval "rs.initiate({ _id: 'configReplSet', configsvr: true, members: [{ _id: 0, host: 'configsvr:27019' }] })"

# 2. Инициализировать shard1
docker compose exec shard1 mongosh --port 27018 --eval "rs.initiate({ _id: 'shard1ReplSet', members: [{ _id: 0, host: 'shard1:27018' }] })"

# 3. Инициализировать shard2
docker compose exec shard2 mongosh --port 27020 --eval "rs.initiate({ _id: 'shard2ReplSet', members: [{ _id: 0, host: 'shard2:27020' }] })"

# 4. Добавить шарды и включить шардирование
docker compose exec mongos mongosh --port 27017 --eval "sh.addShard('shard1ReplSet/shard1:27018'); sh.addShard('shard2ReplSet/shard2:27020'); sh.enableSharding('somedb'); sh.shardCollection('somedb.helloDoc', { _id: 'hashed' })"

# 5. Заполнить коллекцию ≥ 1000 документов
docker compose exec mongos mongosh --port 27017 somedb --eval "for (let i = 0; i < 1500; i++) { db.helloDoc.insertOne({ age: i, name: 'ly' + i }) }"
```

### 🐧 Linux / macOS (bash)

```bash
# 1. Инициализировать config сервер
docker compose exec -T configsvr mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [{ _id: 0, host: "configsvr:27019" }]
})
EOF

# 2. Инициализировать shard1
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id: "shard1ReplSet",
  members: [{ _id: 0, host: "shard1:27018" }]
})
EOF

# 3. Инициализировать shard2
docker compose exec -T shard2 mongosh --port 27020 --quiet <<EOF
rs.initiate({
  _id: "shard2ReplSet",
  members: [{ _id: 0, host: "shard2:27020" }]
})
EOF

# 4. Добавить шарды и включить шардирование
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
sh.addShard("shard1ReplSet/shard1:27018")
sh.addShard("shard2ReplSet/shard2:27020")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", { _id: "hashed" })
EOF

# 5. Заполнить коллекцию ≥ 1000 документов
docker compose exec -T mongos mongosh --port 27017 somedb --quiet <<EOF
for (let i = 0; i < 1500; i++) {
  db.helloDoc.insertOne({ age: i, name: "ly" + i })
}
EOF
```



## ✅ Проверка результатов

```bash
# Общее количество документов (mongos)
docker compose exec mongos mongosh --port 27017 somedb --eval "db.helloDoc.countDocuments()"

# Количество документов в shard1
docker compose exec shard1 mongosh --port 27018 somedb --eval "db.helloDoc.countDocuments()"

# Количество документов в shard2
docker compose exec shard2 mongosh --port 27020 somedb --eval "db.helloDoc.countDocuments()"
```
