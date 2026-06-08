# SGB Backend - Sistema de Gestión de Básquet

Backend para el sistema de gestión de liga de básquet con Redis y PostgreSQL.

## 📦 Instalación

### 1. Instalar dependencias

```bash
cd backend
npm install
```

Esto instalará:
- **redis**: Cliente oficial de Redis para Node.js
- **express**: Framework web
- **pg**: Driver PostgreSQL
- **dotenv**: Gestión de variables de entorno
- **nodemon**: (dev) Reinicio automático durante desarrollo

## 🚀 Configurar Redis

### Opción A: Redis Local (Recomendado para desarrollo)

#### En Windows con WSL2 (Recomendado):

```bash
# 1. Abre WSL2
wsl

# 2. Instala Redis
sudo apt-get update
sudo apt-get install redis-server

# 3. Inicia el servidor
sudo service redis-server start

# 4. Verifica que está corriendo
redis-cli ping
# Respuesta esperada: PONG
```

#### En Windows sin WSL2 (Memurai):

1. Descarga [Memurai for Redis](https://www.memurai.com/)
2. Instala siguiendo el wizard
3. Redis se ejecutará como servicio de Windows automáticamente
4. Verifica con: `redis-cli ping`

#### Con Docker:

```bash
# Inicia un contenedor de Redis
docker run -d -p 6379:6379 --name redis-sgb redis:latest

# Verifica
docker exec redis-sgb redis-cli ping
```

### Opción B: Redis en la Nube

#### Redis Cloud (Recomendado para producción):

1. Crea una cuenta en [redis.com/cloud](https://redis.com/try-free/)
2. Crea una base de datos gratuita
3. Copia la URL de conexión (ej: `redis://default:password@host:port`)
4. Configura en `.env`:

```env
REDIS_URL=redis://default:tu_password@host:port
```

#### Alternativas:
- **Upstash**: `upstash.com` (gratuito, con REST API)
- **Azure Cache for Redis**: Cache gestionado en Azure
- **AWS ElastiCache**: Cache gestionado en AWS

## ⚙️ Configuración

### 1. Crear archivo `.env`

```bash
cp .env.example .env
```

### 2. Configurar variables (si usas Redis local):

```env
# Redis Local
REDIS_HOST=localhost
REDIS_PORT=6379

# O Redis Cloud:
REDIS_URL=redis://default:tu_password@host:port
```

## 🔌 Usar Redis en tu código

### Importar el módulo de conexión:

```javascript
import { connectRedis, getRedisClient, disconnectRedis } from './config/redis.js';

// En tu archivo principal (main/server):
await connectRedis();
const redis = getRedisClient();

// Usar Redis
await redis.set('key', 'value');
const value = await redis.get('key');
```

### Ejemplos de uso:

```javascript
import { getRedisClient } from './config/redis.js';

const redis = getRedisClient();

// SET y GET
await redis.set('user:1:name', 'Juan Pérez');
const name = await redis.get('user:1:name');

// HSET y HGETALL (Objetos)
await redis.hSet('user:1', {
  name: 'Juan Pérez',
  email: 'juan@example.com'
});
const user = await redis.hGetAll('user:1');

// INCR (Contadores)
const visitCount = await redis.incr('page:visits');

// LPUSH y LRANGE (Listas)
await redis.lPush('queue:tasks', 'task1', 'task2');
const tasks = await redis.lRange('queue:tasks', 0, -1);

// SADD y SMEMBERS (Conjuntos)
await redis.sAdd('teams:tournament:1', 'team:1', 'team:2');
const teams = await redis.sMembers('teams:tournament:1');

// ZADD y ZRANGE (Conjuntos ordenados - rankings)
await redis.zAdd('ranking:players', [
  { score: 150, member: 'player:1' },
  { score: 200, member: 'player:2' }
]);
const ranking = await redis.zRange('ranking:players', 0, -1, { withScores: true });

// EXPIRE (Expiración)
await redis.set('session:abc123', 'data', { EX: 3600 }); // Expira en 1 hora
const ttl = await redis.ttl('session:abc123');
```

## 🧪 Ejecutar la aplicación

### Desarrollo (con nodemon):
```bash
npm run dev
```

### Producción:
```bash
npm start
```

### Esperado:
```
🚀 Iniciando SGB Backend...

✅ Redis: Conectado correctamente
✅ Redis: Cliente listo para usar
✅ Redis: Ping satisfactorio

📝 SET: app:version = 1.0.0
📖 GET: app:version = 1.0.0
...
✅ SGB Backend está listo para ser usado
```

## 🔧 Monitoreo y Debugging

### Monitorear Redis en tiempo real:

```bash
# En otra terminal
redis-cli

# Comandos útiles
> PING
> KEYS *              # Ver todas las claves
> GET key_name        # Ver valor de una clave
> DBsize              # Número de claves
> MONITOR             # Ver comandos en tiempo real
> FLUSHDB             # Limpiar base de datos (⚠️ cuidado)
> INFO                # Información del servidor
```

### Debugging de conexión:

```bash
# Prueba conexión directa
redis-cli -h localhost -p 6379 ping

# Con URL (si usas Redis Cloud)
redis-cli -u redis://default:password@host:port ping
```

## 📋 Estructura del proyecto

```
backend/
├── src/
│   ├── config/
│   │   └── redis.js          # Módulo de conexión Redis
│   └── index.js              # Servidor principal
├── package.json
├── .env.example
└── README.md
```

## 📚 Recursos

- [Redis Documentation](https://redis.io/commands/)
- [Node.js Redis Client](https://github.com/redis/node-redis)
- [Redis Best Practices](https://redis.io/docs/management/optimization/eviction-policies/)

## ⚠️ Notas importantes

- **Seguridad**: En producción, usa REDIS_PASSWORD y HTTPS/TLS
- **Persistencia**: Redis en memoria; configura snapshots en producción
- **Backup**: Realiza backups regulares de datos críticos
- **Monitoreo**: Usa herramientas como RedisInsight para monitorear en tiempo real

## 🤝 Contribuir

Este módulo está listo para ser expandido con:
- Helpers para operaciones comunes
- Caché de sesiones
- Rate limiting
- Pub/Sub para comunicación en tiempo real
