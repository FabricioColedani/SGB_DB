import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'liga_basquet',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

export const query = async (text, params = []) => {
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
};

export const closeDb = async () => {
  try {
    await pool.end();
    console.log('✅ PostgreSQL: conexión cerrada correctamente');
  } catch (error) {
    console.error('❌ Error cerrando PostgreSQL:', error.message);
  }
};
