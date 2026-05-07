-- INCLUIR COLUMNA TIPO POINT

-- 1. Agregar columna de tipo POINT a la tabla Estadio
ALTER TABLE Estadio ADD COLUMN ubicacion POINT;

-- 2. Crear un índice GiST (Generalized Search Tree) sobre la columna.
-- Este índice es altamente eficiente para búsquedas de proximidad o rangos espaciales.
CREATE INDEX idx_estadio_ubicacion ON Estadio USING GIST (ubicacion);

-- 3. Actualizando coordenadas para algunos estadios (Coordenadas aproximadas)
-- Usamos el formato: POINT(longitud latitud)
UPDATE Estadio SET ubicacion = POINT(-58.3683, -34.6211) WHERE id_estadio = 1; -- Luis Conde
UPDATE Estadio SET ubicacion = POINT(-58.4411, -34.6158) WHERE id_estadio = 2; -- Roberto Pando
UPDATE Estadio SET ubicacion = POINT(-57.5457, -38.0055) WHERE id_estadio = 3; -- Islas Malvinas

-- 4. Buscar estadios dentro de un área definida (por ejemplo, dentro de una caja de coordenadas)
-- El operador <@ significa "está contenido en"
SELECT nombre, ubicacion 
FROM Estadio 
WHERE ubicacion <@ box '((-60,-40),(-50,-30))';
