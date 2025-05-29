-- 1 *****************************************************************************************************************************
-- Consulta: Por mes, presentar el total de marcas solicitadas por tipo de signo (denominativo, gráfico, mixto). 
-- Descripción: Esta consulta cuenta cuantas marcas de tipo denominativa, grafica y mixta fueron solicitadas para
--      su registro en agrupándolas por mes de forma ascendente.
-- Autores: Gabriel De Ornelas, Cristina Gómez.
-- Fecha: 13 de Marzo de 2025.
-- Base de datos: Sistema de gestión de marcas (Postgresql).
-- *******************************************************************************************************************************



\echo '\nConsulta 1\n'


SELECT 
    TO_CHAR(s.fecha_solicitud, 'Mon-YYYY') AS "Mes",
    SUM(CASE WHEN SIGNO.tipo_signo = 'denominativa' THEN 1 ELSE 0 END) AS "Cantidad signo denominativo",
    SUM(CASE WHEN SIGNO.tipo_signo = 'grafica' THEN 1 ELSE 0 END) AS "Cantidad signo grafico",
    SUM(CASE WHEN SIGNO.tipo_signo = 'mixta' THEN 1 ELSE 0 END) AS "Cantidad signo mixto"
FROM 
    SOLICITUD AS s
JOIN 
    SIGNO ON s.num_solicitud = SIGNO.num_solicitud
GROUP BY
    DATE_TRUNC('month', s.fecha_solicitud),
    TO_CHAR(s.fecha_solicitud, 'Mon-YYYY')
ORDER BY
    DATE_TRUNC('month', s.fecha_solicitud) ASC;

-- Explicación:
-- - Se usa TO_CHAR(s.fecha_solicitud, 'Mon-YYYY') para convertir el mes y año de la fecha de solicitud en formato 'Mes-XXXX'.

-- -SUM(CASE WHEN SIGNO.tipo_signo = '[el_tipo_de_signo]' THEN 1 ELSE 0 END).
-- - -La parte SUM(...) es para sumar las ocurrencias dentro del parentesis.
-- - -La parte CASE WHEN es para añadir la condición de que el tipo de signo sea el esperado y, de ser así, devuelve 1, sino, 0.

-- -Se usa JOIN para unir las tablas SOLICITUD y SIGNO  con la condición de que tengan el mismo número de solicitud.

-- -Se usa DATE_TRUNC('month', s.fecha_solicitud) para truncar las fechas de rango, en este caso, por mes de la fecha de solicitud.



-- 2 *****************************************************************************************************************************
-- Consulta: Por mes, presentar el top 3 de los países de domicilio de solicitantes con mayor número de solicitudes. 
-- Descripción: Esta consulta cuenta la cantidad de países de domicilio de los solicitantes y devuelve el top 3 de países con
--      más ocurrencias agrupándolos por mes en forma ascendente y en casos de empate por nombre del país alfabéticamente.
-- Autores: Gabriel De Ornelas, Cristina Gómez.
-- Fecha: 13 de Marzo de 2025.
-- Base de datos: Sistema de gestión de marcas (Postgresql).
-- *******************************************************************************************************************************

\echo '\nConsulta 2\n'

WITH todos_solicitantes AS (
    SELECT
        s.fecha_solicitud,
        sol.pais_domicilio
    FROM
        SOLICITUD AS s
    JOIN
        SOLICITANTE sol ON s.id_solicitante1 = sol.id
    UNION ALL
    SELECT
        s.fecha_solicitud,
        sol.pais_domicilio
    FROM
        SOLICITUD AS s
    JOIN
        SOLICITANTE sol ON s.id_solicitante2 = sol.id
    UNION ALL
    SELECT
        s.fecha_solicitud,
        sol.pais_domicilio
    FROM
        SOLICITUD AS s
    JOIN
        SOLICITANTE sol ON s.id_solicitante3 = sol.id
),
solicitudes_por_mes_pais AS (
    SELECT
        TO_CHAR(fecha_solicitud, 'Mon-YYYY') AS mes,
        pais_domicilio AS pais,
        COUNT(*) AS cantidad_solicitudes
    FROM
        todos_solicitantes
    GROUP BY
        DATE_TRUNC('month', fecha_solicitud),
        TO_CHAR(fecha_solicitud, 'Mon-YYYY'),
        pais_domicilio
),
ranked_paises AS (
    SELECT
        mes,
        pais,
        cantidad_solicitudes,
        ROW_NUMBER() OVER (PARTITION BY mes ORDER BY cantidad_solicitudes DESC, pais ASC) AS rank
    FROM
        solicitudes_por_mes_pais
)
SELECT
    mes as "Mes",
    MAX(CASE WHEN rank = 1 THEN pais || ' (' || cantidad_solicitudes || ')' END) AS "Pais top 1",
    MAX(CASE WHEN rank = 2 THEN pais || ' (' || cantidad_solicitudes || ')' END) AS "Pais top 2",
    MAX(CASE WHEN rank = 3 THEN pais || ' (' || cantidad_solicitudes || ')' END) AS "Pais top 3"
FROM
    ranked_paises
GROUP BY
    "Mes"
ORDER BY
    TO_DATE(mes, 'Mon-YYYY') ASC;

-- Explicación:
-- - Se usa WITH para crear subconsultas de forma de generar 'tablas temporales' que nos ayudan más adelante.

-- - Entre esas subconsultas se crean las tablas:
-- - -'todos_solicitantes' que nos da la fecha de solicitud y el pais de domicilio del solicitante.
-- - -      Se usa UNION ALL para unir 3 consultas diferentes (por los 3 posibles ids asociados como solicitante de la solicitud).
-- - -'solicitudes_por_mes_pais' que cuenta la cantidad de solicitudes en todos_solicitantes y las agrupa por
-- - -      mes (con DATE_TRUNC('month', fecha_solicitud)), y por país.
-- - -'ranked_paises' que usa ROW_NUMBER() OVER (PARTITION BY mes ORDER BY cantidad_solicitudes DESC, pais ASC) para rankear lo
-- - -      obtenido en solicitudes_por_mes_pais donde ROW_NUMBER asigna un número único a cada fila en la partición en el orden
-- - -      de ORDER BY, el cual es por cantidad de solicitudes (De mayor a menor) y por país (alfabéticamente).

-- - De la subconsulta ranked_paises se utilizan los ranks según el CASE WHEN para tener cada top (el 1, 2 y 3), donde la función
-- - -      MAX nos ayuda a 'agrupar' en cierto modo las filas que necesitamos y elige la máxima, que en este caso será solo una. 

-- - Se las filas se agrupan por mes y se ordenan por mes usando TO_DATE(mes, 'Mon-YYYY') para truncarlos.



-- 3 *****************************************************************************************************************************
-- Consulta: Detalles de los números de solicitud con sus prioridades extranjeras (PE). 
-- Descripción: Esta consulta muestra el número de solicitud, la fecha de solicitud, la fecha de propiedad extranjera, el número
--      de propiedad extranjera y el país de propiedad extranjera asociados a un número de solicitud, ordenados por número de
--      solicitud y en caso de más de una Propiedad extranjera por solicitud, se ordenan por fecha de propiedad extranjera
-- Autores: Gabriel De Ornelas, Cristina Gómez.
-- Fecha: 13 de Marzo de 2025.
-- Base de datos: Sistema de gestión de marcas (Postgresql).
-- *******************************************************************************************************************************

\echo '\nConsulta 3\n'

SELECT
	num_solicitud AS "Solicitud numero",
	fecha_solicitud AS "Solicitud fecha",
	fecha_prop1 AS "PE fecha",
	prop_extranjera1 AS "PE numero",
	pais_prop1 AS "PE pais"
FROM
	SOLICITUD WHERE prop_extranjera1 IS NOT NULL

UNION ALL

SELECT 
	num_solicitud AS "Solicitud numero",
	fecha_solicitud AS "Solicitud fecha",
	fecha_prop2 AS "PE fecha",
	prop_extranjera2 AS "PE numero",
	pais_prop2 AS "PE pais"
FROM 
	SOLICITUD WHERE prop_extranjera2 IS NOT NULL

ORDER BY "Solicitud numero" ASC, "PE fecha" ASC;

-- Explicación:
-- - Se usa UNION ALL para unir 2 consultas diferentes, una para los casos donde la propiedad extranjera1 no sea NULL y otra
-- - -      para los casos donde la propiedad extranjera2 no sea NULL.

-- - Se usa ORDER BY para ordenar por número de solicitud y en segunda instancia por fecha de propiedad extranjera.



-- 4 *****************************************************************************************************************************
-- Consulta: El mismo listado anterior, pero filtrando solamente las filas en donde la fecha de la PE sea mayor o igual que la
--      fecha de la solicitud.
-- Descripción: Esta consulta muestra el número de solicitud, la fecha de solicitud, la fecha de propiedad extranjera, el número
--      de propiedad extranjera y el país de propiedad extranjera asociados a un número de solicitud, ordenados por número de
--      solicitud y en caso de más de una Propiedad extranjera por solicitud, se ordenan por fecha de propiedad extranjera, y
--      además los filtra mostrando solo las fechas donde la fecha de Propiedad extranjera sea mayor o igual a la fecha de la
--      solicitud.
-- Autores: Gabriel De Ornelas, Cristina Gómez.
-- Fecha: 13 de Marzo de 2025.
-- Base de datos: Sistema de gestión de marcas (Postgresql).
-- *******************************************************************************************************************************

\echo '\nConsulta 4\n'

SELECT
	num_solicitud AS "Solicitud numero",
	fecha_solicitud AS "Solicitud fecha",
	fecha_prop1 AS "PE fecha",
	prop_extranjera1 AS "PE numero",
	pais_prop1 AS "PE pais"
FROM
	SOLICITUD WHERE prop_extranjera1 IS NOT NULL AND fecha_prop1 >= fecha_solicitud

UNION ALL

SELECT 
	num_solicitud AS "Solicitud numero",
	fecha_solicitud AS "Solicitud fecha",
	fecha_prop2 AS "PE fecha",
	prop_extranjera2 AS "PE numero",
	pais_prop2 AS "PE pais"
FROM 
	SOLICITUD WHERE prop_extranjera2 IS NOT NULL AND fecha_prop2 >= fecha_solicitud

ORDER BY "Solicitud numero" ASC, "PE fecha" ASC;

-- Explicación:
-- - Se usa UNION ALL para unir 2 consultas diferentes, una para los casos donde la propiedad extranjera1 no sea NULL y otra
-- - -      para los casos donde la propiedad extranjera2 no sea NULL.

-- - Se usa ORDER BY para ordenar por número de solicitud y en segunda instancia por fecha de propiedad extranjera.



-- 5 *****************************************************************************************************************************
-- Consulta: Por mes, la lista de solicitantes que no presentaron marcas durante ese mes.
-- Descripción: Esta consulta muestra los solicitantes por mes que no hicieron solicitaron ningún registro de marcas, ordenados
--      por mes y por nombre del solicitante.
-- Autores: Gabriel De Ornelas, Cristina Gómez.
-- Fecha: 13 de Marzo de 2025.
-- Base de datos: Sistema de gestión de marcas (Postgresql).
-- *******************************************************************************************************************************

\echo '\nConsulta 5\n'

WITH meses AS (
    SELECT DISTINCT DATE_TRUNC('month', fecha_solicitud) AS mes
    FROM SOLICITUD
),
solicitantes_que_hicieron AS (
    SELECT DISTINCT 
        DATE_TRUNC('month', s.fecha_solicitud) AS mes,
        s.id_solicitante1 AS id_solicitante
    FROM SOLICITUD AS s
    WHERE s.id_solicitante1 IS NOT NULL

    UNION ALL

    SELECT DISTINCT 
        DATE_TRUNC('month', s.fecha_solicitud) AS mes,
        s.id_solicitante2 AS id_solicitante
    FROM SOLICITUD AS s
    WHERE s.id_solicitante2 IS NOT NULL

    UNION ALL

    SELECT DISTINCT 
        DATE_TRUNC('month', s.fecha_solicitud) AS mes,
        s.id_solicitante3 AS id_solicitante
    FROM SOLICITUD AS s
    WHERE s.id_solicitante3 IS NOT NULL
),
solicitantes_no_participaron AS (
    SELECT 
        m.mes,
        sol.id AS id_solicitante,
        sol.nombre AS nombre_solicitante,
        sol.pais_domicilio AS pais_domicilio
    FROM meses AS m
    CROSS JOIN SOLICITANTE AS sol
    LEFT JOIN solicitantes_que_hicieron AS sqh
        ON m.mes = sqh.mes AND sol.id = sqh.id_solicitante
    WHERE sqh.id_solicitante IS NULL
)
SELECT 
    TO_CHAR(mes, 'Mon-YYYY') AS "Mes",
    nombre_solicitante AS "Solicitante",
    pais_domicilio AS "Pais de domicilio"
FROM solicitantes_no_participaron
ORDER BY mes ASC, nombre_solicitante ASC;

-- Explicación:
-- - Se usa WITH para crear subconsultas de forma de generar 'tablas temporales' que nos ayudan más adelante.

-- - Entre esas subconsultas se crean las tablas:
-- - -'meses' que genera una tabla con los meses distintos (usando DISTINCT) presentes en fecha_solicitud de SOLICITUD.
-- - -'solicitantes_que_hicieron' que genera una tabla con los solicitantes que sí hicieron solicitudes almacenando el mes (con DATE_TRUNC)
-- - -      y el id de cada uno.
-- - -      Se usa UNION ALL para unir 3 consultas diferentes (por los 3 posibles ids asociados como solicitante de la solicitud)
-- - -'solicitantes_no_participaron' que obtiene los solicitantes que no participaron por mes de ninguna solicitud.
-- - -      Se hace un CROSS JOIN entre meses y SOLICITANTE, para tener la información de los meses y los todos los SOLICITANTES, luego
-- - -      a ese resultado se le hace LEFT JOIN con solicitantes_que_hicieron con la condición de que el mes y el id conincidan y luego
-- - -      se filtran los ids nulos, que serían los de solicitantes que NO hicieron solicitudes en ese mes.

-- - De solicitantes_no_participaron se imprime el mes, el nombre y el país de domicilio de cada solicitante, ordenado por mes y nombre.