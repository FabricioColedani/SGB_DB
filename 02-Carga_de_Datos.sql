-- INSERCIÓN DE DATOS DE EJEMPLO

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

-- Jugadores (1 x equipo)
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

-- Registros de estadísticas (jugadores-partidos)
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
