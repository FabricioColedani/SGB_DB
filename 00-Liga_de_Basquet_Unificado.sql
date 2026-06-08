-- Archivo unificado para crear la base de datos y ejecutar todo en un solo script.
-- Ejecútalo con psql: psql -f 00-Liga_de_Basquet_Unificado.sql
-- Nota: este script usa el meta-comando \c para cambiar a la base de datos creada.

-- Borrar y recrear la base de datos
DROP DATABASE IF EXISTS liga_basquet;
CREATE DATABASE liga_basquet;
\c liga_basquet

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Esquema privado para los objetos de la liga
CREATE SCHEMA IF NOT EXISTS liga AUTHORIZATION CURRENT_USER;
SET search_path = liga, public;

-- Tabla de auditoría
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario TEXT NOT NULL,
    sqlstate TEXT,
    mensaje_error TEXT
);

-- Tablas principales de la liga
CREATE TABLE IF NOT EXISTS Equipo (
    id_equipo SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    tecnico VARCHAR(100),
    anio_fundacion INT
);

CREATE TABLE IF NOT EXISTS Jugador (
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

CREATE TABLE IF NOT EXISTS Estadio (
    id_estadio SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    capacidad INT
);

CREATE TABLE IF NOT EXISTS Arbitro (
    id_arbitro SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    categoria VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Partido (
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

CREATE TABLE IF NOT EXISTS Estadistica (
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

-- Datos de ejemplo: equipos, estadios, árbitros, jugadores, partidos y estadísticas
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

-- Agregados, índices y modificaciones posteriores
ALTER TABLE Jugador ADD COLUMN IF NOT EXISTS perfil_tecnico JSONB;
CREATE INDEX IF NOT EXISTS idx_jugador_perfil_tecnico ON Jugador USING GIN (perfil_tecnico);

ALTER TABLE Estadio ADD COLUMN IF NOT EXISTS ubicacion POINT;
CREATE INDEX IF NOT EXISTS idx_estadio_ubicacion ON Estadio USING GIST (ubicacion);

UPDATE Jugador 
SET perfil_tecnico = '{"tiro_triple": "A+", "defensa": "B", "liderazgo": "Alto"}'
WHERE id_jugador = 1;

UPDATE Estadio SET ubicacion = POINT(-58.3683, -34.6211) WHERE id_estadio = 1;
UPDATE Estadio SET ubicacion = POINT(-58.4411, -34.6158) WHERE id_estadio = 2;
UPDATE Estadio SET ubicacion = POINT(-57.5457, -38.0055) WHERE id_estadio = 3;

-- Vistas
CREATE OR REPLACE VIEW vista_jugadores_equipo AS
SELECT j.nombre, j.apellido, j.posicion, e.nombre AS equipo, e.ciudad
FROM Jugador j
JOIN Equipo e ON j.id_equipo = e.id_equipo;

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

-- Tablas y procedimientos extra
CREATE TABLE IF NOT EXISTS VentaEntrada (
    id_venta SERIAL PRIMARY KEY,
    id_partido INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC NOT NULL,
    precio_total NUMERIC NOT NULL,
    fecha_venta TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (id_partido) REFERENCES Partido(id_partido)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS InscripcionJugador (
    id_inscripcion SERIAL PRIMARY KEY,
    id_jugador INT NOT NULL,
    id_partido INT NOT NULL,
    estado VARCHAR(30) NOT NULL,
    asiento VARCHAR(20),
    fecha_inscripcion TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (id_jugador) REFERENCES Jugador(id_jugador)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_partido) REFERENCES Partido(id_partido)
        ON UPDATE CASCADE ON DELETE CASCADE
);

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
SECURITY DEFINER
SET search_path = liga, public
AS $$
DECLARE
    v_sqlstate TEXT;
    v_message TEXT;
BEGIN
    INSERT INTO Jugador (nombre, apellido, fecha_nacimiento, posicion, altura, peso, id_equipo)
    VALUES (p_nombre, p_apellido, p_fecha_nac, p_posicion, p_altura, p_peso, p_id_equipo);
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
    INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
    VALUES (current_user, v_sqlstate, v_message);
    RAISE;
END;
$$;

CREATE OR REPLACE FUNCTION estadisticas_jugador(p_id_jugador INT)
RETURNS TABLE (
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    total_puntos NUMERIC,
    total_rebotes NUMERIC,
    total_asistencias NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = liga, public
AS $$
DECLARE
    v_sqlstate TEXT;
    v_message TEXT;
BEGIN
    RETURN QUERY
    SELECT j.nombre, j.apellido, COALESCE(SUM(e.puntos),0)::NUMERIC AS total_puntos,
           COALESCE(SUM(e.rebotes),0)::NUMERIC AS total_rebotes, COALESCE(SUM(e.asistencias),0)::NUMERIC AS total_asistencias
    FROM Estadistica e
    JOIN Jugador j ON e.id_jugador = j.id_jugador
    WHERE j.id_jugador = p_id_jugador
    GROUP BY j.nombre, j.apellido;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
    INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
    VALUES (current_user, v_sqlstate, v_message);
    RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE procesar_venta_e_inscripcion(
    p_id_partido INT,
    p_id_jugador INT,
    p_cantidad INT,
    p_asiento VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = liga, public
AS $$
DECLARE
    v_partido Partido%ROWTYPE;
    v_jugador Jugador%ROWTYPE;
    v_precio_unitario NUMERIC;
    v_precio_total NUMERIC;
    v_venta VentaEntrada%ROWTYPE;
    v_inscripcion InscripcionJugador%ROWTYPE;
    v_sqlstate TEXT;
    v_message TEXT;
BEGIN

    SELECT * INTO v_partido
    FROM Partido
    WHERE id_partido = p_id_partido;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El partido % no existe', p_id_partido;
    END IF;

    SELECT * INTO v_jugador
    FROM Jugador
    WHERE id_jugador = p_id_jugador;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El jugador % no existe', p_id_jugador;
    END IF;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad de entradas debe ser mayor que cero';
    END IF;

    v_precio_unitario := 20.0;
    v_precio_total := v_precio_unitario * p_cantidad;

    INSERT INTO VentaEntrada (id_partido, cantidad, precio_unitario, precio_total)
    VALUES (p_id_partido, p_cantidad, v_precio_unitario, v_precio_total)
    RETURNING * INTO v_venta;

    BEGIN
        INSERT INTO InscripcionJugador (id_jugador, id_partido, estado, asiento)
        VALUES (p_id_jugador, p_id_partido, 'INSCRITO', p_asiento)
        RETURNING * INTO v_inscripcion;

        RAISE NOTICE 'Inscripción registrada: id_inscripcion=%, estado=%',
            v_inscripcion.id_inscripcion,
            v_inscripcion.estado;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (current_user, v_sqlstate, v_message);
        RAISE NOTICE 'Fallo en la inscripción; se registró el error. SQLSTATE=% mensaje=%',
            v_sqlstate, v_message;
    END;


    RAISE NOTICE 'Venta registrada: id_venta=%, partido=%, jugador=% %',
        v_venta.id_venta,
        v_partido.id_partido,
        v_jugador.nombre,
        v_jugador.apellido;
    RAISE NOTICE 'Precio total cobrado: %', v_precio_total;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
    INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
    VALUES (current_user, v_sqlstate, v_message);
    RAISE;
END;
$$;

-- Ejecutar procedimientos de ejemplo
CALL agregar_jugador('Mariano', 'López', '2003-05-12', 'Escolta', 1.88, 79, 2);
SELECT * FROM estadisticas_jugador(1);
CALL procesar_venta_e_inscripcion(1, 1, 2, 'A12');

-- Scripts de generación masiva de datos
TRUNCATE TABLE Estadistica RESTART IDENTITY CASCADE;
TRUNCATE TABLE Partido RESTART IDENTITY CASCADE;

INSERT INTO Partido (id_equipo_local, id_equipo_visitante, id_estadio, id_arbitro, fecha, hora)
SELECT 
    (floor(random() * 10 + 1))::int,
    (floor(random() * 10 + 1))::int,
    (floor(random() * 5 + 1))::int,
    (floor(random() * 5 + 1))::int,
    NOW() - (random() * INTERVAL '365 days'),
    '20:00'::TIME + (floor(random() * 720))::INT * INTERVAL '1 minute'
FROM generate_series(1, 200000) AS s;

INSERT INTO Estadistica (id_partido, id_jugador, puntos, asistencias, rebotes)
SELECT 
    floor(random() * 200000 + 1)::int,
    floor(random() * 15 + 1)::int,
    floor(random() * 35)::int,
    floor(random() * 12)::int,
    floor(random() * 15)::int
FROM generate_series(1, 800000) AS s;

ANALYZE Partido;
ANALYZE Estadistica;

-- Índices adicionales
CREATE INDEX IF NOT EXISTS idx_estadistica_puntos_asistencias ON Estadistica USING BTREE (puntos, asistencias);
CREATE INDEX IF NOT EXISTS idx_jugador_posicion_hash ON Jugador USING HASH (posicion);
CREATE INDEX IF NOT EXISTS idx_jugador_perfil_tecnico_gin ON Jugador USING GIN (perfil_tecnico);
CREATE INDEX IF NOT EXISTS idx_estadio_ubicacion_gist ON Estadio USING GIST (ubicacion);

ALTER TABLE Partido ADD COLUMN IF NOT EXISTS resultado VARCHAR(50);

INSERT INTO Estadistica (id_partido, id_jugador, puntos, asistencias, rebotes)
SELECT 
    s,
    floor(random() * 15 + 1)::int,
    floor(random() * 35)::int,
    floor(random() * 12)::int,
    floor(random() * 15)::int
FROM generate_series(1, 200000) AS s;

-- Función de promedio de puntos por jugador
CREATE OR REPLACE FUNCTION fn_promedio_puntos_jugador(
    p_id_jugador Jugador.id_jugador%TYPE
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = liga, public
STRICT
STABLE
AS $$
DECLARE
    v_promedio NUMERIC;
    v_sqlstate TEXT;
    v_message TEXT;
BEGIN
    SELECT AVG(puntos)::NUMERIC
    INTO v_promedio
    FROM Estadistica
    WHERE id_jugador = p_id_jugador;

    RETURN COALESCE(v_promedio, 0);
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
    INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
    VALUES (current_user, v_sqlstate, v_message);
    RAISE;
END;
$$;

-- Ejemplos de vistas, consultas y funciones de ventana
SELECT * FROM vista_jugadores_equipo;
SELECT * FROM vista_partidos_resumen;

SELECT * FROM Equipo;
SELECT nombre, apellido, posicion, altura
FROM Jugador
ORDER BY apellido ASC;
SELECT nombre, apellido, posicion
FROM Jugador
WHERE id_equipo = 1;
SELECT * FROM Partido
WHERE puntos_local > 80;
SELECT e.nombre AS equipo, COUNT(j.id_jugador) AS cantidad_jugadores
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
GROUP BY e.nombre
ORDER BY cantidad_jugadores DESC;
SELECT ROUND(AVG(puntos_local + puntos_visitante), 2) AS promedio_puntos
FROM Partido;
SELECT e.nombre, COUNT(j.id_jugador) AS total
FROM Equipo e
JOIN Jugador j ON e.id_equipo = j.id_equipo
GROUP BY e.nombre
HAVING COUNT(j.id_jugador) > 1;
SELECT j.nombre, j.apellido, AVG(e.puntos) AS promedio_puntos
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.nombre, j.apellido
ORDER BY promedio_puntos DESC;
SELECT j.nombre, j.apellido, SUM(e.rebotes) AS total_rebotes
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.nombre, j.apellido
ORDER BY total_rebotes DESC
LIMIT 1;
SELECT eq.nombre AS equipo, COUNT(*) AS partidos_ganados
FROM Partido p
JOIN Equipo eq ON p.id_equipo_local = eq.id_equipo
WHERE p.puntos_local > p.puntos_visitante
GROUP BY eq.nombre
ORDER BY partidos_ganados DESC;
SELECT j.nombre, j.apellido, e.nombre AS equipo
FROM Jugador j
INNER JOIN Equipo e ON j.id_equipo = e.id_equipo;
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
LEFT JOIN Jugador j ON e.id_equipo = j.id_equipo;
SELECT e.nombre AS equipo, j.nombre AS jugador
FROM Equipo e
RIGHT JOIN Jugador j ON e.id_equipo = j.id_equipo;
SELECT e.nombre AS equipo, a.nombre AS arbitro
FROM Equipo e
CROSS JOIN Arbitro a;
SELECT p.id_partido, e.nombre AS estadio, a.nombre AS arbitro, a.apellido, p.puntos_local, p.puntos_visitante
FROM Partido p
INNER JOIN Estadio e ON p.id_estadio = e.id_estadio
INNER JOIN Arbitro a ON p.id_arbitro = a.id_arbitro;

-- Jerarquía de la liga
CREATE TABLE IF NOT EXISTS Jerarquia_Liga (
    id_entidad SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_entidad VARCHAR(50),
    id_padre INTEGER REFERENCES Jerarquia_Liga(id_entidad),
    nivel_jerarquico INTEGER
);

INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('FIBA', 'Federacion Internacional', NULL);
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('CABB (Argentina)', 'Confederacion Nacional', 1);
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('Federacion Cordobesa', 'Federacion Provincial', 2),
       ('Federacion Santafesina', 'Federacion Provincial', 2);
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre) 
VALUES ('Liga Cordobesa - Primera', 'Division', 3),
       ('Liga Cordobesa - Juveniles', 'Division', 3);

-- Funciones de ventana y CTE recursivas
SELECT
    j.nombre,
    j.apellido,
    ROUND(AVG(e.puntos), 2) AS promedio_puntos,
    COUNT(e.id_partido) AS partidos_jugados,
    RANK() OVER (ORDER BY AVG(e.puntos) DESC) AS ranking_historico
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.id_jugador, j.nombre, j.apellido
HAVING COUNT(e.id_partido) >= 1
ORDER BY ranking_historico;

WITH RECURSIVE Jerarquia_Completa AS (
    SELECT
        id_entidad,
        nombre,
        tipo_entidad,
        id_padre,
        1 AS nivel,
        nombre::VARCHAR AS ruta_completa
    FROM Jerarquia_Liga
    WHERE id_padre IS NULL

    UNION ALL

    SELECT
        h.id_entidad,
        h.nombre,
        h.tipo_entidad,
        h.id_padre,
        p.nivel + 1,
        p.ruta_completa || ' > ' || h.nombre
    FROM Jerarquia_Liga h
    INNER JOIN Jerarquia_Completa p ON h.id_padre = p.id_entidad
)
SELECT
    nivel,
    tipo_entidad,
    nombre,
    ruta_completa,
    CASE
        WHEN nivel = 1 THEN 'Federación Internacional'
        WHEN nivel = 2 THEN 'Confederación Nacional'
        WHEN nivel = 3 THEN 'Federación Provincial'
        WHEN nivel = 4 THEN 'División/Categoría Local'
        ELSE 'Otro nivel'
    END AS descripcion_nivel
FROM Jerarquia_Completa
ORDER BY ruta_completa;

SELECT
    e.nombre AS equipo,
    j.nombre,
    j.apellido,
    ROUND(AVG(est.puntos), 2) AS promedio_puntos,
    RANK() OVER (PARTITION BY e.id_equipo ORDER BY AVG(est.puntos) DESC) AS ranking_por_equipo
FROM Estadistica est
JOIN Jugador j ON est.id_jugador = j.id_jugador
JOIN Equipo e ON j.id_equipo = e.id_equipo
GROUP BY e.id_equipo, e.nombre, j.id_jugador, j.nombre, j.apellido
ORDER BY e.nombre, ranking_por_equipo;

-- Seguridad y permisos
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;
REVOKE CONNECT ON DATABASE liga_basquet FROM PUBLIC;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_admin') THEN
        CREATE ROLE liga_admin NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_analyst') THEN
        CREATE ROLE liga_analyst NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_app') THEN
        CREATE ROLE liga_app NOINHERIT;
    END IF;
END$$;

GRANT CONNECT ON DATABASE liga_basquet TO liga_admin, liga_analyst, liga_app;
GRANT USAGE ON SCHEMA liga TO liga_admin, liga_analyst, liga_app;
REVOKE ALL ON SCHEMA liga FROM PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA liga TO liga_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA liga TO liga_analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA liga TO liga_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA liga TO liga_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA liga TO liga_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT ALL ON TABLES TO liga_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT SELECT ON TABLES TO liga_analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO liga_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT ALL ON SEQUENCES TO liga_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT USAGE ON SEQUENCES TO liga_app;

-- Trigger de auditoría para Jugador
CREATE OR REPLACE FUNCTION fn_audit_jugador_dml()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = liga, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('INSERT Jugador: id=%s, nombre=%s %s, equipo=%s', NEW.id_jugador, NEW.nombre, NEW.apellido, COALESCE(NEW.id_equipo::text, 'NULL'))
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('UPDATE Jugador: id=%s, antes=%s %s, despues=%s %s', OLD.id_jugador, OLD.nombre, OLD.apellido, NEW.nombre, NEW.apellido)
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('DELETE Jugador: id=%s, nombre=%s %s, equipo=%s', OLD.id_jugador, OLD.nombre, OLD.apellido, COALESCE(OLD.id_equipo::text, 'NULL'))
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_audit_jugador_dml
AFTER INSERT OR UPDATE OR DELETE ON Jugador
FOR EACH ROW
EXECUTE FUNCTION fn_audit_jugador_dml();

