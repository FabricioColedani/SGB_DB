# Guía de Pruebas - Frontend Actualizado con Acciones e Invalidación de Cache

## 🚀 Inicio Rápido

### 1. Arrancar Backend y Redis

```bash
# Terminal 1: Arrancar Redis (si no está corriendo)
redis-server

# Terminal 2: Arrancar Backend
cd backend
npm start
```

El backend debería estar disponible en `http://localhost:3000`

---

## 📋 Casos de Prueba

### Test 1: Ver Tabla de Posiciones con Cache HIT

1. **Abrir el frontend**: `http://localhost:3000`
2. **Hacer clic en "Posiciones"** (botón rápido o menú)
3. **Observar el indicador de estado**:
   - Debe mostrar: `Cache HIT (Redis)` ✅
   - Latencia baja (< 10ms típicamente)
   - Badge: Verde con "Redis Online"

**Esperado**: La tabla muestra los equipos y sus puntos.

---

### Test 2: Dar de Baja un Equipo y Verificar Cache MISS

1. **En la tabla de Posiciones**, hacer clic en botón **"Dar de Baja"** de cualquier equipo
2. **Modal de confirmación** aparece mostrando el equipo
3. **Hacer clic en "Dar de Baja"** en el modal
4. **Observar**:
   - Notificación verde en esquina inferior derecha: ✓ Éxito
   - Las tablas se refrescan automáticamente (~500ms)
   - **Indicador de cache cambia a: `Cache MISS (PostgreSQL)`** 🔴
   - Latencia más alta (comparada con HIT)
   - Badge: Rojo con "Redis Offline" (simulado)

5. **Hacer clic nuevamente en "Posiciones"**
   - Primera carga: CACHE MISS (datos nuevos desde PostgreSQL)
   - El equipo que fue dado de baja ya no aparece en la tabla
   - Latencia más alta

6. **Esperar 120 segundos** (TTL configurado) o hacer otra acción
7. **Hacer clic en "Posiciones" de nuevo**
   - Ahora debe ser: `Cache HIT (Redis)` ✅
   - La cache se recargó en Redis

**Esperado**: 
- ✅ El equipo desaparece de la lista
- ✅ Se ve CACHE MISS después de la acción
- ✅ Se ve CACHE HIT después de que expira el TTL

---

### Test 3: Invalidación Selectiva en "Máximos Anotadores"

1. **Hacer clic en "Máximos Anotadores"**
2. **Anotar el indicador**: Debe mostrar CACHE HIT (si es la segunda carga)
3. **Dar de baja un jugador** desde la tabla:
   - Botón "Dar de Baja" en la fila del jugador
   - Confirmar en el modal
4. **Observar**:
   - Notificación ✓ Éxito
   - Las tablas se refrescan
   - Indicador pasa a: `Cache MISS (PostgreSQL)` 🔴

5. **Verificar que el jugador fue dado de baja**:
   - El jugador ya no aparece en "Máximos Anotadores"
   - Tampoco aparece en "Posiciones" (mismo equipo afectado)

**Esperado**:
- ✅ Jugador desaparece de ambas tablas
- ✅ CACHE MISS se muestra después de dar de baja
- ✅ La invalidación es selectiva (solo se invalidaron las claves relevantes)

---

### Test 4: Indicador de Estado en Tiempo Real

1. **Abrir DevTools** (F12) → Console
2. **Hacer varias consultas**:
   - Posiciones (CACHE HIT después de primera carga)
   - Equipos (CACHE HIT)
   - Máximos Anotadores (CACHE HIT)
3. **Dar de baja un jugador**
4. **Observar cambios en Console**:
   - Debe haber logs de DELETE exitoso
   - Debe haber logs de invalidación de cache

**Esperado**:
- ✅ CACHE HIT aparece para consultas repetidas
- ✅ CACHE MISS aparece después de una acción (DELETE)
- ✅ Latencia diferente entre HIT y MISS

---

### Test 5: Notificaciones de Acción

1. **Realizar cualquier acción** (Dar de Baja):
   - Modal de confirmación
   - Confirmar
2. **Observar la notificación**:
   - Aparece en esquina inferior derecha
   - Color verde con ✓ si es exitoso
   - Color rojo con ✗ si hay error
   - Se desaparece automáticamente después de 4 segundos

**Esperado**:
- ✅ Notificación clara y visible
- ✅ Auto-desaparece después de 4s
- ✅ Mensajes claros en español

---

### Test 6: Verificar Invalidación en Redis (Avanzado)

1. **Conectar a Redis CLI**:
   ```bash
   redis-cli
   ```

2. **Antes de dar de baja, ver claves**:
   ```
   KEYS posiciones:*
   KEYS equipos:*
   ```

3. **Dar de baja un equipo desde el frontend**

4. **En Redis CLI, verificar que las claves fueron eliminadas**:
   ```
   KEYS posiciones:*      # Debe estar vacío
   KEYS equipos:*         # Debe estar vacío
   ```

**Esperado**:
- ✅ Las claves de cache son eliminadas selectivamente
- ✅ Las próximas consultas van a PostgreSQL y se recarga en Redis

---

## 🔍 Checklist de Funcionalidades

- [ ] ✅ Botones "Dar de Baja" aparecen en las tablas
- [ ] ✅ Modales de confirmación funcionan
- [ ] ✅ Cache HIT/MISS se muestra correctamente
- [ ] ✅ Las acciones invalidan la cache
- [ ] ✅ Las tablas se refrescan automáticamente
- [ ] ✅ Los datos actualizados se reflejan en la UI
- [ ] ✅ Las notificaciones aparecen y desaparecen
- [ ] ✅ Latencia diferente entre HIT y MISS
- [ ] ✅ Redis Online/Offline badge se actualiza

---

## 📊 Flujo Esperado Completo

```
1. Frontend carga → CACHE MISS (primera vez desde BD)
       ↓
2. Frontend carga de nuevo → CACHE HIT (desde Redis)
       ↓
3. Usuario presiona "Dar de Baja" → Modal
       ↓
4. Confirma → DELETE /api/equipos/:id
       ↓
5. Backend invalida cache selectivamente
       ↓
6. Frontend refrescar tablas (automático)
       ↓
7. Nuevas consultas → CACHE MISS (cache fue invalida)
       ↓
8. Mostrar datos actualizados (sin el elemento eliminado)
       ↓
9. Después de TTL (120s) → CACHE HIT de nuevo (recargado desde BD)
```

---

## 🐛 Troubleshooting

| Problema | Solución |
|----------|----------|
| No aparecen botones de acción | Verificar que `renderTable()` recibe el parámetro `context` correcto |
| Modal no se abre | Verificar que Bootstrap JS está cargado y `modalElement.show()` se ejecuta |
| Cache no se invalida | Revisar logs del backend y verificar que `deleteKeysByPattern()` se ejecuta |
| Datos no se refrescan | Verificar que `setTimeout()` en `confirmDelete()` ejecuta `loadPosiciones()`, etc. |
| Indicador no cambia a MISS | Revisar que `setStatus()` se llama con meta correcta después de refrescar |

---

## 📝 Notas Técnicas

- **TTL de Cache**: 120 segundos (configurable en `backend/src/serverExample.js`)
- **Invalidación Selectiva**: Al dar de baja, se invalidan solo las claves afectadas
- **Refresco Automático**: 500ms de delay después de acción (permite UI update)
- **Patrones de Invalidación**:
  - `posiciones:tabla` - Tabla de posiciones
  - `equipos:lista` - Lista de equipos
  - `equipos:*:jugadores` - Jugadores por equipo
  - `estadisticas:maximos-anotadores` - Top 10 anotadores

---

## ✅ Estado Actual

- [x] Botones de acción en HTML
- [x] Modales de confirmación
- [x] Funciones JavaScript para acciones
- [x] Invalidación de cache en backend
- [x] Refresco automático de datos
- [x] Indicadores visuales de cache
- [x] Notificaciones de acción
