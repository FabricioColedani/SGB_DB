-- 13-Crear_Tabla_Audit_Logs.sql
-- Crea la tabla audit_logs con los campos base solicitados.

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario TEXT NOT NULL,
    sqlstate TEXT,
    mensaje_error TEXT
);

-- Función de auditoría para cambios DML en Jugador.
CREATE OR REPLACE FUNCTION fn_audit_jugador_dml()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('INSERT Jugador: id=%s, nombre=%s %s, equipo=%s', NEW.id_jugador, NEW.nombre, NEW.apellido, COALESCE(NEW.id_equipo::text, 'NULL'))
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('UPDATE Jugador: id=%s, antes=%s %s, despues=%s %s', OLD.id_jugador, OLD.nombre, OLD.apellido, NEW.nombre, NEW.apellido)
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (usuario, sqlstate, mensaje_error)
        VALUES (
            current_user,
            NULL,
            format('DELETE Jugador: id=%s, nombre=%s %s, equipo=%s', OLD.id_jugador, OLD.nombre, OLD.apellido, COALESCE(OLD.id_equipo::text, 'NULL'))
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_jugador_dml
AFTER INSERT OR UPDATE OR DELETE ON Jugador
FOR EACH ROW
EXECUTE FUNCTION fn_audit_jugador_dml();
