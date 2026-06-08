# Análisis de Caché para SGB_DB

## 1. Contexto de la arquitectura actual

El repositorio es principalmente una base de datos PostgreSQL para una liga de básquetbol. La arquitectura actual se basa en:

- Tablas principales: `Equipo`, `Jugador`, `Estadio`, `Arbitro`, `Partido`, `Estadistica`
- Vistas de resumen: incluyen `vista_jugadores_equipo` y `vista_partidos_resumen`
- Procedimientos almacenados para lógica de negocio y operaciones complejas
- Índices y optimizaciones en columnas JSONB, geoespaciales y consultas frecuentes
- Monitoreo con `pg_stat_statements` para identificar consultas costosas

No existe código de API en el repositorio, por lo que los endpoints se infieren de las consultas y vistas diseñadas para uso de datos de lectura.

## 2. Criterios para elegir endpoints a cachear

Los criterios usados son:

- Alta frecuencia de lectura
- Baja frecuencia de escritura o actualización
- Tolerancia a consistencia eventual (1-2 minutos de retraso aceptable)
- Resultados que se pueden servir bien desde una vista/consulta precomputada

## 3. Endpoints ideales para cachear

### 3.1. `GET /partidos/resumen`

**Motivo:**
- Corresponde claramente a la vista `vista_partidos_resumen`
- Es probable que sea una consulta muy consultada por la UI o por dashboards de resultados
- Las fechas, puntuaciones y estadísticas de partidos suelen cambiar solo cuando se cargan nuevos resultados
- Si el caché está 1-2 minutos desactualizado, el sistema sigue siendo consistente para lectura histórica y resúmenes de partidos

**Características clave:**
- Datos de lectura intensiva
- Baja frecuencia de escritura (solo cuando hay nuevos partidos o resultados)
- Buena candidata para TTL corto de 60-120 segundos

### 3.2. `GET /equipos/{equipoId}/jugadores`

**Motivo:**
- Representa la consulta de plantilla/plantel que probablemente usa la vista `vista_jugadores_equipo`
- Las plantillas de equipos cambian con baja frecuencia (altas, bajas, transferencias)
- Soporta consistencia eventual: un jugador recién transferido puede no verse al instante y eso no rompe la mayoría de las vistas de equipos

**Características clave:**
- Alta lectura para mostrar información de equipo en páginas de detalle
- Actualizaciones relativamente infrecuentes
- TTL de 60-120 segundos es adecuado para evitar excesivos datos desactualizados

## 4. Recomendación de estrategia de caché

### Patrón sugerido: Cache-Aside

1. Consultar Redis primero.
2. Si existe el dato en caché, devolverlo.
3. Si no existe, consultar la base de datos y poblar Redis.
4. Usar un TTL de 60-120 segundos.

### Fallback y robustez

- Si Redis falla, la aplicación debe consultar directamente la base de datos.
- Registrar errores de Redis, pero no interrumpir la respuesta.
- No guardar en caché datos con errores de consulta o respuestas inválidas.

## 5. Observaciones finales

Estas rutas son las más adecuadas dentro de un sistema típico de liga deportiva basado en el diseño de este repositorio, porque:

- Se apoyan en vistas diseñadas para consultas frecuentes
- No requieren coherencia inmediata absoluta
- Reducen la carga de la base de datos en partes de lectura intensiva

> Si el sistema real tiene rutas distintas, la regla práctica es: cachear consultas de resumen y datos de catálogo/plantilla que sean leídos muchas veces y actualizados pocas veces.
