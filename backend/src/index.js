import { connectRedis, disconnectRedis, getRedisClient } from './config/redis.js';

/**
 * Servidor principal de la aplicación SGB Backend
 */

const main = async () => {
  try {
    console.log('🚀 Iniciando SGB Backend...\n');

    // Conectar a Redis
    await connectRedis();

    // Ejemplos de uso de Redis
    const redisClient = getRedisClient();

    // SET: Guardar un valor
    await redisClient.set('app:version', '1.0.0');
    console.log('\n📝 SET: app:version = 1.0.0');

    // GET: Obtener un valor
    const version = await redisClient.get('app:version');
    console.log('📖 GET: app:version =', version);

    // INCR: Incrementar un contador
    const visitCount = await redisClient.incr('app:visits');
    console.log('🔢 INCR: app:visits =', visitCount);

    // HSET: Guardar un hash (objeto)
    await redisClient.hSet('user:1', {
      name: 'Juan Pérez',
      email: 'juan@example.com',
      role: 'player'
    });
    console.log('📦 HSET: user:1 = {name, email, role}');

    // HGETALL: Obtener todos los valores de un hash
    const user = await redisClient.hGetAll('user:1');
    console.log('📖 HGETALL: user:1 =', user);

    // EXPIRE: Establecer expiración (TTL)
    await redisClient.set('session:abc123', '{"userId": 1}', { EX: 3600 });
    console.log('⏱️  EXPIRE: session:abc123 vence en 3600 segundos');

    // TTL: Obtener tiempo de expiración
    const ttl = await redisClient.ttl('session:abc123');
    console.log('⏱️  TTL: session:abc123 expira en', ttl, 'segundos');

    console.log('\n✅ SGB Backend está listo para ser usado\n');
    console.log('💡 Próximos pasos:');
    console.log('   1. Configura tu .env con datos de Redis');
    console.log('   2. Importa { connectRedis, getRedisClient } en tus archivos');
    console.log('   3. Usa getRedisClient() para acceder al cliente\n');

  } catch (error) {
    console.error('❌ Error fatal:', error);
    process.exit(1);
  }
};

// Ejecutar la aplicación
main().catch((error) => {
  console.error('❌ Error no capturado:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n\n🛑 Deteniendo servidor...');
  await disconnectRedis();
  process.exit(0);
});
