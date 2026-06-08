import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Cliente de Redis exportado para ser utilizado en toda la aplicación
 * 
 * Configuración:
 * - Host: Por defecto localhost (configurable vía REDIS_HOST)
 * - Port: Por defecto 6379 (configurable vía REDIS_PORT)
 * - URL: Soporta conexión directa con REDIS_URL
 * - Password: Opcional, se configura con REDIS_PASSWORD
 * 
 * Uso:
 * import { redisClient, connectRedis } from './config/redis.js';
 * 
 * await connectRedis();
 * await redisClient.set('key', 'value');
 * const value = await redisClient.get('key');
 */

let redisClient;

const getRedisConfig = () => {
  // Si existe REDIS_URL, úsala (útil para servicios en la nube como Redis Cloud, Heroku, etc)
  if (process.env.REDIS_URL) {
    return {
      url: process.env.REDIS_URL
    };
  }

  // Configuración local o manual
  return {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    db: process.env.REDIS_DB || 0,
    retry_strategy: (options) => {
      if (options.error && options.error.code === 'ECONNREFUSED') {
        console.error('❌ Redis: No se pudo conectar. ¿Está corriendo el servidor?');
        return new Error('Redis connection refused');
      }
      if (options.total_retry_time > 1000 * 60 * 60) {
        return new Error('Redis retry time exhausted');
      }
      if (options.attempt > 10) {
        return undefined;
      }
      return Math.min(options.attempt * 100, 3000);
    }
  };
};

/**
 * Conecta al servidor de Redis
 * @returns {Promise<void>}
 */
export const connectRedis = async () => {
  try {
    redisClient = createClient(getRedisConfig());

    // Eventos del cliente Redis
    redisClient.on('error', (err) => {
      console.error('❌ Redis error:', err);
    });

    redisClient.on('connect', () => {
      console.log('✅ Redis: Conectado correctamente');
    });

    redisClient.on('ready', () => {
      console.log('✅ Redis: Cliente listo para usar');
    });

    redisClient.on('reconnecting', () => {
      console.log('🔄 Redis: Intentando reconectar...');
    });

    await redisClient.connect();
    
    // Test de conexión
    const pong = await redisClient.ping();
    if (pong === 'PONG') {
      console.log('✅ Redis: Ping satisfactorio');
    }

  } catch (error) {
    console.error('❌ Error al conectar Redis:', error.message);
    throw error;
  }
};

/**
 * Desconecta del servidor de Redis
 * @returns {Promise<void>}
 */
export const disconnectRedis = async () => {
  try {
    if (redisClient) {
      await redisClient.disconnect();
      console.log('✅ Redis: Desconectado correctamente');
    }
  } catch (error) {
    console.error('❌ Error al desconectar Redis:', error.message);
  }
};

/**
 * Obtiene la instancia del cliente Redis
 * @returns {Object} Cliente de Redis
 */
export const getRedisClient = () => {
  if (!redisClient) {
    throw new Error('Redis no está conectado. Ejecuta connectRedis() primero.');
  }
  return redisClient;
};

/**
 * Cliente de Redis exportado directamente
 */
export { redisClient };
