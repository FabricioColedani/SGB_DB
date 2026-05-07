-- MODIFICAR TABLA JUGADOR - Agregar columna JSONB

-- 1. Agregar la columna JSONB
ALTER TABLE Jugador 
ADD COLUMN perfil_tecnico JSONB;

-- 2. Crear un índice GIN sobre la nueva columna
-- Esto optimiza búsquedas como: ¿Qué jugadores tienen 'defensa' en su perfil?
CREATE INDEX idx_jugador_perfil_tecnico ON Jugador USING GIN (perfil_tecnico);

-- 3. Ejemplo de cómo insertar datos en esta nueva columna
UPDATE Jugador 
SET perfil_tecnico = '{"tiro_triple": "A+", "defensa": "B", "liderazgo": "Alto"}'
WHERE id_jugador = 1;

-- 4. Ejemplo de consulta usando el índice GIN
-- (Busca jugadores que tengan un nivel de liderazgo "Alto")
SELECT nombre, apellido 
FROM Jugador 
WHERE perfil_tecnico @> '{"liderazgo": "Alto"}';
