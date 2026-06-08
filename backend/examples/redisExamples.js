/**
 * Ejemplos prácticos de uso del módulo Redis
 * Estos ejemplos muestran las operaciones más comunes
 */

import { 
  getRedisClient, 
  connectRedis, 
  disconnectRedis 
} from '../src/config/redis.js';

import {
  createKey,
  safeGet,
  safeSet,
  increment,
  decrement,
  setHash,
  getHash,
  setHashField,
  pushList,
  getList,
  addSet,
  getSet,
  isMemberOfSet,
  addSortedSet,
  getSortedSet,
  deleteKeys,
  getKeysByPattern,
  getTTL,
  setExpire,
  getInfo
} from '../src/utils/redisHelpers.js';

const examples = async () => {
  try {
    await connectRedis();
    const redis = getRedisClient();

    console.log('\n========== EJEMPLOS DE USO DE REDIS ==========\n');

    // ========== STRINGS ==========
    console.log('📝 OPERACIONES CON STRINGS (Cadenas)');
    console.log('---');

    // Ejemplo 1: SET y GET
    const userKey = createKey('user', '1', 'name');
    await safeSet(userKey, 'Juan Pérez');
    const userName = await safeGet(userKey);
    console.log(`  SET ${userKey} = "${userName}"`);
    console.log(`  GET ${userKey} = "${userName}"\n`);

    // Ejemplo 2: SET con expiración (sesión)
    const sessionKey = createKey('session', 'user123token');
    await safeSet(sessionKey, { userId: 1, role: 'player' }, 3600); // 1 hora
    const session = await safeGet(sessionKey);
    console.log(`  SET ${sessionKey} con TTL 3600s`);
    console.log(`  Valor: ${session}`);
    const ttl = await getTTL(sessionKey);
    console.log(`  TTL restante: ${ttl} segundos\n`);

    // ========== NÚMEROS ==========
    console.log('🔢 OPERACIONES CON NÚMEROS (Contadores)');
    console.log('---');

    const visitKey = createKey('stats', 'homepage', 'visits');
    for (let i = 0; i < 5; i++) {
      await increment(visitKey);
    }
    const visits = await safeGet(visitKey);
    console.log(`  Visitas a homepage: ${visits}`);

    const viewKey = createKey('stats', 'player', 'views');
    await safeSet(viewKey, 100);
    await decrement(viewKey, 10);
    const views = await safeGet(viewKey);
    console.log(`  Vistas de jugador: ${views}\n`);

    // ========== HASHES ==========
    console.log('📦 OPERACIONES CON HASHES (Objetos)');
    console.log('---');

    const playerKey = createKey('player', '1');
    await setHash(playerKey, {
      name: 'Juan Pérez',
      number: '10',
      position: 'Base',
      points: '450'
    }, 7200); // 2 horas
    
    const player = await getHash(playerKey);
    console.log(`  HSET ${playerKey}:`);
    console.log(`    ${JSON.stringify(player, null, 2)}`);

    const playerName = await getHash(playerKey, 'name');
    console.log(`  HGET ${playerKey}:name = "${player.name}"\n`);

    // Actualizar un campo
    await setHashField(playerKey, 'points', '455');
    console.log(`  HSET ${playerKey}:points = "455"\n`);

    // ========== LISTAS ==========
    console.log('📋 OPERACIONES CON LISTAS (Colas/Stacks)');
    console.log('---');

    const queueKey = createKey('queue', 'tasks');
    await pushList(queueKey, 
      { id: 1, name: 'Procesar partido' },
      { id: 2, name: 'Calcular estadísticas' },
      { id: 3, name: 'Generar reporte' }
    );

    const tasks = await getList(queueKey);
    console.log(`  LPUSH ${queueKey}:`);
    tasks.forEach(task => console.log(`    - ${task.name}`));
    console.log();

    // ========== CONJUNTOS ==========
    console.log('🎯 OPERACIONES CON CONJUNTOS (Sets)');
    console.log('---');

    const tournamentKey = createKey('tournament', '1', 'teams');
    await addSet(tournamentKey, 
      'team:1', 
      'team:2', 
      'team:3', 
      'team:4'
    );

    const teams = await getSet(tournamentKey);
    console.log(`  SADD ${tournamentKey}:`);
    teams.forEach(team => console.log(`    - ${team}`));

    const isTeam1 = await isMemberOfSet(tournamentKey, 'team:1');
    console.log(`  Equipo 1 en torneo: ${isTeam1}\n`);

    // ========== CONJUNTOS ORDENADOS ==========
    console.log('🏆 OPERACIONES CON CONJUNTOS ORDENADOS (Ranking)');
    console.log('---');

    const rankingKey = createKey('ranking', 'season1', 'players');
    await addSortedSet(rankingKey, [
      { score: 450, member: 'Juan Pérez' },
      { score: 380, member: 'Carlos López' },
      { score: 420, member: 'Miguel García' },
      { score: 510, member: 'Luis Martínez' }
    ]);

    const ranking = await getSortedSet(rankingKey, 0, -1, true);
    console.log(`  🥇 Ranking de goleadores (${rankingKey}):`);
    ranking.forEach((player, idx) => {
      console.log(`    ${idx + 1}. ${player.member}: ${player.score} puntos`);
    });
    console.log();

    // ========== OPERACIONES EN LOTE ==========
    console.log('⚡ OPERACIONES EN LOTE');
    console.log('---');

    const pattern = createKey('session', '*');
    const sessionKeys = await getKeysByPattern(pattern);
    console.log(`  Sesiones activas: ${sessionKeys.length}`);
    if (sessionKeys.length > 0) {
      console.log(`    ${sessionKeys.join(', ')}`);
    }

    // Eliminar una clave
    await deleteKeys(visitKey);
    console.log(`  Clave eliminada: ${visitKey}\n`);

    // ========== INFORMACIÓN DEL SERVIDOR ==========
    console.log('ℹ️  INFORMACIÓN DEL SERVIDOR');
    console.log('---');
    
    const info = await getInfo();
    if (info) {
      const lines = info.split('\r\n').slice(0, 5);
      console.log(`  ${lines.join('\n  ')}`);
    }
    console.log();

    console.log('========== FIN DE EJEMPLOS ==========\n');

  } catch (error) {
    console.error('❌ Error en ejemplos:', error.message);
  } finally {
    await disconnectRedis();
  }
};

// Ejecutar ejemplos
examples();
