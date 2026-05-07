-- implementar índices b-tree hash gin
-- 1. B-Tree (Tradicional: Ideal para comparaciones de igualdad y rangos)
-- Optimiza la consulta de estadísticas por puntos y asistencias
CREATE INDEX IF NOT EXISTS idx_estadistica_puntos_asistencias ON Estadistica USING BTREE (puntos, asistencias);

-- 2. Hash (Ideal para comparaciones de igualdad exacta '=')
-- Optimiza la búsqueda de jugadores por una posición específica
CREATE INDEX IF NOT EXISTS idx_jugador_posicion_hash ON Jugador USING HASH (posicion);

-- 3. GIN (Generalized Inverted Index: Ideal para JSONB)
-- Ya lo tenías en tu script, pero asegúrate de que esté creado para las búsquedas en perfiles técnicos
CREATE INDEX IF NOT EXISTS idx_jugador_perfil_tecnico_gin ON Jugador USING GIN (perfil_tecnico);

-- 4. GiST (Generalized Search Tree: Ideal para datos geométricos/espaciales)
-- Optimiza búsquedas por cercanía o ubicación en el mapa de estadios
CREATE INDEX IF NOT EXISTS idx_estadio_ubicacion_gist ON Estadio USING GIST (ubicacion);

--Scan Seq
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;

--Scan Index
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;

-- Agregar columna faltante si no existe
ALTER TABLE Partido ADD COLUMN IF NOT EXISTS resultado VARCHAR(50);

-- Corregir el INSERT de estadísticas para que use IDs de partidos que realmente existen
-- (el script intentaba insertar hasta el ID 200.000, lo cual es correcto tras el generate_series anterior)
INSERT INTO Estadistica (id_partido, id_jugador, puntos, asistencias, rebotes)
SELECT 
    s, -- Usamos el ID correlativo de la serie para asegurar que cada partido tenga al menos una estadística
    floor(random() * 15 + 1)::int, 
    floor(random() * 35)::int, 
    floor(random() * 12)::int, 
    floor(random() * 15)::int
FROM generate_series(1, 200000) AS s; 
