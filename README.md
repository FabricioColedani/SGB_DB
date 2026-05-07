## 📋 Orden de Ejecución Recomendado

### 1. **01-Estructura.sql** 
- Crea la base de datos `liga_basquet`
- Define todas las tablas principales: Equipo, Jugador, Estadio, Arbitro, Partido, Estadistica
- **Debe ejecutarse primero** para crear la estructura base

### 2. **02-Carga_de_Datos.sql** 
- Inserta datos de ejemplo en todas las tablas
- Incluye: Equipos, Estadios, Árbitros, Jugadores, Partidos y Estadísticas
- Depende de: `01-Estructura.sql`

### 3. **03-Consultas.sql** 
- Contiene 10 consultas básicas
- Incluye 5 consultas con JOINS (INNER, LEFT, RIGHT, CROSS)
- Permite explorar y validar los datos

### 4. **04-Vistas.sql** 
- Define 2 vistas útiles:
  - `vista_jugadores_equipo`: Jugadores con datos de su equipo
  - `vista_partidos_resumen`: Resumen de partidos con nombres legibles
- Facilita consultas recurrentes

### 5. **05-Procedimientos_Almacenados.sql** 
- Define 2 procedimientos almacenados:
  - `agregar_jugador()`: Agrega nuevos jugadores
  - `estadisticas_jugador()`: Consulta estadísticas por jugador
- Ejemplo de automatización de operaciones comunes

### 6. **06-Modificacion_JSONB.sql** 
- Agrega columna `perfil_tecnico` JSONB a la tabla Jugador
- Crea índice GIN para optimizar búsquedas
- Ejemplos de inserción y consulta de datos JSON

### 7. **07-Tabla_Jerarquia.sql** 
- Crea tabla jerárquica `Jerarquia_Liga`
- Implementa CTE (Common Table Expression) recursiva
- Simula estructura de federaciones, confederaciones y ligas

### 8. **08-Columna_POINT.sql** 
- Agrega columna `ubicacion` de tipo POINT a Estadio
- Crea índice GiST para búsquedas geoespaciales
- Incluye ejemplos de consultas espaciales

### 9. **09-Generate_Series.sql** 
- Genera 200,000 registros de Partidos usando `generate_series`
- Genera 800,000 registros de Estadísticas
- Incluye ANALYZE para optimizar estadísticas del planificador
- **Opcional**: Para pruebas de rendimiento y grandes volúmenes

---

## 📁 Estructura de Archivos

```
SGB_DB/
├── 01-Estructura.sql
├── 02-Carga_de_Datos.sql
├── 03-Consultas.sql
├── 04-Vistas.sql
├── 05-Procedimientos_Almacenados.sql
├── 06-Modificacion_JSONB.sql
├── 07-Tabla_Jerarquia.sql
├── 08-Columna_POINT.sql
├── 09-Generate_Series.sql
└── README_EJECUCION.md (este archivo)
```
