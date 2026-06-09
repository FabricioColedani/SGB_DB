# Redis Cheat Sheet - Referencia Rápida

## 🔧 Conexión desde Node.js

```javascript
import { connectRedis, getRedisClient, disconnectRedis } from './config/redis.js';

// Conectar
await connectRedis();
const redis = getRedisClient();

// Usar Redis...

// Desconectar
await disconnectRedis();
```

---

## 📝 Strings (Cadenas)

```javascript
// SET y GET
await redis.set('name', 'Juan');
const name = await redis.get('name');

// SET con expiración (segundos)
await redis.set('temp', 'value', { EX: 3600 });

// INCR y DECR
await redis.incr('counter');        // +1
await redis.incrBy('counter', 5);   // +5
await redis.decr('counter');        // -1
await redis.decrBy('counter', 3);   // -3

// APPEND
await redis.append('name', ' Pérez'); // 'Juan Pérez'

// STRLEN
const len = await redis.strlen('name'); // 10

// GETRANGE
const sub = await redis.getRange('name', 0, 3); // 'Juan'

// MSET y MGET (múltiples)
await redis.mSet({ key1: 'val1', key2: 'val2' });
const vals = await redis.mGet(['key1', 'key2']);
```

---

## 🔤 Hashes (Objetos)

```javascript
// HSET
await redis.hSet('user:1', { name: 'Juan', age: 30 });

// HGET
const name = await redis.hGet('user:1', 'name');

// HGETALL
const user = await redis.hGetAll('user:1');

// HMGET
const fields = await redis.hmGet('user:1', ['name', 'age']);

// HDEL
await redis.hDel('user:1', 'age');

// HEXISTS
const exists = await redis.hExists('user:1', 'name'); // true/false

// HKEYS y HVALS
const keys = await redis.hKeys('user:1');   // ['name', 'age']
const vals = await redis.hVals('user:1');   // ['Juan', 30]

// HLEN
const count = await redis.hLen('user:1'); // 2

// HINCRBY
await redis.hIncrBy('user:1', 'age', 1); // age: 31
```

---

## 📋 Lists (Listas/Colas)

```javascript
// LPUSH y RPUSH
await redis.lPush('queue', 'task1', 'task2'); // Agregar al inicio
await redis.rPush('queue', 'task3');          // Agregar al final

// LPOP y RPOP
const first = await redis.lPop('queue');  // Quitar del inicio
const last = await redis.rPop('queue');   // Quitar del final

// LRANGE
const tasks = await redis.lRange('queue', 0, -1); // Todos

// LLEN
const count = await redis.lLen('queue'); // Número de elementos

// LINDEX
const task = await redis.lIndex('queue', 0); // Elemento en posición 0

// LSET
await redis.lSet('queue', 0, 'newTask');

// LTRIM
await redis.lTrim('queue', 0, 9); // Mantener solo primeros 10

// LREM
await redis.lRem('queue', 1, 'task1'); // Quitar 1 ocurrencia de 'task1'
```

---

## 🎯 Sets (Conjuntos únicos)

```javascript
// SADD
await redis.sAdd('tags', 'java', 'python', 'javascript');

// SMEMBERS
const tags = await redis.sMembers('tags');

// SISMEMBER
const hasPython = await redis.sIsMember('tags', 'python'); // true/false

// SCARD
const count = await redis.sCard('tags'); // 3

// SREM
await redis.sRem('tags', 'python');

// SPOP (quitar uno al azar)
const random = await redis.sPop('tags');

// SRANDMEMBER (obtener sin quitar)
const randomTag = await redis.sRandMember('tags');

// Operaciones de sets
const common = await redis.sInter('set1', 'set2');     // Intersección
const union = await redis.sUnion('set1', 'set2');      // Unión
const diff = await redis.sDiff('set1', 'set2');        // Diferencia
```

---

## 🏆 Sorted Sets (Ranking/Puntuación)

```javascript
// ZADD
await redis.zAdd('ranking', [
  { score: 150, member: 'player1' },
  { score: 200, member: 'player2' },
  { score: 175, member: 'player3' }
]);

// ZRANGE (ascendente)
const bottom = await redis.zRange('ranking', 0, 2); // Primeros 3

// ZREVRANGE (descendente - para ranking)
const top = await redis.zRevRange('ranking', 0, 2, { withScores: true });
// [{ member: 'player2', score: 200 }, ...]

// ZCARD
const count = await redis.zCard('ranking'); // 3

// ZSCORE
const score = await redis.zScore('ranking', 'player1'); // 150

// ZRANK (posición ascendente)
const pos = await redis.zRank('ranking', 'player1'); // 0

// ZREVRANK (posición descendente)
const revPos = await redis.zRevRank('ranking', 'player1'); // 2

// ZINCRBY
await redis.zIncrBy('ranking', 10, 'player1'); // player1 score: 160

// ZREM
await redis.zRem('ranking', 'player3');

// ZCOUNT
const inRange = await redis.zCount('ranking', 150, 200); // 2
```

---

## ⏱️ Keys (Claves)

```javascript
// KEYS (buscar patrón)
const keys = await redis.keys('user:*');       // Todas con prefijo
const allKeys = await redis.keys('*');         // Todas las claves

// DEL
await redis.del('key1', 'key2');               // Eliminar múltiples

// EXISTS
const exists = await redis.exists('mykey');    // true/false

// EXPIRE
await redis.expire('mykey', 3600);             // Expirar en 1 hora

// TTL (Time To Live)
const seconds = await redis.ttl('mykey');      // -1 (sin exp), -2 (no existe)

// PTTL (millisegundos)
const ms = await redis.pTtl('mykey');

// PERSIST (quitar expiración)
await redis.persist('mykey');

// RENAME
await redis.rename('oldKey', 'newKey');

// TYPE
const type = await redis.type('mykey');        // 'string', 'hash', 'list', etc.

// SCAN (iterar sin bloquear)
const keys = await redis.scan(0);              // Cursor y keys
```

---

## 🔄 Transacciones

```javascript
// Abrir transacción
const multi = redis.multi();

multi.set('key1', 'val1');
multi.set('key2', 'val2');
multi.incr('counter');

const results = await multi.exec();
```

---

## 🔔 Pub/Sub (Publicar/Suscribirse)

```javascript
import { createClient } from 'redis';

// Suscriptor
const subscriber = createClient();
await subscriber.connect();
await subscriber.subscribe('channel:news', (message) => {
  console.log('Nuevo mensaje:', message);
});

// Publicador
const publisher = createClient();
await publisher.connect();
await publisher.publish('channel:news', 'Hello!');
```

---

## 🔧 Utilidades del servidor

```javascript
// INFO (información del servidor)
const info = await redis.info();

// DBSIZE (número de claves)
const count = await redis.dbSize();

// FLUSHDB (limpiar BD actual - ⚠️ PELIGRO)
await redis.flushDb();

// FLUSHALL (limpiar todo - ⚠️⚠️ PELIGRO)
await redis.flushAll();

// PING
const pong = await redis.ping();

// SAVE (guardar a disco)
await redis.save();

// BGSAVE (guardar en background)
await redis.bgsave();

// LASTSAVE
const timestamp = await redis.lastSave();

// TIME
const [seconds, microseconds] = await redis.time();
```

---

## 🏗️ Con Helpers (Recomendado)

```javascript
import { 
  createKey, 
  safeGet, 
  safeSet, 
  increment,
  setHash,
  getHash,
  pushList,
  getList,
  addSet,
  getSet,
  addSortedSet,
  getSortedSet,
  deleteKeys,
  getKeysByPattern,
  getTTL,
  setExpire,
  flushDatabase,
  getInfo
} from './utils/redisHelpers.js';

// Crear clave con namespace
const key = createKey('user', '1', 'name'); // 'user:1:name'

// GET/SET seguro
await safeSet('user:1:name', 'Juan', 3600);
const name = await safeGet('user:1:name');

// Incrementar
const views = await increment('page:views');

// Hash (objeto)
await setHash('player:1', { name: 'Juan', number: 10 });
const player = await getHash('player:1');

// Lista
await pushList('queue:tasks', 'task1', 'task2');
const tasks = await getList('queue:tasks');

// Conjunto
await addSet('tournament:1:teams', 'team1', 'team2');
const teams = await getSet('tournament:1:teams');

// Ranking
await addSortedSet('ranking:points', [
  { score: 150, member: 'player:1' },
  { score: 200, member: 'player:2' }
]);
const ranking = await getSortedSet('ranking:points', 0, 9);

// Información
const ttl = await getTTL('mykey');
const info = await getInfo();
```

---

## ⚡ Middlewares Express

```javascript
import {
  redisMiddleware,      // Inyecta req.redis
  cacheMiddleware,      // Cachea respuestas GET
  rateLimitMiddleware,  // Limita requests
  sessionMiddleware,    // Manejo de sesiones
  loggingMiddleware     // Registra logs
} from './middleware/redisMiddleware.js';

const app = express();

// Usar middlewares
app.use(loggingMiddleware());
app.use(redisMiddleware);
app.use(rateLimitMiddleware(100, 60)); // 100 req/min
app.use(sessionMiddleware('session-id', 3600));

// En rutas
app.get('/data', cacheMiddleware(3600), (req, res) => {
  req.redis.set('key', 'value');
  const val = req.redis.get('key');
  
  // Sesiones
  await req.session.set('user', 'Juan');
  const user = req.session.get('user');
});
```

---

## 🎯 Patrones comunes

### Caché de resultado

```javascript
const getCachedData = async (id) => {
  const key = createKey('cache', 'data', id);
  
  // Intenta obtener del cache
  const cached = await safeGet(key);
  if (cached) return JSON.parse(cached);
  
  // Si no, obtén de BD y cachea
  const data = await database.getData(id);
  await safeSet(key, data, 3600);
  
  return data;
};
```

### Contador de visitas

```javascript
app.get('/page/:id', async (req, res) => {
  const countKey = createKey('page', req.params.id, 'views');
  const views = await increment(countKey);
  
  res.json({ views });
});
```

### Session storage

```javascript
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  // ... validar
  
  await req.session.set('username', username);
  await req.session.set('userId', user.id);
  
  res.json({ message: 'Logged in' });
});
```

### Rate limiting global

```javascript
app.use(rateLimitMiddleware(1000, 60)); // 1000 req/min
```

### Ranking en tiempo real

```javascript
app.post('/score', async (req, res) => {
  const { playerId, score } = req.body;
  
  await addSortedSet('ranking:live', [
    { score, member: playerId }
  ]);
  
  const top10 = await getSortedSet('ranking:live', 0, 9);
  res.json({ ranking: top10 });
});
```

---

## 💡 Tips

- Usa **prefijos de namespace** para organizar claves
- Establece **TTL** en datos temporales
- Usa **Sorted Sets** para rankings
- Usa **Hashes** para objetos
- Usa **Lists** para colas
- Usa **Sets** para membresía
- Monitorea con **RedisInsight**
- Backups regulares en producción

---

## 📚 Documentación oficial

- https://redis.io/docs/
- https://github.com/redis/node-redis
- https://redis.io/commands/
