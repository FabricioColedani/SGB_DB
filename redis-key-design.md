# Diseño de llaves Redis para endpoints cacheados

Este documento define la estructura plana de las llaves Redis usando namespacing con `:` y los tiempos de vida (TTL) recomendados para evitar fugas de memoria.

## Endpoints cacheados

1. `GET /partidos/resumen`
   - Clave Redis: `partidos:resumen`
   - TTL recomendado: `60` segundos
   - Motivo: el resumen de partidos es un dato de alta lectura y baja tolerancia a la desactualización a corto plazo.

2. `GET /equipos/{equipoId}/jugadores`
   - Clave Redis: `equipos:{equipoId}:jugadores`
   - Ejemplo: `equipos:12:jugadores`
   - TTL recomendado: `300` segundos
   - Motivo: la lista de jugadores por equipo cambia con menos frecuencia, por lo que puede mantenerse más tiempo en caché sin perder frescura excesiva.

## Convención de namespacing

- `partidos` → namespace principal para datos de partidos
- `resumen` → recurso específico del endpoint de resumen
- `equipos` → namespace principal para datos de equipos
- `{equipoId}` → identificador dinámico del equipo
- `jugadores` → recurso específico del endpoint de jugadores

### Formato plano recomendado

- `partidos:resumen`
- `equipos:123:jugadores`

## Ejemplos con helper

Si se utiliza un helper como `createKey(namespace, id, property)`:

- `createKey('partidos', 'resumen')` → `partidos:resumen`
- `createKey('equipos', equipoId, 'jugadores')` → `equipos:{equipoId}:jugadores`

## Nota adicional

Para mayor aislamiento del proyecto, se puede añadir un prefijo global opcional:

- `sgb:partidos:resumen`
- `sgb:equipos:{equipoId}:jugadores`

Esto ayuda a distinguir claves si se comparte el mismo servidor Redis con otros proyectos.
