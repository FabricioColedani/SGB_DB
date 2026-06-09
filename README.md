# SGB_DB - Documentación y Orden de Ejecución

Este repositorio contiene scripts SQL organizados para el esquema de la liga de básquet y soporte de integración con Redis. Los archivos están nombrados con un orden lógico y descripciones claras para que puedas ejecutar cada paso por separado o revisar funcionalidades específicas.

## 📋 Orden de Ejecución Recomendado

### 1. **00-Liga_de_Basquet_Original.sql**

- Script original completo con toda la estructura, datos y ejemplos.
- Úsalo si quieres cargar el proyecto completo de una sola vez.

### 2. **01-Crear_Estructura_Liga.sql**

- Crea la base de datos `liga_basquet`.
- Define las tablas principales: `Equipo`, `Jugador`, `Estadio`, `Arbitro`, `Partido`, `Estadistica`.
- Ejecútalo primero si prefieres cargar el proyecto paso a paso.

### 3. **02-Insertar_Datos_Ejemplo.sql**

- Inserta datos de prueba en todas las tablas.
- Incluye equipos, estadios, árbitros, jugadores, partidos y estadísticas.
- Depende de la estructura creada en `01-Crear_Estructura_Liga.sql`.
- *Alternativa:* `02-Insertar_Datos_Completos.sql` proporciona una inserción más completa y detallada.

### 4. **03-Consultas_Basicas_Y_Joins.sql**

- Contiene consultas básicas para explorar los datos.
- Incluye ejemplos con `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` y `CROSS JOIN`.

### 5. **04-Crear_Vistas_Resumen.sql**

- Define vistas útiles para simplificar consultas frecuentes.
- Crea `vista_jugadores_equipo` y `vista_partidos_resumen`.

### 6. **05-Procedimientos_Almacenados.sql**

- Define procedimientos PL/pgSQL para automatizar tareas.
- Incluye `agregar_jugador()` y `estadisticas_jugador()`.

### 7. **06-Agregar_Columna_JSONB_Jugador.sql**

- Agrega la columna `perfil_tecnico` de tipo `JSONB` a la tabla `Jugador`.
- Crea un índice `GIN` para búsquedas eficientes en JSON.
- Incluye ejemplos de actualización y consulta.

### 8. **07-Crear_Tabla_Jerarquia_Liga.sql**

- Crea la tabla jerárquica `Jerarquia_Liga`.
- Inserta datos de ejemplo y genera una CTE recursiva para recorrer la jerarquía.

### 9. **08-Agregar_Columna_POINT_Estadio.sql**

- Agrega columna `ubicacion` de tipo `POINT` a la tabla `Estadio`.
- Crea un índice `GiST` para consultas geoespaciales.
- Incluye ejemplos de actualización y consulta.

### 10. **09-Generar_Datos_Masivos_Generate_Series.sql**

- Genera datos masivos con `generate_series`.
- Inserta registros de prueba en `Partido` y `Estadistica`.
- Ideal para pruebas de rendimiento y cargas grandes.

### 11. **10-Indices_BTree_Hash_GIN.sql**

- Contiene ejemplos y explicaciones de índices `B-Tree`, `Hash` y `GIN`.
- Ideal para aprender sobre optimización de consultas en PostgreSQL.

### 12. **11-Window_Functions_Ranking_Historico.sql**

- Contiene ejemplos de funciones de ventana.
- Incluye ranking histórico de jugadores por promedio de puntos y consultas con particiones.

### 13. **12-Monitoreo_PG_Stat_Statements.sql**

- Scripts para monitoreo con `pg_stat_statements`.
- Útil para identificar consultas costosas y analizar rendimiento.
### 13. **13-Crear_Tabla_Audit_Logs.sql**

- Crea la tabla `audit_logs` para auditoría de operaciones y cambios críticos.
- Implementa triggers y registros de metadatos de usuario, operaciones y errores.

### 14. **14-Permisos_Iniciales_y_Esquemas.sql**

- Define roles, permisos y esquemas de seguridad para la base de datos.
- Configura accesos mínimos y aislamiento de objetos según buenas prácticas.

### 15. **15-Crear_Function.sql**

- Crea funciones reutilizables en PL/pgSQL para lógica de negocio y validaciones.
- Refuerza la abstracción y facilita el mantenimiento del esquema.
---

## 📁 Estructura de Archivos Actualizada

```
SGB_DB/
├── 00-Liga_de_Basquet_Original.sql
├── 01-Crear_Estructura_Liga.sql
├── 02-Insertar_Datos_Ejemplo.sql
├── 03-Consultas_Basicas_Y_Joins.sql
├── 04-Crear_Vistas_Resumen.sql
├── 05-Procedimientos_Almacenados.sql
├── 06-Agregar_Columna_JSONB_Jugador.sql
├── 07-Crear_Tabla_Jerarquia_Liga.sql
├── 08-Agregar_Columna_POINT_Estadio.sql
├── 09-Generar_Datos_Masivos_Generate_Series.sql
├── 10-Indices_BTree_Hash_GIN.sql
├── 11-Window_Functions_Ranking_Historico.sql
├── 12-Monitoreo_PG_Stat_Statements.sql
├── 13-Crear_Tabla_Audit_Logs.sql
├── 14-Permisos_Iniciales_y_Esquemas.sql
├── 15-Crear_Function.sql
├── ANALISIS_CACHE.md
├── redis-key-design.md
├── backend/
│   ├── package.json
│   ├── README.md
│   ├── src/
│   └── public/
├── docs/
└── README.md
```

---

## Checklist de Avance - Proyecto Integrador (Parte 2)

### A. Abstracción y Lógica Procedural

- [X]  **1.** Categorizar correctamente la volatilidad de la función (`IMMUTABLE`, `STABLE` o `VOLATILE`) analizando el consumo de CPU.
- [X]  **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.
- [X]  **3.** Implementar la robustez de tipos en variables usando `%TYPE`, `%ROWTYPE` o `RECORD` (evitar tipos estáticos).

### B. Gestión Avanzada de Transacciones

- [X]  **1.** Asegurar la atomicidad global del procedimiento mediante sentencias explícitas de `COMMIT` y `ROLLBACK`.
- [X]  **2.** Identificar el subproceso secundario propenso a fallas y aislarlo mediante la declaración de un `SAVEPOINT`.
- [X]  **3.** Implementar la lógica de reversión parcial (`ROLLBACK TO SAVEPOINT`) ante un error controlado.

### C. Capa de Auditoría y Forense de Datos

- [X]  **1.** Crear la tabla física `audit_logs` con los campos necesarios para metadatos del sistema.
- [X]  **2.** Implementar bloques estructurados `EXCEPTION` en los puntos críticos de los scripts.
- [X]  **3.** Utilizar `GET STACKED DIAGNOSTICS` para extraer de forma limpia el `RETURNED_SQLSTATE` y el `MESSAGE_TEXT`.

### D. Seguridad y Blindaje (Hardening)

- [X]  **1.** Configurar la cabecera del proceso administrativo crítico bajo el contexto de `SECURITY DEFINER`.
- [X]  **2.** Blindar las funciones restringiendo el vector de ataque mediante la fijación explícita del parámetro `search_path`.

### E. Automatización con Triggers

- [X]  **1.** Definir la tabla objetivo y la sincronización temporal del disparador (`BEFORE` / `AFTER`).
- [X]  **2.** Crear la función asociada al disparador aplicando lógica condicional mediante las pseudovariables `OLD` y `NEW`.
- [X]  **3.** Ejecutar la sentencia `CREATE TRIGGER` y verificar la reactividad ante eventos DML (INSERT, UPDATE o DELETE).

## Checklist: Integración de Caché con Redis (Proyecto Integrador - Parte 3)

### 1. Fase de Diseño y Selección

- [X]  Identificamos 1 o 2 endpoints estratégicos para cachear (alta frecuencia de lectura, baja de escritura).
- [X]  Listado de endpoints cacheados:
  - *Endpoint 1:* `GET /partidos/resumen`
  - *Endpoint 2:* `GET /equipos/{equipoId}/jugadores`
- [X]  Asegurar que el caso de uso soporta **consistencia eventual** (tolera desactualización de 1 o 2 minutos sin romper el sistema).

### 2. Configuración (Setup)

- [X]  Instalamos el cliente de Redis en nuestro proyecto.
- [X]  Establecemos conexión exitosa con el servidor de Redis (Local o Cloud).
- [X]  Implementamos **Manejo de Errores (Fallback)**: Si Redis se cae, la aplicación registra el error pero sigue funcionando, consultando directamente la base de datos principal.

### 3. Implementación del Patrón Cache-Aside

- [X]  **Consulta a la Caché:** El endpoint verifica primero si la clave existe en Redis.
- [X]  **Cache HIT:** Si el dato existe, se retorna inmediatamente al cliente (se evita ir a la DB).
- [X]  **Cache MISS (Consulta a la DB):** Si el dato NO existe, el sistema realiza la consulta a la base de datos principal (PostgreSQL, MongoDB, etc.).
- [X]  **Población de la Caché:** Guardamos el resultado obtenido de la base de datos en Redis.
- [X]  Devolver la respuesta final al cliente en todos los flujos.

### 4. Buenas Prácticas Técnicas

- [X]  **Nomenclatura (Namespacing):** Utilizamos el estándar de separación con dos puntos (`:`) para las claves. *(Ejemplo: `users:123` o `products:list:active`)*.
- [X]  **Asignación de TTL:** Toda clave guardada en Redis tiene un tiempo de vida (Time-To-Live) configurado.
