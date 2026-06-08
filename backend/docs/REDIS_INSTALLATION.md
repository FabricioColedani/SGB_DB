# Instalación de Redis

Este documento explica cómo instalar y ejecutar Redis en Windows.

## 🪟 Opción 1: Redis con WSL2 (Recomendado - Linux en Windows)

### Requisitos previos:
- Windows 10/11 con WSL2 habilitado
- Distribución Linux instalada (Ubuntu, Debian, etc.)

### Pasos:

#### 1. Abre PowerShell como Administrador y habilita WSL2:

```powershell
# Habilitar WSL
wsl --install

# O si ya lo tienes, actualiza:
wsl --update
```

#### 2. Abre la terminal de WSL (Ubuntu):

```bash
# En PowerShell
wsl

# O desde el menu Inicio > Ubuntu
```

#### 3. Instala Redis en Linux:

```bash
# Actualizar paquetes
sudo apt-get update

# Instalar Redis
sudo apt-get install redis-server -y

# Verificar instalación
redis-cli --version
# Output: redis-cli 6.x.x (o versión actual)
```

#### 4. Inicia el servidor Redis:

```bash
# Opción A: Iniciar como servicio
sudo service redis-server start

# Opción B: Iniciar en primer plano
redis-server

# Opción C: Iniciar con archivo de configuración personalizado
redis-server /etc/redis/redis.conf
```

#### 5. Verifica que está funcionando:

```bash
# En otra terminal WSL
redis-cli ping
# Respuesta esperada: PONG

# Ver información del servidor
redis-cli info server
```

#### 6. Detener Redis:

```bash
# Si está en primer plano: Ctrl+C
# Si es un servicio:
sudo service redis-server stop

# Ver estado
sudo service redis-server status
```

---

## 🔧 Opción 2: Memurai para Redis (Windows nativo)

Memurai es una versión de Redis compilada para Windows por Microsoft.

### Pasos:

#### 1. Descarga Memurai:

Visita: [https://www.memurai.com/](https://www.memurai.com/)

- Descarga la versión más reciente (últimamente está abandonado, pero sigue siendo funcional)

#### 2. Instala Memurai:

```
1. Ejecuta el instalador (.msi)
2. Sigue el asistente de instalación
3. Selecciona "Install as a service" (Instalar como servicio)
4. Completa la instalación
```

#### 3. Verifica que Redis está corriendo:

```powershell
# En PowerShell
redis-cli ping
# Respuesta esperada: PONG

# Ver información
redis-cli info server
```

#### 4. Gestionar el servicio:

```powershell
# Ver estado del servicio
Get-Service memurai

# Detener el servicio
Stop-Service memurai

# Iniciar el servicio
Start-Service memurai

# Reiniciar el servicio
Restart-Service memurai

# Deshabilitar inicio automático
Set-Service memurai -StartupType Disabled

# Habilitar inicio automático
Set-Service memurai -StartupType Automatic
```

---

## 🐳 Opción 3: Redis con Docker (Recomendado para producción)

### Requisitos previos:
- Docker Desktop instalado

### Pasos:

#### 1. Abre PowerShell o CMD:

```powershell
# Descargar la imagen de Redis
docker pull redis:latest

# Verificar que se descargó
docker images redis
```

#### 2. Crea un contenedor de Redis:

```powershell
# Iniciar Redis en un contenedor
docker run -d `
  --name redis-sgb `
  -p 6379:6379 `
  -v redis_data:/data `
  redis:latest redis-server --appendonly yes

# Explicación:
# -d: Ejecutar en segundo plano
# --name: Nombre del contenedor
# -p: Mapear puerto (host:contenedor)
# -v: Volumen persistente
# --appendonly yes: Guardar datos en disco
```

#### 3. Verifica el contenedor:

```powershell
# Ver contenedores corriendo
docker ps

# Ver logs del contenedor
docker logs redis-sgb

# Conectarse al contenedor
docker exec -it redis-sgb redis-cli

# Dentro del contenedor:
> PING
PONG
> INFO server
...
> EXIT
```

#### 4. Gestionar el contenedor:

```powershell
# Detener el contenedor
docker stop redis-sgb

# Iniciar el contenedor (persiste los datos)
docker start redis-sgb

# Eliminar el contenedor
docker rm redis-sgb

# Ver volumen de datos
docker volume ls
docker volume inspect redis_data
```

---

## ☁️ Opción 4: Redis en la Nube (Recomendado para producción)

### Redis Cloud (Gratuito + Paid)

1. Crea una cuenta en [https://redis.com/try-free/](https://redis.com/try-free/)
2. Crea una base de datos gratuita
3. Copia la URL de conexión: `redis://default:password@host:port`
4. En tu `.env`:

```env
REDIS_URL=redis://default:tu_password@host:port
```

### Otras opciones en la nube:

- **Upstash**: https://upstash.com (Gratuito con REST API)
- **Azure Cache for Redis**: https://azure.microsoft.com/en-us/products/cache/
- **AWS ElastiCache**: https://aws.amazon.com/elasticache/
- **Google Cloud Memorystore**: https://cloud.google.com/memorystore

---

## 🔐 Configuración Avanzada

### Archivo de configuración (redis.conf):

En WSL o Linux, edita `/etc/redis/redis.conf`:

```bash
sudo nano /etc/redis/redis.conf
```

Configuraciones importantes:

```conf
# Puerto
port 6379

# Contraseña (seguridad)
requirepass tu_contraseña_fuerte

# Dirección de escucha
bind 127.0.0.1

# Persistencia
save 900 1          # Guardar cada 15 min si hay 1 cambio
save 300 10         # Guardar cada 5 min si hay 10 cambios
appendonly yes      # Activar AOF (más seguro)

# Memoria máxima
maxmemory 256mb
maxmemory-policy allkeys-lru  # Política de evicción
```

Después de editar, reinicia:

```bash
sudo service redis-server restart
```

---

## 🧪 Testing de Conexión

### Desde Node.js:

```bash
cd backend
npm run dev
```

### Desde CLI:

```bash
# Conexión local
redis-cli

# Conexión remota (con autenticación)
redis-cli -u redis://default:password@host:port

# Dentro del CLI:
> PING
PONG
> SET mykey "Hello"
OK
> GET mykey
"Hello"
> KEYS *
1) "mykey"
> FLUSHDB
OK
```

---

## 🐛 Troubleshooting

### Error: `redis-cli: command not found`

**En Windows:**
- Verifica que Memurai está instalado
- Agrega `C:\Program Files\Memurai` a PATH

**En WSL:**
```bash
sudo apt-get install redis-tools
```

### Error: `Connection refused`

```bash
# Verifica que Redis está corriendo
ps aux | grep redis

# Si no está, inicia:
redis-server

# O como servicio:
sudo service redis-server start
```

### Error: `WRONGPASS invalid username-password pair`

```bash
# La contraseña es incorrecta
# Edita redis.conf y descomenta:
# requirepass mypassword

# O conéctate sin contraseña:
redis-cli -n 0
```

### Port 6379 already in use

```bash
# En Windows:
netstat -ano | findstr :6379

# En Linux/WSL:
lsof -i :6379

# Mata el proceso:
# Windows: taskkill /PID <PID> /F
# Linux: kill -9 <PID>
```

---

## 📊 Monitoreo

### Redis CLI Monitor:

```bash
redis-cli

# Ver comandos en tiempo real
> MONITOR

# Presiona Ctrl+C para salir
```

### RedisInsight (UI visual):

1. Descarga desde: https://redis.com/redis-enterprise/redisinsight/
2. Abre la aplicación
3. Agrega tu instancia de Redis (localhost:6379)
4. Visualiza datos, claves, rendimiento, etc.

---

## 🎯 Recomendaciones

| Caso de Uso | Opción |
|-------------|--------|
| Desarrollo local | WSL2 + Redis-server |
| Quick start | Docker |
| Producción | Redis Cloud o AWS |
| Testing | Docker (temporalmente) |

---

## 📚 Recursos

- Documentación Redis: https://redis.io/docs/
- Node.js Redis Client: https://github.com/redis/node-redis
- Redis CLI Commands: https://redis.io/commands/
- RedisInsight: https://redis.com/redis-enterprise/redisinsight/
