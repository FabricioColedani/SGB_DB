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

-- Ejecutar procedimiento
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

-- Ejecutar procedimiento
CALL estadisticas_jugador(1);
