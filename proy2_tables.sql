--VERIFICACIONES-------------------------------------------------------------------------------------------------------------


BEGIN;

DO $$
BEGIN
    -- Verifica si el usuario actual tiene privilegios de superusuario
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = CURRENT_USER AND rolsuper) THEN
        RAISE EXCEPTION 'Este script requiere permisos de superusuario. Usuario actual: %', CURRENT_USER;
    END IF;
    --Elimina el Esquema proy2
	DROP SCHEMA IF EXISTS proy2 CASCADE;
	IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'proy2') THEN
		--Elimina el Usuario proy2
        REVOKE ALL PRIVILEGES ON DATABASE postgres FROM proy2;
		DROP USER proy2;
	END IF;
END $$;

--Crea el Usuario proy2
CREATE USER proy2 WITH PASSWORD 'proy2';
CREATE SCHEMA proy2 AUTHORIZATION proy2;
ALTER ROLE proy2 SET search_path TO proy2;
GRANT ALL PRIVILEGES ON SCHEMA proy2 TO proy2;
GRANT CREATE ON SCHEMA proy2 TO proy2;

--Asigna al Usuario proy2 como el usuario actual
SET ROLE proy2;
SET search_path TO proy2;


--CREACIÓN DE PERSONA-------------------------------------------------------------------------------------------------------------


CREATE TABLE PERSONA (
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    nacionalidad VARCHAR(20) NOT NULL,
    pais_domicilio VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    celular VARCHAR(20) NOT NULL,
    fax VARCHAR(20) NOT NULL
);

COMMENT ON TABLE PERSONA IS 'Tabla que almacena los datos de los individuos o empresas que son Agentes o Solicitantes.';
COMMENT ON COLUMN PERSONA.nombre IS 'Nombre de la Persona.';
COMMENT ON COLUMN PERSONA.direccion IS 'La Direccion de la Persona.';
COMMENT ON COLUMN PERSONA.nacionalidad IS 'La Nacionalidad de la Persona.';
COMMENT ON COLUMN PERSONA.pais_domicilio IS 'El Pais de Domicilio de la Persona.';
COMMENT ON COLUMN PERSONA.email IS 'El Correo Electronico de la Persona.';
COMMENT ON COLUMN PERSONA.telefono IS 'El Numero telefonico de la Persona.';
COMMENT ON COLUMN PERSONA.celular IS 'El Numero de Celular de la Persona.';
COMMENT ON COLUMN PERSONA.fax IS 'El Numero de Fax de la Persona.';


--CREACIÓN DE AGENTE-------------------------------------------------------------------------------------------------------------


CREATE TABLE AGENTE (
    num_agente INT PRIMARY KEY,
    doc_identidad VARCHAR(15) NOT NULL
)INHERITS(PERSONA);

COMMENT ON TABLE AGENTE IS 'Tabla que almacena los datos de los Agentes. Hereda Atributos de Persona';
COMMENT ON COLUMN AGENTE.num_agente IS 'El Numero de Agente del Agente.';
COMMENT ON COLUMN AGENTE.doc_identidad IS 'El Documento de Identidad del Agente.';
--Los Agentes heredan los atributos de Persona


--CREACIÓN DE SOLICITANTE-------------------------------------------------------------------------------------------------------------


CREATE TABLE SOLICITANTE (
    id SERIAL PRIMARY KEY,
    tipo_persona VARCHAR(20) NOT NULL CHECK (tipo_persona IN ('Persona Natural', E'Persona Jur\u00EDdica')),   --ok esto hay que revisar si se coloca aqui o en el archivo de checks, esto lo busque por ver como se pone que sea o natural o juridico
    doc_identidad VARCHAR(15),
    num_poder VARCHAR(15),
    num_agente INT,                                     --lo de clave forania se pone en un archivo diferente
    representante_legal VARCHAR(100),                   --tiene restricciones, porque para que haya representante legal deberia ser juridico y venezolano(si lo vemos de esa forma)
    cedula VARCHAR(15)
)INHERITS(PERSONA);

COMMENT ON TABLE SOLICITANTE IS 'Tabla que almacena los datos de los Solicitantes. Hereda Atributos de Persona';
COMMENT ON COLUMN SOLICITANTE.id IS 'El Numero de id del Solicitante.';
COMMENT ON COLUMN SOLICITANTE.tipo_persona IS 'El Tipo de Solicitante (Natural o Juridico).';
COMMENT ON COLUMN SOLICITANTE.doc_identidad IS 'El Documento de Identidad del Solicitante.';
COMMENT ON COLUMN SOLICITANTE.num_poder IS 'El Numero de Poder del documento donde le conceden el Poder al Agente.';
COMMENT ON COLUMN SOLICITANTE.num_agente IS 'El Numero de Agente que referencia a un Agente.';
COMMENT ON COLUMN SOLICITANTE.representante_legal IS 'El nombre del Representante Legal del Solicitante.';
COMMENT ON COLUMN SOLICITANTE.cedula IS 'El Numero de Cedula del Representante Legal.';
--Los Solicitantes heredan los atributos de Persona


--CREACIÓN DE SOLICITUD-------------------------------------------------------------------------------------------------------------


CREATE TABLE SOLICITUD(
    num_solicitud VARCHAR(15) PRIMARY KEY,
    fecha_solicitud DATE NOT NULL,
    id_solicitante1 INT NOT NULL,
    id_solicitante2 INT,
    id_solicitante3 INT,
    prop_extranjera1 VARCHAR(25),
    pais_prop1 VARCHAR(20),
    fecha_prop1 DATE,
    prop_extranjera2 VARCHAR(25),
    pais_prop2 VARCHAR(20),
    fecha_prop2 DATE
);

COMMENT ON TABLE SOLICITUD IS 'Tabla que almacena los datos de las Solicitudes.';
COMMENT ON COLUMN SOLICITUD.num_solicitud IS 'El Numero de Solicitud de la Solicitud.';
COMMENT ON COLUMN SOLICITUD.fecha_solicitud IS 'La Fecha de Solicitud de la Solicitud.';
COMMENT ON COLUMN SOLICITUD.id_solicitante1 IS 'El Numero de id que hace referencia a un Solicitante.';
COMMENT ON COLUMN SOLICITUD.id_solicitante2 IS 'El Numero de id que hace referencia a un 2do Solicitante en la misma Solicitud.';
COMMENT ON COLUMN SOLICITUD.id_solicitante3 IS 'El Numero de id que hace referencia a un 3er Solicitante en la misma Solicitud.';
COMMENT ON COLUMN SOLICITUD.prop_extranjera1 IS 'El Codigo de Propiedad Extranjera.';
COMMENT ON COLUMN SOLICITUD.pais_prop1 IS 'El Pais de la Propiedad Extranjera.';
COMMENT ON COLUMN SOLICITUD.fecha_prop1 IS 'La Fecha de la Propiedad Extranjera.';
COMMENT ON COLUMN SOLICITUD.prop_extranjera2 IS 'El Codigo de una 2da Propiedad Extranjera.';
COMMENT ON COLUMN SOLICITUD.pais_prop2 IS 'El Pais de la 2da Propiedad Extranjera.';
COMMENT ON COLUMN SOLICITUD.fecha_prop2 IS 'La Fecha de la 2da Propiedad Extranjera.';


--CREACIÓN DE SIGNO-------------------------------------------------------------------------------------------------------------


CREATE TABLE SIGNO(
    id SERIAL PRIMARY KEY,
    num_solicitud VARCHAR(15) NOT NULL UNIQUE,                                                           -- clave foranea
    tipo_marca VARCHAR(5) NOT NULL CHECK (tipo_marca IN('MP','MS','NC','LC','DC','DO','MC')),
    tipo_signo VARCHAR(15) NOT NULL CHECK (tipo_signo IN('mixta','grafica','denominativa')),
    clase_int VARCHAR(10) NOT NULL,
    signo VARCHAR(100),                                                                            --no lo pongo no nulo pero debe tener una restriccion, de que si es denominativa o mixta si existe este campo
    distingue TEXT NOT NULL,
    descripcion TEXT
);

COMMENT ON TABLE SIGNO IS 'Tabla que almacena los datos de los Signos.';
COMMENT ON COLUMN SIGNO.id IS 'El Numero de id del Signo.';
COMMENT ON COLUMN SIGNO.num_solicitud IS 'El Numero de Solicitud que hace referencia a la Solicitud asociada al Signo.';
COMMENT ON COLUMN SIGNO.tipo_marca IS 'El Tipo de Marca del Signo.';
COMMENT ON COLUMN SIGNO.tipo_signo IS 'El Tipo de Signo del Signo (grafica, denominativa o mixta).';
COMMENT ON COLUMN SIGNO.clase_int IS 'La Clase Internacional del Signo.';
COMMENT ON COLUMN SIGNO.signo IS 'El Nombre del Signo.';
COMMENT ON COLUMN SIGNO.distingue IS 'Caracteristicas a las que se asocia el Signo.';
COMMENT ON COLUMN SIGNO.descripcion IS 'Descripcion del Signo.';


COMMIT;