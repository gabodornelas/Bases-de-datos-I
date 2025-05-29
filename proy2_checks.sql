--VERIFICACIONES-------------------------------------------------------------------------------------------------------------


BEGIN;

DO $$
BEGIN
    --Verifica que el usuario actual es proy2
    IF CURRENT_USER != 'proy2' THEN
        RAISE EXCEPTION 'Este script debe ejecutarse con el usuario: %, pero el usuario actual es: %', 'proy2', CURRENT_USER;
    END IF;
END $$;


--CHEQUEOS-------------------------------------------------------------------------------------------------------------


-- Clave Foranea de numero de agente en solicitante
ALTER TABLE SOLICITANTE ADD CONSTRAINT fk_agente FOREIGN KEY (num_agente) REFERENCES AGENTE(num_agente) ON DELETE CASCADE;

--Clave Foranea de id de solicitante 1 en solicitud
ALTER TABLE SOLICITUD ADD CONSTRAINT fk_solicitante1 FOREIGN KEY (id_solicitante1) REFERENCES SOLICITANTE(id) ON DELETE CASCADE;

--Clave Foranea de id de solicitante 2 en solicitud
ALTER TABLE SOLICITUD ADD CONSTRAINT fk_solicitante2 FOREIGN KEY (id_solicitante2) REFERENCES SOLICITANTE(id) ON DELETE CASCADE;

--Agregando verificacion de que ya exista un id en solicitante 1
ALTER TABLE SOLICITUD ADD CONSTRAINT check_solicitante2 CHECK (
    (id_solicitante2 IS NOT NULL AND id_solicitante1 IS NOT NULL) OR
    (id_solicitante2 IS NULL)
    );

--Clave Foranea de id de solicitante 3 en solicitud
ALTER TABLE SOLICITUD ADD CONSTRAINT fk_solicitante3 FOREIGN KEY (id_solicitante3) REFERENCES SOLICITANTE(id) ON DELETE CASCADE;

--Agregando verificacion de que ya exista un id en solicitante 1
ALTER TABLE SOLICITUD ADD CONSTRAINT check_solicitante3 CHECK (
    (id_solicitante3 IS NOT NULL AND id_solicitante2 IS NOT NULL) OR
    (id_solicitante3 IS NULL)
    );

--Verificacion de que exista propiedad extranjera 1
ALTER TABLE SOLICITUD ADD CONSTRAINT check_prop2 CHECK (
    (prop_extranjera2 IS NOT NULL AND prop_extranjera1 IS NOT NULL) OR
    (prop_extranjera2 IS NULL)
    );

--Verificacion de que exista pais propiedad extranjera 1
ALTER TABLE SOLICITUD ADD CONSTRAINT check_pais_prop2 CHECK (
    (pais_prop2 IS NOT NULL AND pais_prop1 IS NOT NULL) OR
    (pais_prop2 IS NULL)
    );

--Verificacion de que exista fecha propiedad extranjera 1
ALTER TABLE SOLICITUD ADD CONSTRAINT check_fecha_prop2 CHECK (
    (fecha_prop2 IS NOT NULL AND fecha_prop1 IS NOT NULL) OR
    (fecha_prop2 IS NULL)
    );

--Clave foranea de numero de solicitud en signo
ALTER TABLE SIGNO ADD CONSTRAINT fk_num_solicitud FOREIGN KEY (num_solicitud) REFERENCES SOLICITUD(num_solicitud) ON DELETE CASCADE;

--Restriccion de signo, si es denominativo o mixto, existe y si es grafico no
ALTER TABLE SIGNO ADD CONSTRAINT check_signo CHECK (
    (tipo_signo IN ('denominativa', 'mixta') AND signo IS NOT NULL) OR
    (tipo_signo = 'grafica')
);

COMMIT;