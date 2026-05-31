-- Script de seguridad inicial para esquemas y permisos
-- Asegura que las tablas de la liga queden privadas y que solo roles definidos accedan a ellas.




-- 1. Crear un esquema privado para los objetos de la liga
CREATE SCHEMA IF NOT EXISTS liga AUTHORIZATION CURRENT_USER;

-- 2. Limitar el esquema público para evitar creación de objetos por defecto
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;

-- 3. Asegurar la base de datos contra accesos demasiado amplios
REVOKE CONNECT ON DATABASE liga_basquet FROM PUBLIC;

-- 4. Crear roles de seguridad básicos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_admin') THEN
        CREATE ROLE liga_admin NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_analyst') THEN
        CREATE ROLE liga_analyst NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'liga_app') THEN
        CREATE ROLE liga_app NOINHERIT;
    END IF;
END$$;

-- 5. Conceder conexión a la base de datos solo a los roles autorizados
GRANT CONNECT ON DATABASE liga_basquet TO liga_admin, liga_analyst, liga_app;

-- 6. Conceder uso del esquema privado
GRANT USAGE ON SCHEMA liga TO liga_admin, liga_analyst, liga_app;

-- 7. Evitar que PUBLIC vea objetos del esquema privado
REVOKE ALL ON SCHEMA liga FROM PUBLIC;

-- 8. Permisos iniciales sobre tablas y secuencias existentes en el esquema `liga`
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA liga TO liga_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA liga TO liga_analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA liga TO liga_app;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA liga TO liga_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA liga TO liga_app;

-- 9. Ajustar privilegios predeterminados para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT ALL ON TABLES TO liga_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT SELECT ON TABLES TO liga_analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO liga_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT ALL ON SEQUENCES TO liga_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA liga
    GRANT USAGE ON SEQUENCES TO liga_app;

-- 10. Configuración recomendada de search_path al crear objetos
SET search_path = liga, public;

-- Nota: si ya existen tablas en el esquema public, deben trasladarse al esquema `liga`
-- con ALTER TABLE public.<tabla> SET SCHEMA liga; antes de aplicar este script de seguridad.
