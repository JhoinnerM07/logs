DO $$
DECLARE
    r RECORD;
    trigger_name TEXT;
    tiene_geom BOOLEAN;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_type = 'BASE TABLE'
          AND table_schema NOT IN ('pg_catalog', 'information_schema')
          AND table_name NOT IN ('auditoria_logs', 'logs_servidor')
    LOOP
        -- Verificar si la tabla tiene un campo llamado 'geom'
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = r.table_schema
              AND table_name = r.table_name
              AND column_name = 'geom'
        ) INTO tiene_geom;

        trigger_name := 'tr_log_' || r.table_schema || '_' || r.table_name;

        IF tiene_geom THEN
            EXECUTE format('
                DROP TRIGGER IF EXISTS %I ON %I.%I;
                CREATE TRIGGER %I
                AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION fn_log_con_geom_resumen();
            ',
            trigger_name, r.table_schema, r.table_name,
            trigger_name, r.table_schema, r.table_name);

            RAISE NOTICE 'Trigger con geom (resumen) creado en %.%', r.table_schema, r.table_name;

        ELSE
            EXECUTE format('
                DROP TRIGGER IF EXISTS %I ON %I.%I;
                CREATE TRIGGER %I
                AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION fn_log_sin_geom_resumen();
            ',
            trigger_name, r.table_schema, r.table_name,
            trigger_name, r.table_schema, r.table_name);

            RAISE NOTICE 'Trigger sin geom (resumen) creado en %.%', r.table_schema, r.table_name;
        END IF;
    END LOOP;
END;
$$;
