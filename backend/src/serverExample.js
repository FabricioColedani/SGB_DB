/**
 * Ejemplo de servidor Express con Redis integrado
 * Demuestra cómo usar los middlewares y el cliente de Redis
 */

import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { connectRedis, disconnectRedis, getRedisClient } from './config/redis.js';
import { query, closeDb } from './config/db.js';
import { 
  redisMiddleware, 
  cacheMiddleware, 
  rateLimitMiddleware,
  sessionMiddleware,
  loggingMiddleware 
} from './middleware/redisMiddleware.js';
import {
  createKey,
  safeGet,
  safeSet,
  cacheAside,
  increment,
  getHash,
  setHash,
  getSortedSet,
  addSortedSet
} from './utils/redisHelpers.js';

import { deleteKeys } from './utils/redisHelpers.js';

const app = express();
const PORT = process.env.PORT || 3000;
const BENJA_CACHE_TTL = 120; // TTL recomendado por análisis: 60-120 segundos

// Flag para simular Redis caído desde el admin UI
app.locals.redisDisabled = false;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicPath = path.resolve(__dirname, '../public');

// ========== CONFIGURACIÓN DE MIDDLEWARES ==========

// Servir frontend estático
app.use(express.static(publicPath));

// Middleware de logging
app.use(loggingMiddleware());

// Middleware de inyección de Redis
app.use(redisMiddleware);

// Middleware de rate limiting: 100 requests por minuto
app.use(rateLimitMiddleware(100, 60));

// Middleware de sesiones
app.use(sessionMiddleware('sgb-session', 3600));

// Parsear JSON
app.use(express.json());

const cacheAsideWithMeta = async (key, loader, ttlSeconds = BENJA_CACHE_TTL) => {
  const startTime = Date.now();
  let redisOnline = true;

  // Allow admin to simulate Redis being offline
  if (app?.locals?.redisDisabled) {
    throw new Error('Redis disabled by admin');
  }

  try {
    const redis = getRedisClient();
    const cached = await redis.get(key);

    if (cached) {
      const data = JSON.parse(cached);
      return {
        data,
        meta: {
          cacheHit: true,
          source: 'Redis',
          durationMs: Date.now() - startTime,
          redisOnline
        }
      };
    }

    const data = await loader();
    await redis.set(key, JSON.stringify(data), { EX: ttlSeconds });
    return {
      data,
      meta: {
        cacheHit: false,
        source: 'PostgreSQL',
        durationMs: Date.now() - startTime,
        redisOnline
      }
    };
  } catch (error) {
    redisOnline = false;
    console.warn(`Redis fallback para ${key}: ${error.message}`);
    if (error.stack) console.debug(error.stack);

    // Fallback: obtener desde la DB y devolver meta indicando Redis offline
    const data = await loader();
    return {
      data,
      meta: {
        cacheHit: false,
        source: 'PostgreSQL',
        durationMs: Date.now() - startTime,
        redisOnline
      }
    };
  }
};

// ========== RUTAS DE PRUEBA ==========

/**
 * GET /api/health
 * Verifica si Redis está conectado y devuelve estado general.
 */
app.get('/api/health', async (req, res) => {
  try {
    const redis = req.redis;
    const pong = await redis.ping();
    res.json({
      status: 'ok',
      redisOnline: pong === 'PONG',
      source: pong === 'PONG' ? 'Redis' : 'PostgreSQL',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.json({
      status: 'ok',
      redisOnline: false,
      source: 'PostgreSQL',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/equipos
 * Retorna equipos con cache Redis.
 */
app.get('/api/equipos', async (req, res) => {
  try {
    const cacheKey = 'equipos:lista';
    const result = await cacheAsideWithMeta(cacheKey, async () => {
      const sql = `
        SELECT id_equipo AS id,
               nombre,
               ciudad,
               tecnico,
               anio_fundacion
        FROM Equipo
        ORDER BY nombre;
      `;
      const response = await query(sql);
      return response.rows;
    }, 86400);

    res.json({
      meta: result.meta,
      data: result.data
    });
  } catch (error) {
    console.error('❌ Error /api/equipos:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/posiciones
 * Tabla de posiciones / clasificación del torneo.
 */
app.get('/api/posiciones', async (req, res) => {
  try {
    const cacheKey = 'posiciones:tabla';
    const result = await cacheAsideWithMeta(cacheKey, async () => {
      const sql = `
        SELECT * FROM (
          SELECT
            e.id_equipo AS id,
            e.nombre,
            e.ciudad,
            COUNT(p.id_partido) FILTER (
              WHERE (p.id_equipo_local = e.id_equipo AND p.puntos_local > p.puntos_visitante)
                 OR (p.id_equipo_visitante = e.id_equipo AND p.puntos_visitante > p.puntos_local)
            ) AS victorias,
            COUNT(p.id_partido) FILTER (
              WHERE (p.id_equipo_local = e.id_equipo AND p.puntos_local < p.puntos_visitante)
                 OR (p.id_equipo_visitante = e.id_equipo AND p.puntos_visitante < p.puntos_local)
            ) AS derrotas,
            COALESCE(SUM(CASE
              WHEN p.id_equipo_local = e.id_equipo THEN p.puntos_local
              WHEN p.id_equipo_visitante = e.id_equipo THEN p.puntos_visitante
              ELSE 0 END), 0) AS puntos_anotados,
            COALESCE(SUM(CASE
              WHEN p.id_equipo_local = e.id_equipo THEN p.puntos_visitante
              WHEN p.id_equipo_visitante = e.id_equipo THEN p.puntos_local
              ELSE 0 END), 0) AS puntos_recibidos,
            COALESCE(SUM(CASE
              WHEN (p.id_equipo_local = e.id_equipo AND p.puntos_local > p.puntos_visitante)
                OR (p.id_equipo_visitante = e.id_equipo AND p.puntos_visitante > p.puntos_local) THEN 2
              ELSE 0 END), 0) AS puntos
          FROM Equipo e
          LEFT JOIN Partido p ON p.id_equipo_local = e.id_equipo OR p.id_equipo_visitante = e.id_equipo
          GROUP BY e.id_equipo, e.nombre, e.ciudad
        ) t
        ORDER BY puntos DESC, victorias DESC, (puntos_anotados - puntos_recibidos) DESC;
      `;
      const response = await query(sql);
      return response.rows;
    }, 120);

    res.json({
      meta: result.meta,
      data: result.data
    });
  } catch (error) {
    console.error('❌ Error /api/posiciones:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/estadisticas/maximos-anotadores
 * Retorna Top 10 de máximos anotadores.
 */
app.get('/api/estadisticas/maximos-anotadores', async (req, res) => {
  try {
    const cacheKey = 'estadisticas:maximos-anotadores';
    const result = await cacheAsideWithMeta(cacheKey, async () => {
      const sql = `
        SELECT
          j.id_jugador AS id,
          CONCAT(j.nombre, ' ', j.apellido) AS jugador,
          e.nombre AS equipo,
          COALESCE(SUM(est.puntos), 0) AS puntos_totales,
          COUNT(DISTINCT est.id_partido) AS partidos
        FROM Jugador j
        LEFT JOIN Equipo e ON e.id_equipo = j.id_equipo
        LEFT JOIN Estadistica est ON est.id_jugador = j.id_jugador
        GROUP BY j.id_jugador, j.nombre, j.apellido, e.nombre
        ORDER BY puntos_totales DESC
        LIMIT 10;
      `;
      const response = await query(sql);
      return response.rows;
    }, 120);

    res.json({
      meta: result.meta,
      data: result.data
    });
  } catch (error) {
    console.error('❌ Error /api/estadisticas/maximos-anotadores:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /partidos/resumen
 * Implementa Cache-Aside: primero Redis, luego PostgreSQL, serializa y guarda en Redis con TTL.
 */
app.get('/partidos/resumen', async (req, res) => {
  try {
    const cacheKey = 'partidos:resumen';

    const resumen = await cacheAside(cacheKey, async () => {
      const sql = `
        SELECT p.id_partido AS id,
               p.fecha,
               p.hora,
               p.puntos_local,
               p.puntos_visitante,
               el.nombre AS equipo_local,
               ev.nombre AS equipo_visitante
        FROM partido p
        JOIN equipo el ON p.id_equipo_local = el.id_equipo
        JOIN equipo ev ON p.id_equipo_visitante = ev.id_equipo
        ORDER BY p.fecha DESC
        LIMIT 20
      `;

      const result = await query(sql);
      return result.rows;
    }, BENJA_CACHE_TTL);

    res.json({
      cacheKey,
      ttlSeconds: BENJA_CACHE_TTL,
      data: resumen
    });
  } catch (error) {
    console.error('❌ Error /partidos/resumen:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /cache-test
 * Prueba el cacheo automático de respuestas
 */
app.get('/cache-test', cacheMiddleware(10), async (req, res) => {
  // Esta respuesta se cacheará por 10 segundos
  res.json({
    message: 'Esta respuesta está cacheada',
    timestamp: new Date().toISOString(),
    random: Math.random()
  });
});

/**
 * GET /counter
 * Demuestra uso de contadores en Redis
 */
app.get('/counter', async (req, res) => {
  const key = createKey('stats', 'pageviews');
  const count = await increment(key);
  
  res.json({
    page: 'counter',
    views: count,
    message: 'Contador incrementado'
  });
});

/**
 * POST /player/:id
 * Guarda datos de un jugador
 */
app.post('/player/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, number, position, team } = req.body;

    const playerKey = createKey('player', id);
    
    await setHash(playerKey, {
      name,
      number,
      position,
      team,
      createdAt: new Date().toISOString()
    }, 86400); // Guardar por 24 horas

    res.status(201).json({
      message: 'Jugador guardado',
      id,
      key: playerKey
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /player/:id
 * Obtiene datos de un jugador
 */
app.get('/player/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const playerKey = createKey('player', id);

    const player = await getHash(playerKey);
    
    if (!player || Object.keys(player).length === 0) {
      return res.status(404).json({ message: 'Jugador no encontrado' });
    }

    res.json(player);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /ranking
 * Obtiene ranking de jugadores
 */
app.get('/ranking', async (req, res) => {
  try {
    const rankingKey = createKey('ranking', 'season1', 'points');
    const ranking = await getSortedSet(rankingKey, 0, 9, true);

    if (ranking.length === 0) {
      return res.json({
        message: 'No hay datos en el ranking',
        ranking: []
      });
    }

    res.json({
      season: 'season1',
      topPlayers: ranking
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /ranking/player
 * Agrega puntos a un jugador en el ranking
 */
app.post('/ranking/player', async (req, res) => {
  try {
    const { playerId, score } = req.body;
    
    if (!playerId || typeof score !== 'number') {
      return res.status(400).json({ 
        error: 'playerId y score son requeridos' 
      });
    }

    const rankingKey = createKey('ranking', 'season1', 'points');
    
    await addSortedSet(rankingKey, [
      { score, member: playerId }
    ]);

    const ranking = await getSortedSet(rankingKey, 0, 4, true);

    res.json({
      message: 'Puntos agregados',
      topPlayers: ranking
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /session/set
 * Guarda datos en la sesión
 */
app.get('/session/set/:key/:value', async (req, res) => {
  try {
    const { key, value } = req.params;
    
    await req.session.set(key, value);

    res.json({
      message: 'Dato de sesión guardado',
      key,
      value,
      sessionId: req.sessionId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /session/get/:key
 * Lee datos de la sesión
 */
app.get('/session/get/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const value = req.session.get(key);

    res.json({
      sessionId: req.sessionId,
      key,
      value: value || null,
      allData: req.session.data
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /session/destroy
 * Destruye la sesión
 */
app.get('/session/destroy', async (req, res) => {
  try {
    await req.session.destroy();
    res.json({ message: 'Sesión destruida' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ========== MANEJO DE ERRORES ==========

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  res.status(500).json({ error: error.message || 'Error interno' });
});

// ========== ADMIN ENDPOINTS (TESTING / FALLBACK) ==========

/**
 * POST /admin/cache/flush?key=...
 * Borra una clave del cache (útil para forzar refetch)
 */
app.post('/admin/cache/flush', async (req, res) => {
  try {
    const key = req.query.key;
    if (!key) return res.status(400).json({ error: 'key query param required' });

    const deleted = await deleteKeys(key);
    res.json({ ok: true, deleted });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /admin/redis/disable
 * Simula Redis caído para pruebas de fallback
 */
app.post('/admin/redis/disable', (req, res) => {
  app.locals.redisDisabled = true;
  res.json({ redisDisabled: true });
});

/**
 * POST /admin/redis/enable
 */
app.post('/admin/redis/enable', (req, res) => {
  app.locals.redisDisabled = false;
  res.json({ redisDisabled: false });
});

/**
 * GET /admin/redis/status
 */
app.get('/admin/redis/status', async (req, res) => {
  try {
    const redisDisabled = !!app.locals.redisDisabled;
    const status = { redisDisabled };
    if (!redisDisabled) {
      try {
        const redis = getRedisClient();
        const pong = await redis.ping();
        status.redisPing = pong === 'PONG';
      } catch (e) {
        status.redisPing = false;
        status.redisError = e.message;
      }
    }
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ========== INICIAR SERVIDOR ==========

const startServer = async () => {
  try {
    console.log('\n🚀 Iniciando servidor Express con Redis...\n');

    // Conectar a Redis
    await connectRedis();

    // Iniciar servidor Express
    app.listen(PORT, () => {
      console.log(`✅ Servidor corriendo en http://localhost:${PORT}`);
      console.log('\n📚 Rutas disponibles:');
      console.log(`   GET  /health              - Verificar estado`);
      console.log(`   GET  /partidos/resumen    - Cache-Aside con Redis + PostgreSQL`);
      console.log(`   GET  /cache-test          - Probar cacheo`);
      console.log(`   GET  /counter             - Incrementar contador`);
      console.log(`   POST /player/:id          - Crear jugador`);
      console.log(`   GET  /player/:id          - Obtener jugador`);
      console.log(`   GET  /ranking             - Ver ranking`);
      console.log(`   POST /ranking/player      - Agregar puntos`);
      console.log(`   GET  /session/set/:key/:value - Guardar en sesión`);
      console.log(`   GET  /session/get/:key    - Leer sesión`);
      console.log(`   GET  /session/destroy     - Destruir sesión\n`);
    });
  } catch (error) {
    console.error('❌ Error al iniciar servidor:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n\n🛑 Deteniendo servidor...');
  await disconnectRedis();
  await closeDb();
  process.exit(0);
});

// Iniciar
startServer();
