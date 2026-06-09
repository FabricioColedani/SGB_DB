/**
 * Ejemplo de servidor Express con Redis integrado
 * Demuestra cómo usar los middlewares y el cliente de Redis
 */

import express from 'express';
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

const app = express();
const PORT = process.env.PORT || 3000;
const BENJA_CACHE_TTL = 120; // TTL recomendado por análisis: 60-120 segundos

// ========== CONFIGURACIÓN DE MIDDLEWARES ==========

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

// ========== RUTAS DE PRUEBA ==========

/**
 * GET /health
 * Verifica que Redis está conectado
 */
app.get('/health', async (req, res) => {
  try {
    const redis = req.redis;
    const pong = await redis.ping();
    res.json({
      status: 'ok',
      redis: pong === 'PONG' ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
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
