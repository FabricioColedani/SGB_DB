-- AGREGACIÓN DE TABLA JERARQUÍA

-- 1. Creación de la tabla jerárquica
CREATE TABLE Jerarquia_Liga (
    id_entidad SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_entidad VARCHAR(50), -- Ej: 'Federacion', 'Asociacion', 'Liga', 'Division'
    id_padre INTEGER REFERENCES Jerarquia_Liga(id_entidad), -- Relación Padre-Hijo
    nivel_jerarquico INTEGER -- Opcional, para control manual
);

-- 2. Inserción de datos para pruebas
-- Nivel 1 (Raíz)
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('FIBA', 'Federacion Internacional', NULL);

-- Nivel 2
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('CABB (Argentina)', 'Confederacion Nacional', 1);

-- Nivel 3
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('Federacion Cordobesa', 'Federacion Provincial', 2),
       ('Federacion Santafesina', 'Federacion Provincial', 2);

-- Nivel 4
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('Liga Cordobesa - Primera', 'Division', 3),
       ('Liga Cordobesa - Juveniles', 'Division', 3);

-- 3. Ejemplo de CTE Recursiva
-- Esta consulta recorre toda la estructura desde la raíz hacia abajo
WITH RECURSIVE Organigrama AS (
    -- Caso base: Empezamos por la entidad raíz (FIBA)
    SELECT id_entidad, nombre, tipo_entidad, id_padre, 1 AS nivel
    FROM Jerarquia_Liga
    WHERE id_padre IS NULL
    
    UNION ALL
    
    -- Caso recursivo: Unimos los hijos con sus padres
    SELECT h.id_entidad, h.nombre, h.tipo_entidad, h.id_padre, p.nivel + 1
    FROM Jerarquia_Liga h
    INNER JOIN Organigrama p ON h.id_padre = p.id_entidad
)
SELECT 
    LPAD('', (nivel - 1) * 4, ' ') || nombre AS estructura_visual, -- Para ver la jerarquía con espacios
    tipo_entidad, 
    nivel
FROM Organigrama;
