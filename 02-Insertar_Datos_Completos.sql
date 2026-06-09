-- Inserción completa de datos para el proyecto de Liga de Básquet
-- Ejecutar después de crear las tablas y aplicar las alteraciones de esquema.

SET search_path = liga, public;

-- Limpiar datos previos para evitar duplicados.
TRUNCATE TABLE
    audit_logs,
    InscripcionJugador,
    VentaEntrada,
    Estadistica,
    Partido,
    Jugador,
    Arbitro,
    Estadio,
    Equipo,
    Jerarquia_Liga
RESTART IDENTITY CASCADE;

-- Equipos
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

-- Estadios
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

-- Árbitros
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

-- Jugadores
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

-- Partidos
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

-- Estadísticas
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

-- Venta de entradas
INSERT INTO VentaEntrada (id_partido, cantidad, precio_unitario, precio_total) VALUES
(1, 1200, 18.50, 22200.00),
(2, 980, 20.00, 19600.00),
(3, 750, 16.00, 12000.00),
(4, 1100, 19.00, 20900.00),
(5, 1400, 22.00, 30800.00),
(6, 900, 17.50, 15750.00),
(7, 820, 18.00, 14760.00),
(8, 1300, 20.00, 26000.00),
(9, 1000, 18.00, 18000.00),
(10, 1150, 19.50, 22425.00),
(11, 950, 18.00, 17100.00),
(12, 870, 17.00, 14790.00),
(13, 1020, 21.00, 21420.00),
(14, 980, 18.50, 18130.00),
(15, 760, 16.50, 12540.00);

-- Inscripciones de jugadores a partidos
INSERT INTO InscripcionJugador (id_jugador, id_partido, estado, asiento) VALUES
(1, 1, 'CONFIRMADO', 'A12'),
(2, 2, 'CONFIRMADO', 'B05'),
(3, 3, 'CONFIRMADO', 'C18'),
(4, 4, 'CONFIRMADO', 'D10'),
(5, 5, 'CONFIRMADO', 'E06'),
(6, 6, 'CONFIRMADO', 'F20'),
(7, 7, 'CONFIRMADO', 'G11'),
(8, 8, 'CONFIRMADO', 'H14'),
(9, 9, 'CONFIRMADO', 'I02'),
(10, 10, 'CONFIRMADO', 'J08'),
(11, 11, 'CONFIRMADO', 'K17'),
(12, 12, 'CONFIRMADO', 'L03'),
(13, 13, 'CONFIRMADO', 'M09'),
(14, 14, 'CONFIRMADO', 'N04'),
(15, 15, 'CONFIRMADO', 'O07');

-- Jerarquía de la liga
INSERT INTO Jerarquia_Liga (nombre, tipo_entidad, id_padre, nivel_jerarquico) VALUES
('FIBA', 'Federacion Internacional', NULL, 1),
('CABB (Argentina)', 'Confederacion Nacional', 1, 2),
('Federacion Cordobesa', 'Federacion Provincial', 2, 3),
('Federacion Santafesina', 'Federacion Provincial', 2, 3),
('Liga Cordobesa - Primera', 'Division', 3, 4);

-- Auditoría de carga inicial
INSERT INTO audit_logs (usuario, sqlstate, mensaje_error) VALUES
('sistema', '00000', 'Carga inicial de datos completada con éxito');

-- Datos opcionales para columnas extendidas si ya existen
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'liga' AND table_name = 'jugador' AND column_name = 'perfil_tecnico'
    ) THEN
        UPDATE Jugador SET perfil_tecnico = jsonb_build_object(
            'tiro_triple', 'A',
            'defensa', 'B',
            'liderazgo', 'Alto'
        ) WHERE id_jugador = 1;

        UPDATE Jugador SET perfil_tecnico = jsonb_build_object(
            'tiro_triple', 'B+',
            'defensa', 'A-',
            'liderazgo', 'Medio'
        ) WHERE id_jugador = 2;

        UPDATE Jugador SET perfil_tecnico = jsonb_build_object(
            'tiro_triple', 'A-',
            'defensa', 'A',
            'liderazgo', 'Alto'
        ) WHERE id_jugador = 3;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'liga' AND table_name = 'estadio' AND column_name = 'ubicacion'
    ) THEN
        UPDATE Estadio SET ubicacion = POINT(-58.3683, -34.6211) WHERE id_estadio = 1;
        UPDATE Estadio SET ubicacion = POINT(-58.4411, -34.6158) WHERE id_estadio = 2;
        UPDATE Estadio SET ubicacion = POINT(-57.5457, -38.0055) WHERE id_estadio = 3;
        UPDATE Estadio SET ubicacion = POINT(-63.2280, -27.4495) WHERE id_estadio = 4;
        UPDATE Estadio SET ubicacion = POINT(-58.8185, -27.4673) WHERE id_estadio = 5;
        UPDATE Estadio SET ubicacion = POINT(-64.1898, -31.4010) WHERE id_estadio = 6;
        UPDATE Estadio SET ubicacion = POINT(-58.3772, -34.5880) WHERE id_estadio = 7;
        UPDATE Estadio SET ubicacion = POINT(-67.4912, -45.8660) WHERE id_estadio = 8;
        UPDATE Estadio SET ubicacion = POINT(-58.4750, -34.5190) WHERE id_estadio = 9;
        UPDATE Estadio SET ubicacion = POINT(-58.4085, -34.5831) WHERE id_estadio = 10;
        UPDATE Estadio SET ubicacion = POINT(-66.8467, -29.4220) WHERE id_estadio = 11;
        UPDATE Estadio SET ubicacion = POINT(-58.1789, -26.1844) WHERE id_estadio = 12;
        UPDATE Estadio SET ubicacion = POINT(-64.2228, -31.4038) WHERE id_estadio = 13;
        UPDATE Estadio SET ubicacion = POINT(-63.5500, -26.8130) WHERE id_estadio = 14;
        UPDATE Estadio SET ubicacion = POINT(-60.9488, -34.5989) WHERE id_estadio = 15;
    END IF;
END $$;
