-- CONSULTAS
-- 1. Mostrar todos los equipos
SELECT * FROM Equipo
WHERE activo = true;

-- 2. Mostrar jugadores ordenados por apellido
SELECT nombre, apellido, posicion, altura
FROM Jugador
WHERE activo = true
ORDER BY apellido ASC;

-- 3. Mostrar los jugadores de un equipo específico
SELECT nombre, apellido, posicion
FROM Jugador
WHERE id_equipo = 1
  AND activo = true;

-- 4. Mostrar los partidos con más de 80 puntos del equipo local
SELECT *
FROM Partido
WHERE puntos_local > 80
  AND activo = true;

-- 5. Contar la cantidad de jugadores por equipo
SELECT e.nombre AS equipo, COUNT(j.id_jugador) AS cantidad_jugadores
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
WHERE e.activo = true
  AND j.activo = true
GROUP BY e.nombre
ORDER BY cantidad_jugadores DESC;

-- 6. Promedio de puntos por partido
SELECT ROUND(AVG(puntos_local + puntos_visitante), 2) AS promedio_puntos
FROM Partido
WHERE activo = true;

-- 7. Equipos con más de 1 jugador (usando HAVING)
SELECT e.nombre, COUNT(j.id_jugador) AS total
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
WHERE e.activo = true
  AND j.activo = true
GROUP BY e.nombre
HAVING COUNT(j.id_jugador) > 1;

-- 8. Promedio de puntos por jugador
SELECT j.nombre, j.apellido, AVG(e.puntos) AS promedio_puntos
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
WHERE e.activo = true
  AND j.activo = true
GROUP BY j.nombre, j.apellido
ORDER BY promedio_puntos DESC;

-- 9. Jugador con más rebotes
SELECT j.nombre, j.apellido, SUM(e.rebotes) AS total_rebotes
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
WHERE e.activo = true
  AND j.activo = true
GROUP BY j.nombre, j.apellido
ORDER BY total_rebotes DESC
LIMIT 1;

-- 10. Equipos que más partidos ganaron (simplificado)
SELECT eq.nombre AS equipo, COUNT(*) AS partidos_ganados
FROM Partido p
JOIN Equipo eq ON p.id_equipo_local = eq.id_equipo
WHERE p.puntos_local > p.puntos_visitante
  AND p.activo = true
  AND eq.activo = true
GROUP BY eq.nombre
ORDER BY partidos_ganados DESC;


-- CONSULTAS CON JOINS
-- 1. Mostrar los jugadores y el nombre de su equipo
SELECT j.nombre, j.apellido, e.nombre AS equipo
FROM Jugador j
INNER JOIN Equipo e ON j.id_equipo = e.id_equipo
WHERE j.activo = true
  AND e.activo = true;

-- 2. Mostrar todos los equipos, aunque no tengan jugadores
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
LEFT JOIN Jugador j ON e.id_equipo = j.id_equipo
WHERE e.activo = true
  AND (j.activo = true OR j.id_jugador IS NULL);

-- 3. Mostrar todos los jugadores, incluso si su equipo fue borrado
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
RIGHT JOIN Jugador j ON e.id_equipo = j.id_equipo
WHERE j.activo = true;

-- 4. Combinación cruzada entre equipos y árbitros (todas las combinaciones posibles)
SELECT e.nombre AS equipo, a.nombre AS arbitro
FROM Equipo e
CROSS JOIN Arbitro a
WHERE e.activo = true
  AND a.activo = true;

-- 5. Mostrar partido, estadio y árbitro
SELECT p.id_partido, e.nombre AS estadio, a.nombre AS arbitro, a.apellido, p.puntos_local, p.puntos_visitante
FROM Partido p
INNER JOIN Estadio e ON p.id_estadio = e.id_estadio
INNER JOIN Arbitro a ON p.id_arbitro = a.id_arbitro
WHERE p.activo = true
  AND e.activo = true
  AND a.activo = true;
