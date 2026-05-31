-- 15-CREAR FUNCTION
-- Ejemplo de función que calcula el promedio de puntos de un jugador
-- Usa parámetros de entrada con %TYPE y define la volatilidad correctamente.

CREATE OR REPLACE FUNCTION fn_promedio_puntos_jugador(
    p_id_jugador Jugador.id_jugador%TYPE
)
RETURNS NUMERIC
LANGUAGE plpgsql
STRICT
STABLE
AS $$
DECLARE
    v_promedio NUMERIC;
BEGIN
    SELECT AVG(puntos)::NUMERIC
    INTO v_promedio
    FROM Estadistica
    WHERE id_jugador = p_id_jugador;

    RETURN COALESCE(v_promedio, 0);
END;
$$;

-- Uso:
-- SELECT fn_promedio_puntos_jugador(1);
