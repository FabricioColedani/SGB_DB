-- WINDOW FUNCTIONS Y CTE RECURSIVA

-- 1. WINDOW FUNCTION: Ranking histórico de jugadores según promedio de puntos
-- Esta consulta calcula el promedio de puntos por jugador y asigna un ranking
-- usando la función de ventana RANK() ordenado por promedio descendente

SELECT
    j.nombre,
    j.apellido,
    ROUND(AVG(e.puntos), 2) AS promedio_puntos,
    COUNT(e.id_partido) AS partidos_jugados,
    RANK() OVER (ORDER BY AVG(e.puntos) DESC) AS ranking_historico
FROM Estadistica e
JOIN Jugador j ON e.id_jugador = j.id_jugador
GROUP BY j.id_jugador, j.nombre, j.apellido
HAVING COUNT(e.id_partido) >= 1  -- Solo jugadores con al menos 1 partido
ORDER BY ranking_historico;

-- 2. CTE RECURSIVA: Recorrido de la estructura jerárquica de la liga
-- Esta CTE recorre desde la Federación Nacional hasta las categorías locales
-- mostrando la jerarquía completa con niveles

WITH RECURSIVE Jerarquia_Completa AS (
    -- Caso base: Entidades raíz (sin padre)
    SELECT
        id_entidad,
        nombre,
        tipo_entidad,
        id_padre,
        1 AS nivel,
        nombre AS ruta_completa
    FROM Jerarquia_Liga
    WHERE id_padre IS NULL

    UNION ALL

    -- Caso recursivo: Hijos de las entidades anteriores
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

-- 3. EJEMPLO ADICIONAL: Ranking por equipo usando PARTITION BY
-- Esta window function particiona por equipo para ver rankings dentro de cada equipo

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
