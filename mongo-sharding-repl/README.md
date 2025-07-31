# 🛠 Настройка MongoDB с шардированием и репликацией

В этом проекте реализуется MongoDB-шардирование с репликацией. Каждый шард имеет 3 реплики (1 primary + 2 secondary) для обеспечения высокой доступности и отказоустойчивости.

## 🧩 Схема компонентов

### Конфигурационный сервер
* `configsvr` — конфигурационный сервер (порт `27019`)

### Шард 1 (3 реплики)
* `shard1` — primary (порт `27018`)
* `shard1-secondary1` — secondary 1 (порт `27028`)
* `shard1-secondary2` — secondary 2 (порт `27038`)

### Шард 2 (3 реплики)
* `shard2` — primary (порт `27020`)
* `shard2-secondary1` — secondary 1 (порт `27030`)
* `shard2-secondary2` — secondary 2 (порт `27040`)

### Маршрутизатор
* `mongos` — маршрутизатор (порт `27017`)

### База данных
* База данных: `somedb`
* Коллекция: `helloDoc`

## 🚀 Шаги инициализации кластера

### 💻 Windows PowerShell

```powershell
# 1. Инициализировать config сервер
docker compose exec configsvr mongosh --port 27019 --eval "rs.initiate({ _id: 'configReplSet', configsvr: true, members: [{ _id: 0, host: 'configsvr:27019' }] })"

# 2. Инициализировать shard1 replica set (3 реплики)
docker compose exec shard1 mongosh --port 27018 --eval "rs.initiate({ _id: 'shard1ReplSet', members: [{ _id: 0, host: 'shard1:27018' }, { _id: 1, host: 'shard1-secondary1:27028' }, { _id: 2, host: 'shard1-secondary2:27038' }] })"

# 3. Инициализировать shard2 replica set (3 реплики)
docker compose exec shard2 mongosh --port 27020 --eval "rs.initiate({ _id: 'shard2ReplSet', members: [{ _id: 0, host: 'shard2:27020' }, { _id: 1, host: 'shard2-secondary1:27030' }, { _id: 2, host: 'shard2-secondary2:27040' }] })"

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

# 2. Инициализировать shard1 replica set (3 реплики)
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id: "shard1ReplSet",
  members: [
    { _id: 0, host: "shard1:27018" },
    { _id: 1, host: "shard1-secondary1:27028" },
    { _id: 2, host: "shard1-secondary2:27038" }
  ]
})
EOF

# 3. Инициализировать shard2 replica set (3 реплики)
docker compose exec -T shard2 mongosh --port 27020 --quiet <<EOF
rs.initiate({
  _id: "shard2ReplSet",
  members: [
    { _id: 0, host: "shard2:27020" },
    { _id: 1, host: "shard2-secondary1:27030" },
    { _id: 2, host: "shard2-secondary2:27040" }
  ]
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

### Общее количество документов
```bash
# Через mongos (общее количество)
docker compose exec mongos mongosh --port 27017 somedb --eval "db.helloDoc.countDocuments()"
```

### Количество документов в шардах
```bash
# Shard1 Primary
docker compose exec shard1 mongosh --port 27018 somedb --eval "db.helloDoc.countDocuments()"

# Shard2 Primary
docker compose exec shard2 mongosh --port 27020 somedb --eval "db.helloDoc.countDocuments()"
```

### Проверка репликации
```bash
# Статус репликации shard1
docker compose exec shard1 mongosh --port 27018 --eval "rs.status()"

# Статус репликации shard2
docker compose exec shard2 mongosh --port 27020 --eval "rs.status()"

# Количество реплик в shard1
docker compose exec shard1 mongosh --port 27018 --eval "rs.status().members.length"

# Количество реплик в shard2
docker compose exec shard2 mongosh --port 27020 --eval "rs.status().members.length"
```

### Проверка через API
```bash
# Общее количество документов через API
curl http://localhost:8000/
```

## 🔍 Ожидаемые результаты

После выполнения всех команд:
- **Общее количество документов**: ≥ 1000 (1500)
- **Количество документов в shard1**: ~750
- **Количество документов в shard2**: ~750
- **Количество реплик в shard1**: 3
- **Количество реплик в shard2**: 3
- **API работает**: `http://localhost:8000/` возвращает информацию о базе данных
