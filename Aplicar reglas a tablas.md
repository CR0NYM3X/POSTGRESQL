# Bibliografía 
https://supabase.com/docs/guides/database/postgres/row-level-security#policies

 
### Rules (Reglas)

**Rules** son una característica de PostgreSQL que permite interceptar y modificar consultas SQL antes de que se ejecuten. Se utilizan principalmente para reescribir consultas o para implementar restricciones personalizadas.

#### Características de Rules:
- **Reescritura de consultas**: Puedes modificar la consulta original antes de que se ejecute.
- **Flexibilidad**: Puedes definir reglas para `INSERT`, `UPDATE`, `DELETE`, y `SELECT`.
- **Complejidad**: Las reglas pueden ser complejas y difíciles de mantener en sistemas grandes.

#### Ejemplo de Uso:
- **Auditoría**: Registrar cambios en una tabla sin modificar la lógica de la aplicación.
- **Restricciones personalizadas**: Implementar restricciones que no se pueden lograr con restricciones estándar de SQL.

### Row-Level Security (RLS)

**Row-Level Security (RLS)** es una característica que permite definir políticas de seguridad a nivel de fila. Esto significa que puedes controlar qué filas pueden ser vistas o modificadas por diferentes usuarios.

#### Características de RLS:
- **Seguridad a nivel de fila**: Controla el acceso a filas específicas en una tabla.
- **Políticas de seguridad**: Define políticas que determinan qué filas pueden ser accedidas por cada usuario.
- **Simplicidad**: Más fácil de entender y mantener en comparación con las reglas.

#### Ejemplo de Uso:
- **Multi-tenant applications**: Asegurar que los datos de diferentes clientes no se mezclen.
- **Seguridad**: Implementar controles de acceso detallados basados en roles de usuario.

### Comparación y Escenarios de Uso

| Característica | Rules | RLS |
|----------------|-------|-----|
| **Propósito** | Reescritura de consultas | Seguridad a nivel de fila |
| **Complejidad** | Alta | Baja |
| **Mantenimiento** | Difícil en sistemas grandes | Más fácil |
| **Escenarios** | Auditoría, restricciones personalizadas | Multi-tenant, seguridad detallada |

### Escenarios de Uso

- **Usa Rules** cuando necesites modificar o interceptar consultas SQL para implementar lógica personalizada o auditoría.
- **Usa RLS** cuando necesites implementar controles de acceso detallados a nivel de fila, especialmente en aplicaciones multi-tenant o donde la seguridad es crítica.

 


# Aplicando rules 
```sql

-- 1. EJEMPLO DE RULES
-- Implementa regla que si alguien intenta realizar un insert en la vista  "vista_empleados" redirecciona los insert a la tabla "empleados"
-- También se aplica regla para que no puedan realizar delete en la tabla 
-- Además registra la operación en una tabla de auditoría
-- Bibliografías : https://www.postgresql.org/docs/current/sql-createrule.html



-- Primero creamos las tablas necesarias
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    salario DECIMAL(10,2),
    departamento VARCHAR(50),
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


--- Creamos la tabla de  auditoria 
CREATE TABLE auditoria_empleados (
    id SERIAL PRIMARY KEY,
    operacion VARCHAR(20),
    usuario VARCHAR(50),
    fecha TIMESTAMP,
    detalles JSONB
);



-- Creamos una vista para los empleados
CREATE VIEW vista_empleados AS 
SELECT id, nombre, salario, departamento 
FROM empleados;



-- Creamos la regla que maneja las inserciones en la vista
CREATE OR REPLACE RULE insertar_empleado AS ON INSERT TO vista_empleados
DO INSTEAD (
    -- Insertar en la tabla base
    INSERT INTO empleados (nombre, salario, departamento) 
    VALUES (NEW.nombre, NEW.salario, NEW.departamento);
    
    -- Registrar en auditoría
    INSERT INTO auditoria_empleados (operacion, usuario, fecha, detalles)
    VALUES (
        'INSERT',
        current_user,
        current_timestamp,
        jsonb_build_object(
            'nombre', NEW.nombre,
            'salario', NEW.salario,
            'departamento', NEW.departamento
        )
    );
);


-- Restringimos el uso de delete 
CREATE RULE restrict_delete AS
ON DELETE TO empleados
DO INSTEAD NOTHING;



-- Creamos un rol para los gerentes y desarrollo
CREATE ROLE gerentes;
CREATE ROLE desarrollo;

-- Darle permisos al usuario para usar la vista 
grant select,update,insert ,delete on table empleados to gerentes; 
grant select,update,insert ,delete on table empleados to desarrollo; 
GRANT usage,select  ON SEQUENCE empleados_id_seq TO gerentes;
GRANT usage,select ON SEQUENCE empleados_id_seq TO desarrollo;
REVOKE TRUNCATE ON datos_generales FROM PUBLIC; -- No hay una regla directa para TRUNCATE, pero puedes revocar permisos

INSERT INTO vista_empleados (nombre, salario, departamento)
VALUES 
('Juan Pérez', 55000.00, 'Finanzas'),
('María López', 48000.00, 'Recursos Humanos'),
('Carlos García', 67000.00, 'Tecnología'),
('Ana Fernández', 53000.00, 'Marketing'),
('Luis Gómez', 72000.00, 'Ventas'),
('gerentes', 72000.00, 'Ventas');





postgres@postgres# select * from empleados;
+----+---------------+----------+------------------+----------------------------+
| id |    nombre     | salario  |   departamento   |     fecha_modificacion     |
+----+---------------+----------+------------------+----------------------------+
|  1 | Juan Pérez    | 55000.00 | Finanzas         | 2024-11-15 10:06:37.873278 |
|  2 | María López   | 48000.00 | Recursos Humanos | 2024-11-15 10:06:37.873278 |
|  3 | Carlos García | 67000.00 | Tecnología       | 2024-11-15 10:06:37.873278 |
|  4 | Ana Fernández | 53000.00 | Marketing        | 2024-11-15 10:06:37.873278 |
|  5 | Luis Gómez    | 72000.00 | Ventas           | 2024-11-15 10:06:37.873278 |
|  6 | gerentes      | 72000.00 | Ventas           | 2024-11-15 10:06:37.873278 |
+----+---------------+----------+------------------+----------------------------+
(6 rows)


postgres@postgres# select * from vista_empleados;
+----+---------------+----------+------------------+
| id |    nombre     | salario  |   departamento   |
+----+---------------+----------+------------------+
|  1 | Juan Pérez    | 55000.00 | Finanzas         |
|  2 | María López   | 48000.00 | Recursos Humanos |
|  3 | Carlos García | 67000.00 | Tecnología       |
|  4 | Ana Fernández | 53000.00 | Marketing        |
|  5 | Luis Gómez    | 72000.00 | Ventas           |
|  6 | gerentes      | 72000.00 | Ventas           |
+----+---------------+----------+------------------+
(6 rows)



postgres@postgres# select * from auditoria_empleados;
+----+-----------+----------+----------------------------+------------------------------------------------------------------------------------+
| id | operacion | usuario  |           fecha            |                                      detalles                                      |
+----+-----------+----------+----------------------------+------------------------------------------------------------------------------------+
|  1 | INSERT    | postgres | 2024-11-15 08:58:23.741375 | {"nombre": "Juan Pérez", "salario": 55000.00, "departamento": "Finanzas"}          |
|  2 | INSERT    | postgres | 2024-11-15 08:58:23.741375 | {"nombre": "María López", "salario": 48000.00, "departamento": "Recursos Humanos"} |
|  3 | INSERT    | postgres | 2024-11-15 08:58:23.741375 | {"nombre": "Carlos García", "salario": 67000.00, "departamento": "Tecnología"}     |
|  4 | INSERT    | postgres | 2024-11-15 08:58:23.741375 | {"nombre": "Ana Fernández", "salario": 53000.00, "departamento": "Marketing"}      |
|  5 | INSERT    | postgres | 2024-11-15 08:58:23.741375 | {"nombre": "Luis Gómez", "salario": 72000.00, "departamento": "Ventas"}            |
| 6 | INSERT    | postgres | 2024-11-15 10:06:37.873278 | {"nombre": "gerentes", "salario": 72000.00, "departamento": "Ventas"}              |
+----+-----------+----------+----------------------------+------------------------------------------------------------------------------------+


postgres@postgres# set role gerentes ;
SET
Time: 0.381 ms


postgres@postgres> delete from  empleados ; -- no le permite borrar 
DELETE 0
Time: 0.408 ms


postgres@postgres>  select * from empleados;
+----+----------+----------+--------------+----------------------------+
| id |  nombre  | salario  | departamento |     fecha_modificacion     |
+----+----------+----------+--------------+----------------------------+
|  6 | gerentes | 72000.00 | Ventas       | 2024-11-15 10:06:37.873278 |
+----+----------+----------+--------------+----------------------------+
(1 row)





--- Validar rules aplicadas 
SELECT * FROM pg_catalog.pg_rules;


``` 



# aplicando RLS Row-Level Security (RLS)
```sql 


-- 2. EJEMPLO DE ROW LEVEL SECURITY (RLS)
-- Este ejemplo implementa políticas de seguridad a nivel de fila para que los usuarios
-- solo puedan ver y modificar registros de su propio departamento
-- Crear Funciones personalizadas para limitar accesos en horarios específicos 
-- Bibliografías : https://www.postgresql.org/docs/current/sql-createpolicy.html

-- Habilitamos RLS en la tabla
ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;


-- Política para ver registros
-- drop  POLICY ver_empleados_departamento on empleados; 
CREATE POLICY ver_empleados_departamento ON empleados
    FOR SELECT
    --TO gerentes -- esto si quieres pasarle un usuario 
    USING (nombre = current_user);


-- Crear politica que  solo permita que los gerentes realicen insert 
CREATE POLICY insert_policy ON empleados
FOR INSERT
WITH CHECK (current_user = 'gerentes');




-- Crear Funciones personalizadas para limitar accesos en horarios específicos 
CREATE OR REPLACE FUNCTION restrict_access()
RETURNS boolean AS $$
DECLARE
	v_start_time time := '14:00';
	v_end_time time := '18:00';
BEGIN
    IF (current_user != 'gerentes' AND now()::time BETWEEN v_start_time AND v_end_time) THEN
        RAISE EXCEPTION 'Access restricted during this time % - %  ',v_start_time, v_end_time;
	else 
	--	RAISE NOTICE 'Aaaaaaaaaaa % - % ',v_start_time, v_end_time  ;
    END IF;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql set client_min_messages = notice ;



CREATE POLICY time_based_access
-- FOR ALL
-- FOR SELECT
ON empleados USING (restrict_access());



postgres@postgres# set role gerentes ;
SET
Time: 0.325 ms
 
postgres@postgres> select * from empleados; 
+----+----------+----------+--------------+----------------------------+
| id |  nombre  | salario  | departamento |     fecha_modificacion     |
+----+----------+----------+--------------+----------------------------+
|  6 | gerentes | 72000.00 | Ventas       | 2024-11-15 10:06:37.873278 |
+----+----------+----------+--------------+----------------------------+
(1 row)




postgres@postgres# set role desarrollo;
SET
Time: 0.431 ms
 
postgres@postgres> INSERT INTO empleados (nombre, salario, departamento) VALUES ('Maria', 55000.00, 'Finanzas');
ERROR:  new row violates row-level security policy for table "empleados"
Time: 0.859 ms


postgres@postgres> select * from empleados;
ERROR:  Access restricted during this time 14:00:00 - 18:00:00
CONTEXT:  PL/pgSQL function restrict_access() line 7 at RAISE
Time: 1.246 ms



---- Ver las politicas 
SELECT * FROM pg_policies;

```



#### SECURITY LABEL con sepgsql — SELinux

```sql

-- -- Los Security Labels en PostgreSQL se usan principalmente para:
-- de los datos y controlar el acceso basado en niveles de autorización
-- 1. Clasificación de datos según niveles de sensibilidad
-- 2. Integración con sistemas de control de acceso externos
-- 3. Cumplimiento normativo y auditoría

-- Formato de las etiquetas de seguridad SELinux:
-- system_u:object_r:tipo_t:nivel
-- Donde:
-- - system_u: Usuario SELinux (system_user)
-- - object_r: Rol SELinux (object_role)
-- - tipo_t: Tipo de objeto
-- - nivel: Nivel de sensibilidad (s0, s1, etc.) y categorías (c0, c1, etc.)


https://www.joeconway.com/presentations/mls-postgres-scale14x-2016.pdf
https://www.postgresql.org/docs/current/sepgsql.html


# Validar si estan los paquetes necesarios 
[postgres@TEST_SERVER data15]$ rpm -qa | grep -Ei "libselinux-devel|selinux-policy"
libselinux-devel-2.9-8.el8.x86_64
selinux-policy-3.14.3-139.el8_10.noarch
selinux-policy-targeted-3.14.3-139.el8_10.noarch

# Validar si esta instalado en postgres
[postgres@TEST_SERVER lib]$ ls /usr/pgsql-16/lib  | grep sepgsql
sepgsql.so


# Validar si esta activado 
[postgres@TEST_SERVER lib]$  sestatus
SELinux status:                 enabled


shared_preload_libraries = 'sepgsql'



for DBNAME in template0 template1 postgres; do
    /usr/pgsql-15/bin/postgres  --single  -D $PGDATA15 -F -c exit_on_error=true $DBNAME \
      </usr/pgsql-15/share/contrib/sepgsql.sql >/dev/null
done


 



 --- Ver los security label
SELECT * FROM pg_seclabel; 



```




####  Info Extra 

```sql


Opciones DO INSTEAD ( Reemplaza la operación original con una operación alternativa.) : 
 
 

DO INSTEAD NOTHING --> evita que la operación original ocurra 

CREATE RULE example_rule AS
ON INSERT TO example_table
DO INSTEAD NOTHING;



DO INSTEAD SELECT  --> Reemplaza la operación original con una consulta SELECT

CREATE RULE example_rule AS
ON INSERT TO example_table
DO INSTEAD 
SELECT 'Inserts are not allowed' AS message;



DO ALSO 			--> Realiza una operación adicional además de la operación original.

CREATE RULE example_rule AS
ON UPDATE TO example_table
DO ALSO 
INSERT INTO log_table (old_value, new_value) VALUES (OLD.value, NEW.value);




CREATE RULE notify_me AS
ON UPDATE TO empleados
DO ALSO NOTIFY empleados;


CREATE OR REPLACE FUNCTION notify_trigger_function() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('empleados', row_to_json(NEW)::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER notify_trigger
AFTER UPDATE ON empleados
FOR EACH ROW
EXECUTE FUNCTION notify_trigger_function();


--------------


El LEAKPROOF de las funciones: Esto afecta la forma en que el sistema ejecuta consultas contra vistas creadas con la opción security_barrier o tablas con seguridad de nivel de fila habilitada.

 
```

 

# security_barrier en vistas 
se utiliza para crear vistas que aseguren que las condiciones(Where/ RLS) de seguridad que se encuentran dentro de la vista creadas por el Admin o desarrollados  se ejecuten antes que las condiciones(Where) agregada por el usuario que ejecuta o usa la vista . Esto es crucial para evitar que los usuarios obtengan acceso no autorizado a los datos a través de técnicas de inferencia
 
```
https://www.cybertec-postgresql.com/en/security-barriers-cheating-on-the-planner/
 

CREATE FUNCTION slow_func(int4) RETURNS int4 AS $$
BEGIN
                EXECUTE 'SELECT pg_sleep(1)';
                RAISE NOTICE 'slow_func: %', $1;
                RETURN $1;
END;
$$ LANGUAGE 'plpgsql' 
        IMMUTABLE
        COST  10;
		
		
		
CREATE FUNCTION fast_func(int4) RETURNS int4 AS $$
        BEGIN
                RAISE NOTICE 'fast_func: %', $1;
                RETURN $1;
        END;
$$ LANGUAGE 'plpgsql' 
        IMMUTABLE
        COST  100;
		
		
		
CREATE TABLE t_test (id int4);
INSERT INTO t_test SELECT * FROM generate_series(1, 20);

select * from t_test;

 
CREATE VIEW v AS
        SELECT  *
        FROM    t_test
        WHERE   id % 2 = 0
                AND fast_func(id) = 0;
				
				
				
SELECT * FROM v WHERE slow_func(id) = 0;


drop VIEW v ;  

CREATE VIEW v WITH (security_barrier) AS  
        SELECT  *
        FROM    t_test
        WHERE   id % 2 = 0
                AND fast_func(id) = 0;
				
				
				
SELECT * FROM v WHERE slow_func(id) = 0;
```

# Temas  Importantes : 
```
Abusing SECURITY DEFINER functions in PostgreSQL : https://www.cybertec-postgresql.com/en/abusing-security-definer-functions/
security_invoker Vistas  : https://www.cybertec-postgresql.com/en/view-permissions-and-row-level-security-in-postgresql/
Abusing PostgreSQL as an SQL beautifier : https://www.cybertec-postgresql.com/en/abusing-postgresql-as-an-sql-beautifier/
Tag: security: https://www.cybertec-postgresql.com/en/tag/security/

```
