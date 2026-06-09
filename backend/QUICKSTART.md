# 🚀 INICIO RÁPIDO - SGB Backend con Redis

## Resumen de lo instalado

✅ **Cliente oficial de Redis** (`redis@4.6.14`)  
✅ **Módulo de conexión** (`src/config/redis.js`)  
✅ **Helpers y utilidades** (`src/utils/redisHelpers.js`)  
✅ **Middlewares para Express** (`src/middleware/redisMiddleware.js`)  
✅ **Ejemplos de uso** (`examples/redisExamples.js`)  
✅ **Servidor Express de prueba** (`src/serverExample.js`)  
✅ **Documentación completa** (`docs/REDIS_INSTALLATION.md`)  

---

## 📝 Paso 1: Instalar Redis en tu máquina

### Opción A: WSL2 + Linux (Recomendado)

```powershell
# En PowerShell, abre WSL
wsl

# En WSL (Ubuntu), ejecuta:
sudo apt-get update
sudo apt-get install redis-server -y
sudo service redis-server start

# Verifica
redis-cli ping
# Respuesta: PONG
```

### Opción B: Memurai (Windows nativo)

1. Descarga de: https://www.memurai.com/
2. Instala normalmente (se ejecutará como servicio)
3. Verifica: `redis-cli ping` en PowerShell

### Opción C: Docker

```powershell
docker run -d -p 6379:6379 --name redis-sgb redis:latest
```

Lee `docs/REDIS_INSTALLATION.md` para más opciones.

---

## ⚙️ Paso 2: Configurar variables de entorno

```bash
cd backend

# Si no existe .env, se creó automáticamente
# Si deseas cambiar la configuración, edita:
cat .env

# Para cambios, edita el archivo:
# REDIS_HOST=localhost
# REDIS_PORT=6379
```

---

## 🧪 Paso 3: Ejecutar ejemplos

### Ejecutar ejemplos básicos:

```bash
cd backend
node examples/redisExamples.js
```

Verás output como:

```
========== EJEMPLOS DE USO DE REDIS ==========

✅ Redis: Conectado correctamente
✅ Redis: Cliente listo para usar
✅ Redis: Ping satisfactorio

📝 OPERACIONES CON STRINGS (Cadenas)
---
  SET user:1:name = "Juan Pérez"
  GET user:1:name = "Juan Pérez"
...
========== FIN DE EJEMPLOS ==========
```

---

## 🔌 Paso 4: Usar Redis en tu código

### Opción 1: Uso básico

```javascript
import { connectRedis, getRedisClient, disconnectRedis } from './config/redis.js';

// Conectar
await connectRedis();
const redis = getRedisClient();

// Usar
await redis.set('mykey', 'myvalue');
const value = await redis.get('mykey');

// Desconectar
await disconnectRedis();
```

### Opción 2: Usar helpers

```javascript
import { 
  connectRedis, 
  getRedisClient 
} from './config/redis.js';

import {
  createKey,
  safeGet,
  safeSet,
  increment,
  setHash,
  getHash,
  getSortedSet,
  addSortedSet
} from './utils/redisHelpers.js';

await connectRedis();

// Strings
await safeSet('user:1:name', 'Juan Pérez', 3600); // Con TTL
const name = await safeGet('user:1:name');

// Objetos
await setHash('player:1', { name: 'Juan', number: '10' });
const player = await getHash('player:1');

// Ranking
await addSortedSet('ranking:points', [
  { score: 150, member: 'player:1' },
  { score: 200, member: 'player:2' }
]);
const ranking = await getSortedSet('ranking:points', 0, 9);
```

### Opción 3: Con Express y middlewares

```javascript
import express from 'express';
import { connectRedis } from './config/redis.js';
import { 
  redisMiddleware, 
  cacheMiddleware,
  rateLimitMiddleware
} from './middleware/redisMiddleware.js';

const app = express();

app.use(redisMiddleware);  // Inyecta req.redis
app.use(rateLimitMiddleware(100, 60)); // Rate limit

// Ahora puedes usar req.redis en rutas
app.get('/api/data', cacheMiddleware(3600), (req, res) => {
  const redis = req.redis;
  // ... usar redis
});

await connectRedis();
app.listen(3000);
```

---

## 🌐 Paso 5: Probar servidor Express

```bash
# Opción 1: Ejecutar servidor de ejemplo
node src/serverExample.js

# Opción 2: Modo desarrollo con nodemon
npm run dev

# Opción 3: Producción
npm start
```

Verás:

```
🚀 Iniciando servidor Express con Redis...

✅ Redis: Conectado correctamente
✅ Redis: Cliente listo para usar
✅ Redis: Ping satisfactorio

✅ Servidor corriendo en http://localhost:3000

📚 Rutas disponibles:
   GET  /health              - Verificar estado
   GET  /cache-test          - Probar cacheo
   GET  /counter             - Incrementar contador
   POST /player/:id          - Crear jugador
   ...
```

---

## 🧪 Prueba las rutas

### En otra terminal (PowerShell, cmd o bash):

```bash
# Verificar conexión
curl http://localhost:3000/health

# Probar cacheo
curl http://localhost:3000/cache-test

# Incrementar contador
curl http://localhost:3000/counter

# Crear jugador
curl -X POST http://localhost:3000/player/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Juan Pérez","number":"10","position":"Base","team":"Lakers"}'

# Obtener jugador
curl http://localhost:3000/player/1

# Agregar puntos al ranking
curl -X POST http://localhost:3000/ranking/player \
  -H "Content-Type: application/json" \
  -d '{"playerId":"player:1","score":150}'

# Ver ranking
curl http://localhost:3000/ranking
```

---

## 📚 Estructura del backend

```
backend/
├── src/
│   ├── config/
│   │   └── redis.js              ← Módulo de conexión (IMPORTAR AQUÍ)
│   ├── middleware/
│   │   └── redisMiddleware.js    ← Middlewares Express
│   ├── utils/
│   │   └── redisHelpers.js       ← Funciones auxiliares
│   ├── index.js                  ← Servidor principal
│   └── serverExample.js          ← Ejemplo con Express
├── examples/
│   └── redisExamples.js          ← Ejemplos de operaciones
├── docs/
│   └── REDIS_INSTALLATION.md    ← Guía de instalación
├── package.json
├── .env                          ← Configuración local
├── .env.example                  ← Plantilla de configuración
├── .gitignore
└── README.md
```

---

## 🔑 Importar Redis en otros archivos

### Para obtener el cliente:

```javascript
// En cualquier archivo del backend
import { getRedisClient } from './config/redis.js';
import { connectRedis } from './config/redis.js';

// En tu archivo principal (main/server):
await connectRedis();

// En funciones/rutas:
const redis = getRedisClient();
await redis.set('key', 'value');
```

### Para usar helpers:

```javascript
import { 
  safeGet, 
  safeSet, 
  increment,
  setHash,
  getHash,
  getSortedSet,
  addSortedSet
} from './utils/redisHelpers.js';

// Usar directamente
await safeSet('mykey', 'myvalue');
const value = await safeGet('mykey');
```

---

## 🔧 Comandos útiles

```bash
# Ver logs de Redis en tiempo real
redis-cli MONITOR

# Ver todas las claves
redis-cli KEYS *

# Obtener una clave
redis-cli GET mykey

# Ver información del servidor
redis-cli INFO server

# Limpiar toda la base de datos (⚠️ cuidado)
redis-cli FLUSHDB

# Conectarse a Redis interactivamente
redis-cli
```

---

## 📊 Monitoreo en tiempo real

### RedisInsight (UI visual):

1. Descarga desde: https://redis.com/redis-enterprise/redisinsight/
2. Abre la aplicación
3. Conéctate a `localhost:6379`
4. Visualiza claves, valores, rendimiento, etc.

---

## 🎯 Próximos pasos

1. **Integrar con PostgreSQL**: Importa el cliente PG junto con Redis
2. **Implementar caché de sesiones**: Usa `sessionMiddleware` en tu servidor
3. **Rate limiting**: Protege tus rutas con `rateLimitMiddleware`
4. **Pub/Sub**: Usa Redis para comunicación en tiempo real
5. **Jobs asincronos**: Implementa una cola de trabajos con Redis

---

## ⚠️ Notas de seguridad

En **producción**:
- ✅ Usa contraseña en Redis (`.env` con `REDIS_PASSWORD`)
- ✅ No expongas Redis directamente a internet
- ✅ Usa conexión cifrada (TLS)
- ✅ Monitorea el uso de memoria
- ✅ Configura respaldos/snapshots

---

## 🆘 Troubleshooting

### Redis no se conecta

```bash
# 1. Verifica que Redis está corriendo
redis-cli ping
# Deberías ver: PONG

# 2. Si no, inicia Redis
# En WSL:
sudo service redis-server start

# En Windows (Memurai):
net start memurai

# 3. Verifica el puerto
netstat -ano | findstr :6379
```

### Error: "Redis client not available"

```javascript
// Asegúrate de llamar a connectRedis ANTES de usar getRedisClient()
await connectRedis(); // ← Añade esta línea
const redis = getRedisClient();
```

### Error: "WRONGPASS"

- Edita `.env` y verifica `REDIS_PASSWORD`
- O crea una redis sin contraseña para desarrollo

---

## 📞 Recursos

- [Redis Docs](https://redis.io/docs/)
- [Node.js Redis Client](https://github.com/redis/node-redis)
- [Redis CLI Commands](https://redis.io/commands/)

---

## ✨ ¡Listo!

El módulo de Redis está completamente instalado y listo para usar. 

**Todos en el equipo pueden importar:**

```javascript
import { connectRedis, getRedisClient } from './config/redis.js';
```

**¡A codificar!** 🚀
