import 'dotenv/config';
import { query, closeDb } from './config/db.js';

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

(async function run(){
  try{
    console.log('Ejecutando consulta posiciones...');
    const res = await query(sql);
    console.log('OK. Filas:', res.rows.length);
    console.log(res.rows.slice(0,5));
  }catch(err){
    console.error('ERROR executing posiciones SQL:');
    console.error(err);
  }finally{
    await closeDb();
  }
})();
