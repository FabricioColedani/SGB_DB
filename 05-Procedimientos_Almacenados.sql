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

-- 3. Proceso complejo: venta de entradas e inscripción de jugador con control transaccional
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

CREATE OR REPLACE PROCEDURE procesar_venta_e_inscripcion(
    p_id_partido INT,
    p_id_jugador INT,
    p_cantidad INT,
    p_asiento VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
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
    START TRANSACTION;

    -- Validaciones previas
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

    -- Cálculo básico del precio total
    v_precio_unitario := 20.0;
    v_precio_total := v_precio_unitario * p_cantidad;

    INSERT INTO VentaEntrada (id_partido, cantidad, precio_unitario, precio_total)
    VALUES (p_id_partido, p_cantidad, v_precio_unitario, v_precio_total)
    RETURNING * INTO v_venta;

    SAVEPOINT sp_inscripcion;
    BEGIN
        INSERT INTO InscripcionJugador (id_jugador, id_partido, estado, asiento)
        VALUES (p_id_jugador, p_id_partido, 'INSCRITO', p_asiento)
        RETURNING * INTO v_inscripcion;

        RAISE NOTICE 'Inscripción registrada: id_inscripcion=%, estado=%',
            v_inscripcion.id_inscripcion,
            v_inscripcion.estado;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
        ROLLBACK TO SAVEPOINT sp_inscripcion;
        RAISE NOTICE 'Fallo en la inscripción, se revierte sólo esa parte. SQLSTATE=% mensaje=%',
            v_sqlstate, v_message;
    END;

    COMMIT;

    RAISE NOTICE 'Venta registrada: id_venta=%, partido=%, jugador=% %',
        v_venta.id_venta,
        v_partido.id_partido,
        v_jugador.nombre,
        v_jugador.apellido;
    RAISE NOTICE 'Precio total cobrado: %', v_precio_total;
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
$$;

-- Ejecutar procedimiento complejo
CALL procesar_venta_e_inscripcion(1, 1, 2, 'A12');
