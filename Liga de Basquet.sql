-- CREAR BASE DE DATOS
CREATE DATABASE liga_basquet;
\c liga_basquet;

-- CREAR TABLAS
CREATE TABLE Equipo (
    id_equipo SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    tecnico VARCHAR(100),
    anio_fundacion INT
);

CREATE TABLE Jugador (
    id_jugador SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    posicion VARCHAR(50),
    altura NUMERIC(4,2),
    peso NUMERIC(5,2),
    id_equipo INT,
    FOREIGN KEY (id_equipo)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Estadio (
    id_estadio SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    capacidad INT
);

CREATE TABLE Arbitro (
    id_arbitro SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    categoria VARCHAR(50)
);

CREATE TABLE Partido (
    id_partido SERIAL PRIMARY KEY,
    fecha DATE,
    hora TIME,
    puntos_local INT,
    puntos_visitante INT,
    id_equipo_local INT,
    id_equipo_visitante INT,
    id_estadio INT,
    id_arbitro INT,
    FOREIGN KEY (id_equipo_local)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_equipo_visitante)
        REFERENCES Equipo (id_equipo)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_estadio)
        REFERENCES Estadio (id_estadio)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (id_arbitro)
        REFERENCES Arbitro (id_arbitro)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Estadistica (
    id_estadistica SERIAL PRIMARY KEY,
    id_jugador INT NOT NULL,
    id_partido INT NOT NULL,
    puntos INT DEFAULT 0,
    rebotes INT DEFAULT 0,
    asistencias INT DEFAULT 0,
    robos INT DEFAULT 0,
    tapas INT DEFAULT 0,
    minutos_jugados INT DEFAULT 0,
    FOREIGN KEY (id_jugador)
        REFERENCES Jugador (id_jugador)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (id_partido)
        REFERENCES Partido (id_partido)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- INSERCIÓN DE DATOS DE EJEMPLO
-- equipos
INSERT INTO Equipo (nombre, ciudad, tecnico, anio_fundacion) VALUES
('Boca Juniors', 'Buenos Aires', 'Carlos Duro', 1929),
('San Lorenzo', 'CABA', 'Leandro Ramírez', 1930),
('Peñarol', 'Mar del Plata', 'Julián Morales', 1922),
('Quimsa', 'Santiago del Estero', 'Sebastián González', 1988),
('Regatas Corrientes', 'Corrientes', 'Fernando Tulo', 1923),
('Instituto', 'Córdoba', 'Lucas Victoriano', 1918),
('Obras Sanitarias', 'CABA', 'Gregorio Martínez', 1917),
('Gimnasia CR', 'Comodoro Rivadavia', 'Martín Villagrán', 1919),
('Platense', 'Vicente López', 'Alejandro Vázquez', 1905),
('Ferro Carril Oeste', 'CABA', 'Diego Lifschitz', 1904),
('Riachuelo', 'La Rioja', 'Gabriel Piccato', 1980),
('La Unión', 'Formosa', 'Sebastián Ginóbili', 1995),
('Atenas', 'Córdoba', 'Emanuel Córdoba', 1938),
('Olímpico', 'La Banda', 'Leonardo Gutiérrez', 1921),
('Argentino', 'Junín', 'Juan Pérez', 1935);

-- estadios
INSERT INTO Estadio (nombre, ciudad, capacidad) VALUES
('Luis Conde', 'Buenos Aires', 7500),
('Polideportivo Roberto Pando', 'CABA', 6000),
('Islas Malvinas', 'Mar del Plata', 7000),
('Ciudad de Santiago', 'Santiago del Estero', 8000),
('Regatas Arena', 'Corrientes', 6500),
('Angel Sandrín', 'Córdoba', 5500),
('Templo del Rock', 'CABA', 6200),
('Socios Fundadores', 'Comodoro Rivadavia', 5000),
('Ciudad de Vicente López', 'Vicente López', 4500),
('Héctor Etchart', 'CABA', 7000),
('Superdomo La Rioja', 'La Rioja', 9500),
('Cincuentenario', 'Formosa', 8500),
('Polideportivo Carlos Cerutti', 'Córdoba', 6000),
('Vicente Rosales', 'La Banda', 6500),
('Fortín de las Morochas', 'Junín', 5500);

-- árbitros
INSERT INTO Arbitro (nombre, apellido, categoria) VALUES
('Pablo', 'Estévez', 'A1'),
('Roberto', 'Smith', 'A1'),
('Luis', 'Soto', 'A2'),
('Marcelo', 'Martínez', 'A1'),
('Eduardo', 'López', 'A2'),
('Jorge', 'Maidana', 'B1'),
('Sergio', 'Fernández', 'A2'),
('Carlos', 'Ríos', 'B1'),
('Nicolás', 'Bianchi', 'A1'),
('Tomás', 'Figueroa', 'A2'),
('Ramiro', 'Campos', 'A1'),
('Andrés', 'Giménez', 'B2'),
('Julio', 'Suárez', 'A2'),
('Hernán', 'Correa', 'A1'),
('Iván', 'Torres', 'B1');

-- jugadores (1 x equipo)
INSERT INTO Jugador (nombre, apellido, fecha_nacimiento, posicion, altura, peso, id_equipo) VALUES
('Lucas', 'Gargallo', '1998-03-12', 'Escolta', 1.92, 85, 1),
('Franco', 'Balbi', '1989-08-21', 'Base', 1.85, 80, 2),
('Juan', 'Fernández', '2000-05-02', 'Alero', 2.00, 90, 3),
('Nicolás', 'Copello', '1997-09-11', 'Base', 1.84, 78, 4),
('Martín', 'Fernández', '1996-12-18', 'Alero', 1.98, 87, 5),
('Santiago', 'Scala', '1991-02-07', 'Base', 1.83, 80, 6),
('Pedro', 'Barreiro', '1996-04-09', 'Escolta', 1.94, 86, 7),
('Sebastián', 'Vega', '1990-09-15', 'Alero', 1.96, 88, 8),
('Matías', 'Bernardini', '1995-10-22', 'Base', 1.82, 77, 9),
('Jonathan', 'Torres', '1998-11-01', 'Pívot', 2.04, 101, 10),
('Leandro', 'Vildoza', '1994-04-05', 'Base', 1.83, 80, 11),
('Mariano', 'Giorgetti', '1989-06-10', 'Alero', 2.01, 92, 12),
('Facundo', 'Campana', '2001-01-12', 'Escolta', 1.90, 83, 13),
('Agustín', 'Brocal', '1997-03-25', 'Escolta', 1.93, 84, 14),
('Alejandro', 'Konatzky', '1998-07-14', 'Pívot', 2.05, 102, 15);

-- partidos
INSERT INTO Partido (fecha, hora, puntos_local, puntos_visitante, id_equipo_local, id_equipo_visitante, id_estadio, id_arbitro) VALUES
('2025-09-01', '20:30', 85, 78, 1, 2, 1, 1),
('2025-09-03', '21:00', 90, 88, 3, 4, 3, 2),
('2025-09-05', '19:30', 75, 82, 5, 6, 5, 3),
('2025-09-07', '20:00', 89, 79, 7, 8, 7, 4),
('2025-09-09', '21:15', 102, 95, 9, 10, 9, 5),
('2025-09-10', '22:00', 98, 88, 11, 12, 11, 6),
('2025-09-12', '20:30', 93, 84, 13, 14, 13, 7),
('2025-09-13', '21:00', 88, 90, 15, 1, 15, 8),
('2025-09-15', '20:30', 81, 83, 2, 3, 2, 9),
('2025-09-17', '21:10', 99, 85, 4, 5, 4, 10),
('2025-09-19', '20:45', 96, 91, 6, 7, 6, 11),
('2025-09-21', '19:00', 77, 88, 8, 9, 8, 12),
('2025-09-23', '21:30', 82, 73, 10, 11, 10, 13),
('2025-09-25', '22:00', 90, 87, 12, 13, 12, 14),
('2025-09-27', '20:00', 86, 92, 14, 15, 14, 15);

-- registros de estadísticas (jugadores-partidos)
INSERT INTO Estadistica (id_jugador, id_partido, puntos, rebotes, asistencias, robos, tapas, minutos_jugados) VALUES
(1, 1, 22, 4, 6, 1, 0, 30),
(2, 2, 18, 5, 8, 0, 1, 32),
(3, 3, 14, 6, 3, 2, 1, 28),
(4, 4, 25, 2, 9, 3, 0, 35),
(5, 5, 20, 7, 4, 1, 0, 31),
(6, 6, 27, 5, 6, 2, 1, 33),
(7, 7, 19, 4, 5, 0, 0, 29),
(8, 8, 23, 8, 4, 1, 1, 34),
(9, 9, 15, 3, 7, 2, 0, 28),
(10, 10, 21, 10, 2, 1, 1, 30),
(11, 11, 26, 6, 9, 3, 0, 36),
(12, 12, 17, 5, 5, 1, 0, 27),
(13, 13, 29, 3, 4, 2, 2, 38),
(14, 14, 24, 7, 6, 1, 1, 34),
(15, 15, 19, 8, 3, 0, 0, 31);

-- CONSULTAS
-- 1. Mostrar todos los equipos
SELECT * FROM Equipo;

-- 2. Mostrar jugadores ordenados por apellido
SELECT nombre, apellido, posicion, altura
FROM Jugador
ORDER BY apellido ASC;

-- 3. Mostrar los jugadores de un equipo específico
SELECT nombre, apellido, posicion
FROM Jugador
WHERE id_equipo = 1;

-- 4. Mostrar los partidos con más de 80 puntos del equipo local
SELECT *
FROM Partido
WHERE puntos_local > 80;

-- 5. Contar la cantidad de jugadores por equipo
SELECT e.nombre AS equipo, COUNT(j.id_jugador) AS cantidad_jugadores
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
GROUP BY e.nombre
ORDER BY cantidad_jugadores DESC;

-- 6. Promedio de puntos por partido
SELECT ROUND(AVG(puntos_local + puntos_visitante), 2) AS promedio_puntos
FROM Partido;

-- 7. Equipos con más de 1 jugador (usando HAVING)
SELECT e.nombre, COUNT(j.id_jugador) AS total
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
GROUP BY e.nombre
HAVING COUNT(j.id_jugador) > 1;

-- 8. Promedio de puntos por jugador
SELECT j.nombre, j.apellido, AVG(e.puntos) AS promedio_puntos
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.nombre, j.apellido
ORDER BY promedio_puntos DESC;

-- 9. Jugador con más rebotes
SELECT j.nombre, j.apellido, SUM(e.rebotes) AS total_rebotes
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.nombre, j.apellido
ORDER BY total_rebotes DESC
LIMIT 1;

-- 10. Equipos que más partidos ganaron (simplificado)
SELECT eq.nombre AS equipo, COUNT(*) AS partidos_ganados
FROM Partido p
JOIN Equipo eq ON p.id_equipo_local = eq.id_equipo
WHERE p.puntos_local > p.puntos_visitante
GROUP BY eq.nombre
ORDER BY partidos_ganados DESC;


-- CONSULTAS CON JOINS
-- 1. Mostrar los jugadores y el nombre de su equipo
SELECT j.nombre, j.apellido, e.nombre AS equipo
FROM Jugador j
INNER JOIN Equipo e ON j.id_equipo = e.id_equipo;

-- 2. Mostrar todos los equipos, aunque no tengan jugadores
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
LEFT JOIN Jugador j ON e.id_equipo = j.id_equipo;

-- 3. Mostrar todos los jugadores, incluso si su equipo fue borrado
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
RIGHT JOIN Jugador j ON e.id_equipo = j.id_equipo;

-- 4. Combinación cruzada entre equipos y árbitros (todas las combinaciones posibles)
SELECT e.nombre AS equipo, a.nombre AS arbitro
FROM Equipo e
CROSS JOIN Arbitro a;

-- 4. Mostrar partido, estadio y árbitro
SELECT p.id_partido, e.nombre AS estadio, a.nombre AS arbitro, a.apellido, p.puntos_local, p.puntos_visitante
FROM Partido p
INNER JOIN Estadio e ON p.id_estadio = e.id_estadio
INNER JOIN Arbitro a ON p.id_arbitro = a.id_arbitro;

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

-- Ejecutar vista
SELECT * FROM vista_jugadores_equipo;
SELECT * FROM vista_partidos_resumen;


-- PROCEDIMIENTOS ALMACENADOS
-- 1. Agregar un nuevo jugador
CREATE OR REPLACE PROCEDURE agregar_jugador(
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_fecha_nac DATE,
    p_posicion VARCHAR,
    p_altura NUMERIC,
    p_peso NUMERIC,
    p_id_equipo INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Jugador (nombre, apellido, fecha_nacimiento, posicion, altura, peso, id_equipo)
    VALUES (p_nombre, p_apellido, p_fecha_nac, p_posicion, p_altura, p_peso, p_id_equipo);
END;
$$;

-- Ejecutar
CALL agregar_jugador('Mariano', 'López', '2003-05-12', 'Escolta', 1.88, 79, 2);

-- 2. Consultar estadísticas de un jugador
CREATE OR REPLACE PROCEDURE estadisticas_jugador(p_id_jugador INT)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT j.nombre, j.apellido, SUM(e.puntos) AS total_puntos,
           SUM(e.rebotes) AS total_rebotes, SUM(e.asistencias) AS total_asistencias
    FROM Estadistica e
    JOIN Jugador j ON e.id_jugador = j.id_jugador
    WHERE j.id_jugador = p_id_jugador
    GROUP BY j.nombre, j.apellido;
END;
$$;

-- Ejecutar
CALL estadisticas_jugador(1);

-- MODIFICAR TABLA JUGADOR
-- 1. Modificar la tabla para agregar la columna JSONB
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

--Agregacion de Tabla Jerarquia
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

-- 3. Ejemplo de CTE Recursiva (Requisito E del proyecto)
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

-- Incluir columna tipo POINT
-- 1. Agregar columna de tipo POINT a la tabla Estadio
ALTER TABLE Estadio ADD COLUMN ubicacion POINT;

-- 2. Crear un índice GiST (Generalized Search Tree) sobre la columna.
-- Este índice es altamente eficiente para búsquedas de proximidad o rangos espaciales.
CREATE INDEX idx_estadio_ubicacion ON Estadio USING GIST (ubicacion);

-- Ejemplo: Actualizando coordenadas para algunos estadios (Coordenadas aproximadas)
-- Usamos el formato: POINT(longitud latitud)
UPDATE Estadio SET ubicacion = POINT(-58.3683, -34.6211) WHERE id_estadio = 1; -- Luis Conde
UPDATE Estadio SET ubicacion = POINT(-58.4411, -34.6158) WHERE id_estadio = 2; -- Roberto Pando
UPDATE Estadio SET ubicacion = POINT(-57.5457, -38.0055) WHERE id_estadio = 3; -- Islas Malvinas

-- Buscar estadios dentro de un área definida (por ejemplo, dentro de una caja de coordenadas)
-- El operador <@ significa "está contenido en"
SELECT nombre, ubicacion 
FROM Estadio 
WHERE ubicacion <@ box '((-60,-40),(-50,-30))';

--crear un scrip con generate series

-- 1. Desactivar temporalmente triggers o índices complejos si los hubiera para acelerar la carga
-- SET session_replication_role = 'replica'; 

-- 2. Generar 200.000 Partidos
-- Se distribuyen aleatoriamente entre los equipos y estadios existentes
INSERT INTO Partido (id_equipo_local, id_equipo_visitante, id_estadio, id_arbitro, fecha, resultado)
SELECT 
    floor(random() * 10 + 1)::int,        -- Supongamos que tienes equipos del 1 al 10
    floor(random() * 10 + 1)::int,
    floor(random() * 5 + 1)::int,         -- Estadios del 1 al 5
    floor(random() * 5 + 1)::int,         -- Árbitros del 1 al 5
    NOW() - (random() * INTERVAL '365 days'), -- Fecha aleatoria en el último año
    'Finalizado'
FROM generate_series(1, 200000) AS s;

-- 3. Generar 800.000 registros de Estadísticas
-- Vinculamos cada estadística a un partido existente (1 a 200.000) y a un jugador (1 a 50)
INSERT INTO Estadistica (id_partido, id_jugador, puntos, asistencias, rebotes)
SELECT 
    floor(random() * 200000 + 1)::int, -- ID de partido válido
    floor(random() * 50 + 1)::int,     -- ID de jugador válido
    floor(random() * 30)::int,         -- Puntos aleatorios 0-30
    floor(random() * 10)::int,         -- Asistencias 0-10
    floor(random() * 15)::int          -- Rebotes 0-15
FROM generate_series(1, 800000) AS s;

-- IMPORTANTE: Ejecutar ANALYZE para que el planificador conozca la nueva distribución de datos
ANALYZE Partido;
ANALYZE Estadistica;

EXPLAIN ANALYZE 
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;

-- implementar índices b-tree hash gin
-- 1. B-Tree (Tradicional: Ideal para comparaciones de igualdad y rangos)
-- Optimiza la consulta de estadísticas por puntos y asistencias
CREATE INDEX idx_estadistica_puntos_asistencias ON Estadistica USING BTREE (puntos, asistencias);

-- 2. Hash (Ideal para comparaciones de igualdad exacta '=')
-- Optimiza la búsqueda de jugadores por una posición específica
CREATE INDEX idx_jugador_posicion_hash ON Jugador USING HASH (posicion);

-- 3. GIN (Generalized Inverted Index: Ideal para JSONB)
-- Ya lo tenías en tu script, pero asegúrate de que esté creado para las búsquedas en perfiles técnicos
CREATE INDEX idx_jugador_perfil_tecnico_gin ON Jugador USING GIN (perfil_tecnico);

-- 4. GiST (Generalized Search Tree: Ideal para datos geométricos/espaciales)
-- Optimiza búsquedas por cercanía o ubicación en el mapa de estadios
CREATE INDEX idx_estadio_ubicacion_gist ON Estadio USING GIST (ubicacion);

--Scan Seq
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;

--Scan Index
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
SELECT * FROM Estadistica 
WHERE puntos = 25 AND asistencias > 5;

-- Agregar columna faltante si no existe
ALTER TABLE Partido ADD COLUMN resultado VARCHAR(50);

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
