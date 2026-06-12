/**
 * Ejemplo de servidor Express con Redis integrado
 * Demuestra cómo usar los middlewares y el cliente de Redis
 */

import express from 'express';
import cors from 'cors';
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
  addSortedSet,
  deleteKeys,
  getKeysByPattern,
  flushDatabase
} from './utils/redisHelpers.js';

const app = express();
const PORT = process.env.PORT || 3000;
const BENJA_CACHE_TTL = 120; // TTL recomendado por análisis: 60-120 segundos

const isNonEmptyString = (value) => typeof value === 'string' && value.trim().length > 0;
const parseNullableNumber = (value) => {
  if (value === undefined || value === null || value === '') return null;
  const number = Number(value);
  return Number.isNaN(number) ? null : number;
};

const requireJsonContent = (req, res) => {
  if (!req.is('application/json')) {
    res.status(415).json({ error: 'Content-Type debe ser application/json' });
    return false;
  }
  return true;
};

const deleteKeysByPattern = async (pattern) => {
  try {
    const keys = await getKeysByPattern(pattern);
    if (keys.length === 0) return 0;
    return await deleteKeys(keys);
  } catch (error) {
    console.error(`Error invalidando cache para patrón ${pattern}:`, error.message);
    return 0;
  }
};

const invalidateOldListCaches = async (patterns) => {
  const deletePromises = patterns.map((pattern) => deleteKeysByPattern(pattern));
  await Promise.all(deletePromises);
};

// Flag para simular Redis caído desde el admin UI
app.locals.redisDisabled = false;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicPath = path.resolve(__dirname, '../public');

// ========== CONFIGURACIÓN DE MIDDLEWARES ==========

// Habilitar CORS para que el frontend pueda usar el backend desde cualquier origen
app.use(cors());

// Servir frontend desde backend/public
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
        WHERE activo = true
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
 * POST /api/jugadores
 * Crea un jugador nuevo y borra caches de listas viejas.
 */
app.post('/api/jugadores', async (req, res) => {
  if (!requireJsonContent(req, res)) return;

  try {
    const {
      nombre,
      apellido,
      fechaNacimiento,
      posicion,
      altura,
      peso,
      equipoId
    } = req.body;

    if (!isNonEmptyString(nombre) || !isNonEmptyString(apellido)) {
      return res.status(400).json({ error: 'nombre y apellido son obligatorios' });
    }

    const sql = `
      INSERT INTO Jugador (
        nombre,
        apellido,
        fecha_nacimiento,
        posicion,
        altura,
        peso,
        id_equipo
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING
        id_jugador AS id,
        nombre,
        apellido,
        fecha_nacimiento AS "fechaNacimiento",
        posicion,
        altura,
        peso,
        id_equipo AS "equipoId";
    `;

    const params = [
      nombre.trim(),
      apellido.trim(),
      fechaNacimiento || null,
      posicion ? posicion.trim() : null,
      parseNullableNumber(altura),
      parseNullableNumber(peso),
      equipoId != null ? Number(equipoId) : null
    ];

    const result = await query(sql, params);
    const jugador = result.rows[0];

    await invalidateOldListCaches([
      'equipos:*:jugadores',
      'jugador:*',
      'estadisticas:maximos-anotadores'
    ]);

    res.status(201).json({ data: jugador });
  } catch (error) {
    console.error('❌ Error POST /api/jugadores:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/equipos
 * Crea un equipo nuevo y borra caches de listas viejas.
 */
app.post('/api/equipos', async (req, res) => {
  if (!requireJsonContent(req, res)) return;

  try {
    const { nombre, ciudad, tecnico, anioFundacion } = req.body;

    if (!isNonEmptyString(nombre)) {
      return res.status(400).json({ error: 'nombre es obligatorio para el equipo' });
    }

    const sql = `
      INSERT INTO Equipo (
        nombre,
        ciudad,
        tecnico,
        anio_fundacion
      ) VALUES ($1, $2, $3, $4)
      RETURNING
        id_equipo AS id,
        nombre,
        ciudad,
        tecnico,
        anio_fundacion AS "anioFundacion";
    `;

    const params = [
      nombre.trim(),
      ciudad ? ciudad.trim() : null,
      tecnico ? tecnico.trim() : null,
      parseNullableNumber(anioFundacion)
    ];

    const result = await query(sql, params);
    const equipo = result.rows[0];

    await invalidateOldListCaches([
      'equipos:lista',
      'posiciones:tabla',
      'partidos:resumen'
    ]);

    res.status(201).json({ data: equipo });
  } catch (error) {
    console.error('❌ Error POST /api/equipos:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/partidos
 * Crea un partido nuevo y borra caches de listas viejas.
 */
app.post('/api/partidos', async (req, res) => {
  if (!requireJsonContent(req, res)) return;

  try {
    const {
      fecha,
      hora,
      puntosLocal,
      puntosVisitante,
      equipoLocalId,
      equipoVisitanteId,
      estadioId,
      arbitroId
    } = req.body;

    if (!isNonEmptyString(fecha) || !isNonEmptyString(hora)) {
      return res.status(400).json({ error: 'fecha y hora son obligatorias' });
    }

    const sql = `
      INSERT INTO Partido (
        fecha,
        hora,
        puntos_local,
        puntos_visitante,
        id_equipo_local,
        id_equipo_visitante,
        id_estadio,
        id_arbitro
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING
        id_partido AS id,
        fecha,
        hora,
        puntos_local AS "puntosLocal",
        puntos_visitante AS "puntosVisitante",
        id_equipo_local AS "equipoLocalId",
        id_equipo_visitante AS "equipoVisitanteId",
        id_estadio AS "estadioId",
        id_arbitro AS "arbitroId";
    `;

    const params = [
      fecha,
      hora,
      parseNullableNumber(puntosLocal),
      parseNullableNumber(puntosVisitante),
      equipoLocalId != null ? Number(equipoLocalId) : null,
      equipoVisitanteId != null ? Number(equipoVisitanteId) : null,
      estadioId != null ? Number(estadioId) : null,
      arbitroId != null ? Number(arbitroId) : null
    ];

    const result = await query(sql, params);
    const partido = result.rows[0];

    await invalidateOldListCaches([
      'posiciones:tabla',
      'partidos:resumen',
      'equipos:lista'
    ]);

    res.status(201).json({ data: partido });
  } catch (error) {
    console.error('❌ Error POST /api/partidos:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/jugadores/:id
 * Actualiza campos de un jugador y borra caches relacionadas.
 */
app.patch('/api/jugadores/:id', async (req, res) => {
  if (!requireJsonContent(req, res)) return;

  try {
    const { id } = req.params;
    const allowedFields = {
      nombre: 'nombre',
      apellido: 'apellido',
      fechaNacimiento: 'fecha_nacimiento',
      posicion: 'posicion',
      altura: 'altura',
      peso: 'peso',
      equipoId: 'id_equipo'
    };

    const updates = [];
    const params = [];
    let index = 1;

    for (const [field, column] of Object.entries(allowedFields)) {
      if (req.body[field] !== undefined) {
        updates.push(`${column} = $${index}`);
        const value = field === 'altura' || field === 'peso'
          ? parseNullableNumber(req.body[field])
          : field === 'equipoId'
            ? (req.body[field] != null ? Number(req.body[field]) : null)
            : req.body[field] ? String(req.body[field]).trim() : null;
        params.push(value);
        index += 1;
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No se proporcionaron campos válidos para actualizar' });
    }

    const sql = `
      UPDATE Jugador
      SET ${updates.join(', ')}
      WHERE id_jugador = $${index}
        AND activo = true
      RETURNING
        id_jugador AS id,
        nombre,
        apellido,
        fecha_nacimiento AS "fechaNacimiento",
        posicion,
        altura,
        peso,
        id_equipo AS "equipoId";
    `;

    params.push(Number(id));
    const result = await query(sql, params);
    const jugador = result.rows[0];

    if (!jugador) {
      return res.status(404).json({ error: 'Jugador no encontrado o ya inactivo' });
    }

    await invalidateOldListCaches([
      `jugador:${id}`,
      'equipos:*:jugadores',
      'estadisticas:maximos-anotadores'
    ]);

    res.json({ data: jugador });
  } catch (error) {
    console.error('❌ Error PATCH /api/jugadores/:id:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/partidos/:id
 * Actualiza un partido y elimina cache de posiciones/resumen.
 */
app.patch('/api/partidos/:id', async (req, res) => {
  if (!requireJsonContent(req, res)) return;

  try {
    const { id } = req.params;
    const allowedFields = {
      fecha: 'fecha',
      hora: 'hora',
      puntosLocal: 'puntos_local',
      puntosVisitante: 'puntos_visitante',
      equipoLocalId: 'id_equipo_local',
      equipoVisitanteId: 'id_equipo_visitante',
      estadioId: 'id_estadio',
      arbitroId: 'id_arbitro'
    };

    const updates = [];
    const params = [];
    let index = 1;

    for (const [field, column] of Object.entries(allowedFields)) {
      if (req.body[field] !== undefined) {
        updates.push(`${column} = $${index}`);
        const value = field === 'puntosLocal' || field === 'puntosVisitante'
          ? parseNullableNumber(req.body[field])
          : field === 'equipoLocalId' || field === 'equipoVisitanteId' || field === 'estadioId' || field === 'arbitroId'
            ? (req.body[field] != null ? Number(req.body[field]) : null)
            : String(req.body[field]).trim();
        params.push(value);
        index += 1;
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No se proporcionaron campos válidos para actualizar' });
    }

    const sql = `
      UPDATE Partido
      SET ${updates.join(', ')}
      WHERE id_partido = $${index}
        AND activo = true
      RETURNING
        id_partido AS id,
        fecha,
        hora,
        puntos_local AS "puntosLocal",
        puntos_visitante AS "puntosVisitante",
        id_equipo_local AS "equipoLocalId",
        id_equipo_visitante AS "equipoVisitanteId",
        id_estadio AS "estadioId",
        id_arbitro AS "arbitroId";
    `;

    params.push(Number(id));
    const result = await query(sql, params);
    const partido = result.rows[0];

    if (!partido) {
      return res.status(404).json({ error: 'Partido no encontrado o ya inactivo' });
    }

    await invalidateOldListCaches([
      'posiciones:tabla',
      'partidos:resumen',
      'equipos:lista'
    ]);

    res.json({ data: partido });
  } catch (error) {
    console.error('❌ Error PATCH /api/partidos/:id:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/jugadores/:id
 * Baja lógica de jugador y eliminación selectiva de cache.
 */
app.delete('/api/jugadores/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const sql = `
      UPDATE Jugador
      SET activo = false
      WHERE id_jugador = $1
        AND activo = true
      RETURNING id_jugador AS id, nombre, apellido;
    `;

    const result = await query(sql, [Number(id)]);
    const jugador = result.rows[0];

    if (!jugador) {
      return res.status(404).json({ error: 'Jugador no encontrado o ya inactivo' });
    }

    await invalidateOldListCaches([
      `jugador:${id}`,
      'equipos:*:jugadores',
      'estadisticas:maximos-anotadores'
    ]);

    res.json({ message: 'Jugador dado de baja correctamente', data: jugador });
  } catch (error) {
    console.error('❌ Error DELETE /api/jugadores/:id:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/equipos/:id
 * Baja lógica de equipo y eliminación selectiva de cache.
 */
app.delete('/api/equipos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const sql = `
      UPDATE Equipo
      SET activo = false
      WHERE id_equipo = $1
        AND activo = true
      RETURNING id_equipo AS id, nombre, ciudad;
    `;

    const result = await query(sql, [Number(id)]);
    const equipo = result.rows[0];

    if (!equipo) {
      return res.status(404).json({ error: 'Equipo no encontrado o ya inactivo' });
    }

    await invalidateOldListCaches([
      'equipos:lista',
      'posiciones:tabla',
      'partidos:resumen',
      'equipos:*:jugadores',
      'estadisticas:maximos-anotadores'
    ]);

    res.json({ message: 'Equipo dado de baja correctamente', data: equipo });
  } catch (error) {
    console.error('❌ Error DELETE /api/equipos/:id:', error.message);
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
          LEFT JOIN Partido p ON (p.id_equipo_local = e.id_equipo OR p.id_equipo_visitante = e.id_equipo)
            AND p.activo = true
          WHERE e.activo = true
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
        WHERE j.activo = true
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
        JOIN equipo el ON p.id_equipo_local = el.id_equipo AND el.activo = true
        JOIN equipo ev ON p.id_equipo_visitante = ev.id_equipo AND ev.activo = true
        WHERE p.activo = true
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
 * Obtiene datos de un jugador desde Redis o PostgreSQL si no está cacheado
 */
app.get('/player/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const playerKey = createKey('player', id);

    let player = await getHash(playerKey);

    if (!player || Object.keys(player).length === 0) {
      const sql = `
        SELECT
          j.id_jugador AS id,
          j.nombre,
          j.apellido,
          j.posicion,
          j.fecha_nacimiento AS fechaNacimiento,
          j.altura,
          j.peso,
          j.id_equipo AS equipoId,
          e.nombre AS equipo
        FROM Jugador j
        LEFT JOIN Equipo e ON e.id_equipo = j.id_equipo
        WHERE j.id_jugador = $1;
      `;
      const response = await query(sql, [id]);
      player = response.rows[0] || null;

      if (!player) {
        return res.status(404).json({ message: 'Jugador no encontrado' });
      }

      await setHash(playerKey, {
        id: String(player.id),
        nombre: player.nombre || '',
        apellido: player.apellido || '',
        posicion: player.posicion || '',
        fechaNacimiento: player.fechaNacimiento ? String(player.fechaNacimiento) : '',
        altura: player.altura != null ? String(player.altura) : '',
        peso: player.peso != null ? String(player.peso) : '',
        equipoId: String(player.equipoId || ''),
        equipo: player.equipo || ''
      }, 86400);

      return res.json({ source: 'postgresql', data: player });
    }

    res.json({ source: 'redis', data: player });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /jugador/:id
 * GET /api/jugadores/:id
 * Obtiene datos de un jugador por ID desde PostgreSQL con cache opcional Redis
 */
const getJugadorById = async (req, res) => {
  try {
    const { id } = req.params;
    const cacheKey = `jugador:${id}`;

    const result = await cacheAsideWithMeta(cacheKey, async () => {
      const sql = `
        SELECT
          j.id_jugador AS id,
          j.nombre,
          j.apellido,
          j.posicion,
          j.fecha_nacimiento AS fechaNacimiento,
          j.altura,
          j.peso,
          j.id_equipo AS equipoId,
          e.nombre AS equipo
        FROM Jugador j
        LEFT JOIN Equipo e ON e.id_equipo = j.id_equipo
        WHERE j.id_jugador = $1
          AND j.activo = true;
      `;
      const response = await query(sql, [id]);
      return response.rows[0] || null;
    }, BENJA_CACHE_TTL);

    if (!result.data) {
      return res.status(404).json({ message: 'Jugador no encontrado' });
    }

    res.json({ meta: result.meta, data: result.data });
  } catch (error) {
    console.error('❌ Error /api/jugadores/:id:', error.message);
    res.status(500).json({ error: error.message });
  }
};

app.get(['/jugador/:id', '/api/jugadores/:id'], getJugadorById);

/**
 * GET /api/equipos/:equipoId/jugadores
 * Obtiene listado de jugadores de un equipo
 */
app.get('/api/equipos/:equipoId/jugadores', async (req, res) => {
  try {
    const { equipoId } = req.params;
    const cacheKey = `equipos:${equipoId}:jugadores`;

    const result = await cacheAsideWithMeta(cacheKey, async () => {
      const sql = `
        SELECT
          j.id_jugador AS id,
          j.nombre,
          j.apellido,
          j.posicion,
          j.fecha_nacimiento AS fechaNacimiento,
          j.altura,
          j.peso,
          j.id_equipo AS equipoId
        FROM Jugador j
        WHERE j.id_equipo = $1
          AND j.activo = true
        ORDER BY j.apellido, j.nombre;
      `;
      const response = await query(sql, [equipoId]);
      return response.rows;
    }, BENJA_CACHE_TTL);

    res.json({ meta: result.meta, data: result.data });
  } catch (error) {
    console.error('❌ Error /api/equipos/:equipoId/jugadores:', error.message);
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
    let ranking = await getSortedSet(rankingKey, 0, 9, true);

    if (ranking.length === 0) {
      const sql = `
        SELECT
          j.id_jugador AS id,
          CONCAT(j.nombre, ' ', j.apellido) AS jugador,
          e.nombre AS equipo,
          COALESCE(SUM(est.puntos), 0) AS puntos_totales
        FROM Jugador j
        LEFT JOIN Equipo e ON e.id_equipo = j.id_equipo
        LEFT JOIN Estadistica est ON est.id_jugador = j.id_jugador
        WHERE j.activo = true
        GROUP BY j.id_jugador, j.nombre, j.apellido, e.nombre
        ORDER BY puntos_totales DESC
        LIMIT 10;
      `;
      const response = await query(sql);
      const dbRanking = response.rows.map((row) => ({
        member: String(row.id),
        score: Number(row.puntos_totales),
        jugador: row.jugador,
        equipo: row.equipo
      }));

      if (dbRanking.length > 0) {
        await addSortedSet(rankingKey, dbRanking.map((row) => ({
          score: row.score,
          member: row.member
        })));
      }

      return res.json({
        season: 'season1',
        topPlayers: dbRanking
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

// Nota: este middleware debe ser el último en montarse, después de todas las rutas.
// Si se coloca antes, bloqueará las rutas definidas luego.

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
 * POST /admin/redis/flush
 * Borra todo el contenido de Redis usado por la aplicación
 */
app.post('/admin/redis/flush', async (req, res) => {
  try {
    await flushDatabase();
    res.json({ ok: true, flushed: true });
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
      console.log(`   POST /api/equipos        - Crear un equipo nuevo`);
      console.log(`   POST /api/jugadores      - Crear un jugador nuevo`);
      console.log(`   POST /api/partidos       - Crear un partido nuevo`);
      console.log(`   POST /player/:id          - Crear jugador`);
      console.log(`   GET  /player/:id          - Obtener jugador desde Redis`);
      console.log(`   GET  /jugador/:id         - Obtener jugador por ID (DB + cache)`);
      console.log(`   GET  /api/jugadores/:id   - Obtener jugador por ID (DB + cache)`);
      console.log(`   GET  /ranking             - Ver ranking`);
      console.log(`   POST /ranking/player      - Agregar puntos`);
      console.log(`   GET  /session/set/:key/:value - Guardar en sesión`);
      console.log(`   GET  /session/get/:key    - Leer sesión`);
      console.log(`   GET  /session/destroy     - Destruir sesión`);
      console.log(`   POST /admin/redis/flush   - Limpiar todo Redis\n`);
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
