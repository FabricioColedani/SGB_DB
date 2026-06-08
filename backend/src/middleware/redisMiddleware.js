/**
 * Middleware de Express para inyectar Redis automáticamente
 * Permite acceder a redis en cualquier ruta como: req.redis
 */

import { getRedisClient } from '../config/redis.js';

/**
 * Middleware que inyecta el cliente de Redis en req.redis
 * Uso: app.use(redisMiddleware)
 */
export const redisMiddleware = (req, res, next) => {
  try {
    req.redis = getRedisClient();
    next();
  } catch (error) {
    console.error('❌ Redis middleware error:', error.message);
    res.status(500).json({ 
      error: 'Redis client not available',
      message: error.message 
    });
  }
};

/**
 * Middleware para cachear respuestas en Redis
 * Uso: app.get('/api/jugadores', cacheMiddleware(3600), getJugadores)
 * 
 * @param {number} ttl - Tiempo de vida en segundos (default: 3600)
 * @returns {Function} Middleware function
 */
export const cacheMiddleware = (ttl = 3600) => {
  return async (req, res, next) => {
    try {
      const redis = getRedisClient();
      const cacheKey = `cache:${req.originalUrl || req.url}`;

      // Intenta obtener del cache
      const cached = await redis.get(cacheKey);
      if (cached) {
        console.log(`✅ Cache hit: ${cacheKey}`);
        return res.json(JSON.parse(cached));
      }

      // Intercepta res.json para guardar en cache
      const originalJson = res.json.bind(res);
      res.json = function(data) {
        if (res.statusCode === 200) {
          redis.set(cacheKey, JSON.stringify(data), { EX: ttl })
            .catch(err => console.error('❌ Cache save error:', err.message));
          console.log(`💾 Cached: ${cacheKey} (TTL: ${ttl}s)`);
        }
        return originalJson(data);
      };

      next();
    } catch (error) {
      console.error('❌ Cache middleware error:', error.message);
      next();
    }
  };
};

/**
 * Middleware para rate limiting con Redis
 * Limita el número de requests por IP en un intervalo de tiempo
 * 
 * Uso: app.use(rateLimitMiddleware(100, 60)) // 100 requests por minuto
 * 
 * @param {number} maxRequests - Máximo número de requests
 * @param {number} windowSeconds - Ventana de tiempo en segundos
 * @returns {Function} Middleware function
 */
export const rateLimitMiddleware = (maxRequests = 100, windowSeconds = 60) => {
  return async (req, res, next) => {
    try {
      const redis = getRedisClient();
      const ip = req.ip || req.connection.remoteAddress;
      const key = `ratelimit:${ip}`;

      const current = await redis.incr(key);

      if (current === 1) {
        await redis.expire(key, windowSeconds);
      }

      const ttl = await redis.ttl(key);

      // Headers de rate limit
      res.set('X-RateLimit-Limit', maxRequests);
      res.set('X-RateLimit-Remaining', Math.max(0, maxRequests - current));
      res.set('X-RateLimit-Reset', Math.ceil(Date.now() / 1000) + ttl);

      if (current > maxRequests) {
        return res.status(429).json({
          error: 'Too many requests',
          message: `Rate limit exceeded. Max ${maxRequests} requests per ${windowSeconds}s`,
          retryAfter: ttl
        });
      }

      next();
    } catch (error) {
      console.error('❌ RateLimit middleware error:', error.message);
      next();
    }
  };
};

/**
 * Middleware para manejo de sesiones con Redis
 * Usa cookies para almacenar session ID y Redis para datos de sesión
 * 
 * Uso: app.use(sessionMiddleware('sgb-session', 3600))
 * 
 * @param {string} sessionName - Nombre de la cookie de sesión
 * @param {number} ttl - Tiempo de vida en segundos
 * @returns {Function} Middleware function
 */
export const sessionMiddleware = (sessionName = 'sgb-session', ttl = 3600) => {
  return async (req, res, next) => {
    try {
      const redis = getRedisClient();

      // Generar o obtener session ID
      let sessionId = req.cookies?.[sessionName];
      
      if (!sessionId) {
        // Nueva sesión
        sessionId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        res.cookie(sessionName, sessionId, {
          httpOnly: true,
          maxAge: ttl * 1000,
          secure: process.env.NODE_ENV === 'production'
        });
      }

      const sessionKey = `session:${sessionId}`;
      req.sessionId = sessionId;

      // Cargar datos de sesión
      const sessionData = await redis.hGetAll(sessionKey);
      req.session = {
        id: sessionId,
        data: sessionData,
        
        // Métodos útiles
        set: async (key, value) => {
          await redis.hSet(sessionKey, key, String(value));
          await redis.expire(sessionKey, ttl);
          sessionData[key] = value;
        },
        
        get: (key) => sessionData[key],
        
        remove: async (key) => {
          await redis.hDel(sessionKey, key);
          delete sessionData[key];
        },
        
        destroy: async () => {
          await redis.del(sessionKey);
          res.clearCookie(sessionName);
        }
      };

      // Actualizar TTL de sesión
      if (sessionData && Object.keys(sessionData).length > 0) {
        await redis.expire(sessionKey, ttl);
      }

      next();
    } catch (error) {
      console.error('❌ Session middleware error:', error.message);
      next();
    }
  };
};

/**
 * Middleware para logging de requests en Redis
 * Almacena logs en una lista para análisis posterior
 * 
 * Uso: app.use(loggingMiddleware())
 * 
 * @returns {Function} Middleware function
 */
export const loggingMiddleware = () => {
  return async (req, res, next) => {
    try {
      const redis = getRedisClient();
      
      // Capturar inicio
      const startTime = Date.now();
      
      // Interceptar response
      const originalSend = res.send.bind(res);
      res.send = function(data) {
        const duration = Date.now() - startTime;
        const logEntry = {
          timestamp: new Date().toISOString(),
          method: req.method,
          url: req.originalUrl,
          status: res.statusCode,
          duration: `${duration}ms`,
          ip: req.ip,
          userAgent: req.get('User-Agent')
        };

        // Guardar en Redis (últimos 1000 requests)
        redis.lPush('logs:requests', JSON.stringify(logEntry))
          .then(() => redis.lTrim('logs:requests', 0, 999))
          .catch(err => console.error('❌ Logging error:', err.message));

        // Imprimir en consola
        console.log(
          `${logEntry.method} ${logEntry.url} - ${logEntry.status} (${logEntry.duration})`
        );

        return originalSend(data);
      };

      next();
    } catch (error) {
      console.error('❌ Logging middleware error:', error.message);
      next();
    }
  };
};

export default {
  redisMiddleware,
  cacheMiddleware,
  rateLimitMiddleware,
  sessionMiddleware,
  loggingMiddleware
};
