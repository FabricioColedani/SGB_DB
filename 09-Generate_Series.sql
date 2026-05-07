-- CREAR SCRIPT CON GENERATE_SERIES

-- Limpiar Tablas para evitar errores
TRUNCATE TABLE Estadistica RESTART IDENTITY CASCADE;
TRUNCATE TABLE Partido RESTART IDENTITY CASCADE;

-- 1. Desactivar temporalmente triggers o índices complejos si los hubiera para acelerar la carga
-- SET session_replication_role = 'replica'; 

-- 2. Generar 200.000 Partidos
-- Se distribuyen aleatoriamente entre los equipos y estadios existentes
INSERT INTO Partido (id_equipo_local, id_equipo_visitante, id_estadio, id_arbitro, fecha, hora)
SELECT 
    (floor(random() * 10 + 1))::int,        -- Supongamos que tienes equipos del 1 al 10
    (floor(random() * 10 + 1))::int,
    (floor(random() * 5 + 1))::int,         -- Estadios del 1 al 5
    (floor(random() * 5 + 1))::int,         -- Árbitros del 1 al 5
    NOW() - (random() * INTERVAL '365 days'), -- Fecha aleatoria en el último año
    '20:00'::TIME + (floor(random() * 720))::INT * INTERVAL '1 minute'
FROM generate_series(1, 200000) AS s;

-- 3. Generar 800.000 registros de Estadísticas
-- Vinculamos cada estadística a un partido existente (1 a 200.000) y a un jugador (1 a 50)
INSERT INTO Estadistica (id_partido, id_jugador, puntos, asistencias, rebotes)
   SELECT 
       floor(random() * 200000 + 1)::int, -- Ahora sí existen hasta el 200,000
       floor(random() * 15 + 1)::int,
       floor(random() * 35)::int, 
       floor(random() * 12)::int, 
       floor(random() * 15)::int
   FROM generate_series(1, 800000) AS s;

-- 4. IMPORTANTE: Ejecutar ANALYZE para que el planificador conozca la nueva distribución de datos
ANALYZE Partido;
ANALYZE Estadistica;

-- 5. Ejemplo de consulta con EXPLAIN ANALYZE
EXPLAIN ANALYZE 
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;
