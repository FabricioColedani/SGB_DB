Frontend independiente para el proyecto SGB

Instrucciones rápidas:

1. Arrancar el backend en `SGB_DB/backend`:

```bash
cd backend
npm install
npm start
```

2. Servir este frontend (desde la raíz del proyecto):

```bash
cd frontend
npm start
# o
npx http-server -p 8080 ./
```

3. Abrir en el navegador:

http://localhost:8080

Notas:
- Si ves errores CORS al hacer requests, tienes dos opciones:
  - Servir el frontend desde el mismo origen que el backend (copiando `frontend/*` a `backend/public`), o
  - Habilitar CORS en el backend añadiendo `npm i cors` y `app.use(require('cors')())` en `src/serverExample.js`.

- El frontend usa las rutas públicas del backend como:
  - `/api/posiciones`
  - `/api/estadisticas/maximos-anotadores`
  - `/api/equipos`
  - `/api/health`
  - `/partidos/resumen`
  - `/ranking`
  - `/player/:id`

Si querés, lo sirvo automáticamente desde el backend y configuro CORS para que todo funcione desde la misma URL, sin tocar la vista previa actual en `backend/public`.
