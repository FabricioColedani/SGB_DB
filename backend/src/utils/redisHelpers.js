/**
 * Helpers y utilidades para trabajar con Redis
 * Simplificar operaciones comunes y mejorar la experiencia del desarrollador
 */

import { getRedisClient } from '../config/redis.js';

/**
 * Crea una clave con prefijo de namespace
 * @param {string} namespace - Namespace (ej: 'user', 'session', 'cache')
 * @param {string} id - Identificador único
 * @param {string} [property] - Propiedad opcional (ej: 'name', 'email')
 * @returns {string} Clave formateada
 * 
 * @example
 * createKey('user', '1', 'name') // 'user:1:name'
 * createKey('session', 'abc123') // 'session:abc123'
 */
export const createKey = (namespace, id, property = null) => {
  if (property) {
    return `${namespace}:${id}:${property}`;
  }
  return `${namespace}:${id}`;
};

/**
 * Obtiene una clave con seguridad (evita errores si Redis no está conectado)
 * @param {string} key - Clave a buscar
 * @returns {Promise<any>} Valor o null si no existe
 */
export const safeGet = async (key) => {
  try {
    const redis = getRedisClient();
    return await redis.get(key);
  } catch (error) {
    console.error(`Error obteniendo clave ${key}:`, error.message);
    return null;
  }
};

/**
 * Establece una clave con seguridad y TTL opcional
 * @param {string} key - Clave a establecer
 * @param {any} value - Valor (será JSON stringificado si es objeto)
 * @param {number} [ttlSeconds] - Tiempo de vida en segundos
 * @returns {Promise<boolean>} true si fue exitoso
 */
export const safeSet = async (key, value, ttlSeconds = null) => {
  try {
    const redis = getRedisClient();
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
    
    if (ttlSeconds) {
      await redis.set(key, stringValue, { EX: ttlSeconds });
    } else {
      await redis.set(key, stringValue);
    }
    return true;
  } catch (error) {
    console.error(`Error estableciendo clave ${key}:`, error.message);
    return false;
  }
};

/**
 * Cache-Aside pattern helper.
 * Busca los datos en Redis, y si no existen recupera el dato desde la DB,
 * serializa el resultado como JSON y lo guarda en Redis con TTL.
 *
 * @param {string} key - Clave Redis
 * @param {Function} loader - Función async que devuelve los datos desde la DB
 * @param {number} [ttlSeconds=120] - TTL en segundos
 * @returns {Promise<any>} Resultado desde cache o DB
 */
export const cacheAside = async (key, loader, ttlSeconds = 120) => {
  try {
    const redis = getRedisClient();
    const cached = await redis.get(key);

    if (cached) {
      console.log(`✅ Cache hit: ${key}`);
      try {
        return JSON.parse(cached);
      } catch (parseError) {
        console.warn(`⚠️ Cache hit pero JSON inválido en ${key}:`, parseError.message);
        return cached;
      }
    }

    console.log(`⚠️ Cache miss: ${key}. Consultando DB...`);
    const result = await loader();

    if (result === undefined || result === null) {
      return result;
    }

    const stringValue = typeof result === 'string' ? result : JSON.stringify(result);
    await redis.set(key, stringValue, { EX: ttlSeconds });
    console.log(`💾 Guardado en cache Redis: ${key} (TTL ${ttlSeconds}s)`);

    return result;
  } catch (error) {
    console.error(`❌ Error en cacheAside para ${key}:`, error.message);
    return await loader();
  }
};

/**
 * Incrementa un contador
 * @param {string} key - Clave del contador
 * @param {number} [increment=1] - Cantidad a incrementar
 * @returns {Promise<number>} Valor del contador después del incremento
 */
export const increment = async (key, increment = 1) => {
  const redis = getRedisClient();
  return await redis.incrBy(key, increment);
};

/**
 * Decrementa un contador
 * @param {string} key - Clave del contador
 * @param {number} [decrement=1] - Cantidad a decrementar
 * @returns {Promise<number>} Valor del contador después del decremento
 */
export const decrement = async (key, decrement = 1) => {
  const redis = getRedisClient();
  return await redis.decrBy(key, decrement);
};

/**
 * Almacena un objeto como hash
 * @param {string} key - Clave del hash
 * @param {object} obj - Objeto a almacenar
 * @param {number} [ttlSeconds] - Tiempo de vida en segundos
 * @returns {Promise<boolean>} true si fue exitoso
 */
export const setHash = async (key, obj, ttlSeconds = null) => {
  try {
    const redis = getRedisClient();
    await redis.hSet(key, obj);
    if (ttlSeconds) {
      await redis.expire(key, ttlSeconds);
    }
    return true;
  } catch (error) {
    console.error(`Error estableciendo hash ${key}:`, error.message);
    return false;
  }
};

/**
 * Obtiene un objeto completo desde hash
 * @param {string} key - Clave del hash
 * @returns {Promise<object>} Objeto con los datos
 */
export const getHash = async (key) => {
  try {
    const redis = getRedisClient();
    return await redis.hGetAll(key);
  } catch (error) {
    console.error(`Error obteniendo hash ${key}:`, error.message);
    return null;
  }
};

/**
 * Obtiene un campo específico del hash
 * @param {string} key - Clave del hash
 * @param {string} field - Campo a obtener
 * @returns {Promise<any>} Valor del campo
 */
export const getHashField = async (key, field) => {
  try {
    const redis = getRedisClient();
    return await redis.hGet(key, field);
  } catch (error) {
    console.error(`Error obteniendo campo ${field} del hash ${key}:`, error.message);
    return null;
  }
};

/**
 * Establece un campo del hash
 * @param {string} key - Clave del hash
 * @param {string} field - Campo a establecer
 * @param {any} value - Valor del campo
 * @returns {Promise<boolean>} true si fue exitoso
 */
export const setHashField = async (key, field, value) => {
  try {
    const redis = getRedisClient();
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
    await redis.hSet(key, field, stringValue);
    return true;
  } catch (error) {
    console.error(`Error estableciendo campo ${field} del hash ${key}:`, error.message);
    return false;
  }
};

/**
 * Agrega valores a una lista
 * @param {string} key - Clave de la lista
 * @param {any[]} values - Valores a agregar
 * @returns {Promise<number>} Largo de la lista
 */
export const pushList = async (key, ...values) => {
  const redis = getRedisClient();
  const stringValues = values.map(v => 
    typeof v === 'string' ? v : JSON.stringify(v)
  );
  return await redis.lPush(key, stringValues);
};

/**
 * Obtiene elementos de una lista
 * @param {string} key - Clave de la lista
 * @param {number} [start=0] - Índice de inicio
 * @param {number} [stop=-1] - Índice final
 * @returns {Promise<any[]>} Array de elementos
 */
export const getList = async (key, start = 0, stop = -1) => {
  try {
    const redis = getRedisClient();
    const items = await redis.lRange(key, start, stop);
    return items.map(item => {
      try {
        return JSON.parse(item);
      } catch {
        return item;
      }
    });
  } catch (error) {
    console.error(`Error obteniendo lista ${key}:`, error.message);
    return [];
  }
};

/**
 * Agrega miembros a un conjunto
 * @param {string} key - Clave del conjunto
 * @param {any[]} members - Miembros a agregar
 * @returns {Promise<number>} Número de miembros agregados
 */
export const addSet = async (key, ...members) => {
  const redis = getRedisClient();
  return await redis.sAdd(key, members);
};

/**
 * Obtiene todos los miembros de un conjunto
 * @param {string} key - Clave del conjunto
 * @returns {Promise<string[]>} Array de miembros
 */
export const getSet = async (key) => {
  try {
    const redis = getRedisClient();
    return await redis.sMembers(key);
  } catch (error) {
    console.error(`Error obteniendo conjunto ${key}:`, error.message);
    return [];
  }
};

/**
 * Verifica si un miembro existe en un conjunto
 * @param {string} key - Clave del conjunto
 * @param {string} member - Miembro a verificar
 * @returns {Promise<boolean>} true si existe
 */
export const isMemberOfSet = async (key, member) => {
  try {
    const redis = getRedisClient();
    return await redis.sIsMember(key, member);
  } catch (error) {
    console.error(`Error verificando miembro en conjunto ${key}:`, error.message);
    return false;
  }
};

/**
 * Agrega miembros a un conjunto ordenado (para rankings)
 * @param {string} key - Clave del conjunto ordenado
 * @param {Array} members - Array de {score, member}
 * @returns {Promise<number>} Número de miembros agregados
 * 
 * @example
 * addSortedSet('ranking:players', [
 *   { score: 150, member: 'player:1' },
 *   { score: 200, member: 'player:2' }
 * ])
 */
export const addSortedSet = async (key, members) => {
  const redis = getRedisClient();
  return await redis.zAdd(key, members);
};

/**
 * Obtiene elementos de un conjunto ordenado (para rankings)
 * @param {string} key - Clave del conjunto ordenado
 * @param {number} [start=0] - Índice de inicio
 * @param {number} [stop=-1] - Índice final (-1 para últimos)
 * @param {boolean} [reverse=false] - Ordenar descendente (puntuación más alta primero)
 * @returns {Promise<Array>} Array con {member, score}
 */
export const getSortedSet = async (key, start = 0, stop = -1, reverse = true) => {
  try {
    const redis = getRedisClient();
    const method = reverse ? 'zRevRange' : 'zRange';
    return await redis[method](key, start, stop, { withScores: true });
  } catch (error) {
    console.error(`Error obteniendo conjunto ordenado ${key}:`, error.message);
    return [];
  }
};

/**
 * Elimina una clave
 * @param {string|string[]} keys - Clave o array de claves a eliminar
 * @returns {Promise<number>} Número de claves eliminadas
 */
export const deleteKeys = async (keys) => {
  try {
    const redis = getRedisClient();
    const keyArray = Array.isArray(keys) ? keys : [keys];
    return await redis.del(keyArray);
  } catch (error) {
    console.error(`Error eliminando claves:`, error.message);
    return 0;
  }
};

/**
 * Obtiene todas las claves que coinciden con un patrón
 * @param {string} pattern - Patrón (ej: 'user:*', 'session:*')
 * @returns {Promise<string[]>} Array de claves
 */
export const getKeysByPattern = async (pattern) => {
  try {
    const redis = getRedisClient();
    return await redis.keys(pattern);
  } catch (error) {
    console.error(`Error obteniendo claves con patrón ${pattern}:`, error.message);
    return [];
  }
};

/**
 * Obtiene el TTL (tiempo de vida) de una clave
 * @param {string} key - Clave a consultar
 * @returns {Promise<number>} Segundos restantes (-1 sin expiración, -2 no existe)
 */
export const getTTL = async (key) => {
  try {
    const redis = getRedisClient();
    return await redis.ttl(key);
  } catch (error) {
    console.error(`Error obteniendo TTL de ${key}:`, error.message);
    return -2;
  }
};

/**
 * Establece una expiración a una clave existente
 * @param {string} key - Clave
 * @param {number} seconds - Segundos de expiración
 * @returns {Promise<boolean>} true si se estableció
 */
export const setExpire = async (key, seconds) => {
  try {
    const redis = getRedisClient();
    const result = await redis.expire(key, seconds);
    return result === 1;
  } catch (error) {
    console.error(`Error estableciendo expiración en ${key}:`, error.message);
    return false;
  }
};

/**
 * Limpia todas las claves de la base de datos actual (⚠️ usar con cuidado)
 * @returns {Promise<void>}
 */
export const flushDatabase = async () => {
  try {
    const redis = getRedisClient();
    await redis.flushDb();
    console.warn('⚠️  Base de datos Redis limpiada');
  } catch (error) {
    console.error('Error limpiando base de datos:', error.message);
  }
};

/**
 * Obtiene información sobre la base de datos Redis
 * @returns {Promise<object>} Información del servidor
 */
export const getInfo = async () => {
  try {
    const redis = getRedisClient();
    const info = await redis.info();
    return info;
  } catch (error) {
    console.error('Error obteniendo información:', error.message);
    return null;
  }
};
