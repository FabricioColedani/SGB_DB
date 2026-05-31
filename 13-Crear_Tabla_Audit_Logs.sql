-- 13-Crear_Tabla_Audit_Logs.sql
-- Crea la tabla audit_logs con los campos base solicitados.

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario TEXT NOT NULL,
    sqlstate TEXT,
    mensaje_error TEXT
);
