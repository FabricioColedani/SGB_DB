-- VISTAS

-- 1. Vista de jugadores con su equipo y posición
CREATE OR REPLACE VIEW vista_jugadores_equipo AS
SELECT j.nombre, j.apellido, j.posicion, e.nombre AS equipo, e.ciudad
FROM Jugador j
JOIN Equipo e ON j.id_equipo = e.id_equipo;

-- 2. Vista de partidos con resultado y nombres de equipos
CREATE OR REPLACE VIEW vista_partidos_resumen AS
SELECT p.id_partido,
       eq1.nombre AS equipo_local,
       eq2.nombre AS equipo_visitante,
       p.puntos_local,
       p.puntos_visitante,
       e.nombre AS estadio
FROM Partido p
JOIN Equipo eq1 ON p.id_equipo_local = eq1.id_equipo
JOIN Equipo eq2 ON p.id_equipo_visitante = eq2.id_equipo
JOIN Estadio e ON p.id_estadio = e.id_estadio;

-- Ejecutar vistas
SELECT * FROM vista_jugadores_equipo;
SELECT * FROM vista_partidos_resumen;
