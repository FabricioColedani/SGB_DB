import { connectRedis, disconnectRedis, getRedisClient } from './config/redis.js';

const main = async () => {
  await connectRedis();
  const redis = getRedisClient();

  console.log('PING =>', await redis.ping());
  console.log('GET partidos:resumen =>', await redis.get('partidos:resumen'));
  console.log('TTL partidos:resumen =>', await redis.ttl('partidos:resumen'));

  await disconnectRedis();
};

main().catch(err => {
  console.error(err);
  process.exit(1);
});