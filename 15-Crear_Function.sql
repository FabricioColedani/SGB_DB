-- 15-CREAR FUNCTION
-- Ejemplo de función que calcula el promedio de puntos de un jugador
-- Usa parámetros de entrada con %TYPE y define la volatilidad correctamente.

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

-- Uso:
-- SELECT fn_promedio_puntos_jugador(1);
