
# `pglogical` 
Es una **extensión avanzada para PostgreSQL** que permite realizar **replicación lógica** entre bases de datos PostgreSQL, con capacidades que van más allá de la replicación lógica nativa incluida en PostgreSQL desde la versión 10.

---

##  ¿Qué es `pglogical`?

Es una solución de **replicación lógica basada en publicaciones y suscripciones**, desarrollada originalmente por **2ndQuadrant** (ahora parte de EDB – EnterpriseDB). Está diseñada para ofrecer **replicación más flexible, granular y potente** que la replicación lógica nativa.

---

##  ¿Qué se puede hacer con `pglogical`?

| Funcionalidad | Descripción |
|---------------|-------------|
|  **Replicación unidireccional o bidireccional** | Puedes replicar datos de un nodo a otro o entre ambos (multi-maestro). |
|  **Replicación selectiva** | Puedes elegir qué tablas, columnas o incluso filas replicar. |
|  **Replicación de DDL** | Puede replicar cambios de esquema (CREATE TABLE, ALTER, etc.) si se configura. |
|  **Sincronización en caliente** | Permite migraciones sin downtime entre servidores PostgreSQL. |
|  **Topologías complejas** | Soporta replicación en cascada, en estrella, y multi-nodo. |
|  **Integración con herramientas de HA** | Compatible con soluciones como Patroni, Barman, etc. |


 
### **Servidor Publicador**
El **publicador** es el servidor que tiene los datos originales y que los pone a disposición para ser replicados. Es el que define qué tablas o conjuntos de datos estarán disponibles para los suscriptores. Se encarga de:
- Mantener la fuente de los datos.
- Definir los **sets de replicación**, que agrupan las tablas que serán replicadas.
- Enviar los cambios a los suscriptores en forma de eventos (inserciones, actualizaciones y eliminaciones).
 

### **Servidor Suscriptor**
El **suscriptor** es el servidor que recibe los datos replicados desde el publicador. Este servidor se suscribe a los conjuntos de replicación definidos por el publicador y aplica los cambios en su propia copia de la base de datos. Se encarga de:
- Recibir los datos del publicador.
- Aplicar las modificaciones para mantenerse sincronizado.
- No afectar el servidor publicador con sus cambios (a menos que haya configuraciones adicionales).




##  Laboratorio: Replicación Direcional y despues Multi-Maestro con `pglogical`

###  Requisitos

- PostgreSQL 14 o superior
- Extensión `pglogical` instalada en ambos nodos
- Dos instancias PostgreSQL (pueden ser contenedores, VMs o servidores físicos)
- Acceso de red entre ambos nodos

---

#  Configuración inicial 


### Crear carpetas 
```bash
mkdir /sysx/data16/DATANEW/data_maestro1
mkdir /sysx/data16/DATANEW/data_maestro2
```

### Inicializar datas 
```bash
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_maestro1 --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_maestro2 --data-checksums  &>/dev/null
```

#### `configurar postgresql.conf`

```conf
# Habilita la nivel de wal logico
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_maestro1/postgresql.auto.conf
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_maestro2/postgresql.auto.conf

# Cargar la liberia citus en todos los nodos 
echo "shared_preload_libraries = 'pglogical'" >> /sysx/data16/DATANEW/data_maestro1/postgresql.auto.conf
echo "shared_preload_libraries = 'pglogical'" >> /sysx/data16/DATANEW/data_maestro2/postgresql.auto.conf

# Cambiar los puertos en cada nodo
echo "port = 55161" >> /sysx/data16/DATANEW/data_maestro1/postgresql.auto.conf
echo "port = 55162" >> /sysx/data16/DATANEW/data_maestro2/postgresql.auto.conf

# Permitir las conexiones externas 
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_maestro1/postgresql.auto.conf
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_maestro2/postgresql.auto.conf
```

####  `configurar pg_hba.conf`

Permitir replicación entre nodos:

```conf
host    all             all             0.0.0.0/0               trust
host    replication     all             0.0.0.0/0               trust
```

#### `Iniciar el servicio`
```bash
/usr/pgsql-16/bin/pg_ctl start -D  /sysx/data16/DATANEW/data_maestro1
/usr/pgsql-16/bin/pg_ctl start -D  /sysx/data16/DATANEW/data_maestro2
```

 
###  Crear usuario y base de datos
En ambos nodos:
```bash
 psql -p 55161 -c "CREATE USER user_replicador WITH REPLICATION superuser PASSWORD '123123'; "
 psql -p 55162 -c "CREATE USER user_replicador WITH REPLICATION superuser PASSWORD '123123'; "
```
 
###  Crear la extensión `pglogical`
En ambos nodos:

```sql
psql -p 55161 -c "CREATE EXTENSION pglogical;"
psql -p 55162 -c "CREATE EXTENSION pglogical;"
```

###  Crear tabla en servidor publicador
 psql -p 55161
```sql
CREATE TABLE prueba_datos (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    valor INTEGER,
    fecha_creacion TIMESTAMP DEFAULT NOW()
);
```

---

# Configurar pgLogical básica 

#### En **Nodo A**:

```sql
-- crear el nodo donde indicas la ip del servidor del noda A 
SELECT pglogical.create_node(
         node_name := 'publicador',
         dsn := 'host=127.0.0.1 port=55161 sslmode=prefer dbname=postgres user=user_replicador'
         );

-- Indicar como se va llamar la replica, esto sirve para crear como un tipo grupo 
SELECT pglogical.create_replication_set( set_name := 'replica_set', replicate_insert := TRUE, replicate_update := TRUE, replicate_delete := TRUE, replicate_truncate := TRUE);

-- Todas las tablas del esquema public serán incluidas en el replication 
SELECT pglogical.replication_set_add_all_tables('replica_set', ARRAY['public']);


-- Opcional en caso de querer replicar solo una tabla 
/*
SELECT pglogical.replication_set_add_table(
    set_name := 'replica_set',
    relation := 'public.mi_tabla',
    synchronize_data := true
);
*/

```

#### En **Nodo B**:

```sql
-- crear el nodo donde indicas la ip del servidor del noda B
SELECT pglogical.create_node(
         node_name := 'suscriptor',
         dsn := 'host=127.0.0.1 port=55162 sslmode=prefer dbname=postgres user=user_replicador'
         );


-- Creamos la suscripcion al publicador. 
SELECT pglogical.create_subscription(
         subscription_name := 'nodo_suscriptor',
         provider_dsn :=  'host=127.0.0.1 port=55161 sslmode=prefer dbname=postgres user=user_replicador',
         forward_origins := '{}',
         synchronize_data := true,
         replication_sets := ARRAY['replica_set'],
         synchronize_structure := true
         );

```


### Insertar registros en nodo A como ejemplo
```
INSERT INTO prueba_datos (nombre, valor)
SELECT 
    'Nombre_' || g AS nombre,
    (RANDOM() * 1000)::INT AS valor
FROM generate_series(1, 10000) AS g;

select count(*) from prueba_datos;
+-------+
| count |
+-------+
| 10000 |
+-------+
(1 row)
 ```








###  Crear suscripciones cruzadas (multi-maestro)

#### En **Nodo A**:

```sql
SELECT pglogical.create_subscription(
         subscription_name := 'subscriberA', 
         provider_dsn :=  'host=127.0.0.1 port=55162 sslmode=prefer dbname=postgres user=user_replicador',
         replication_sets := ARRAY['replica_set'],
         forward_origins := '{}',
         synchronize_structure := true,
         synchronize_data := true);

-- subscription_name ->  nombre local de la suscripción.
-- provider_dsn ->  Agregar cadena de conexión (DSN) del nodo B proveedor.
-- replication_sets -> Indicas como se configura el nombre de la replica en el publicador.
-- forward_origins -> Define desde qué orígenes se deben reenviar los cambios. Útil para evitar bucles en replicación bidireccional.
-- synchronize_structure -> intentará replicar la estructura de las tablas, índices y restricciones desde el publicador al suscriptor antes de comenzar la replicación de datos. Después de la creación de la suscripción, no se vuelve a ejecutar automáticamente. Si realizas cambios en la estructura de las tablas en el publicador después de la sincronización inicial, deberás asegurarte manualmente de que esos cambios también se reflejen en el suscriptor.
-- synchronize_data ->  el suscriptor sincroniza los datos existentes desde el proveedor al momento de crear la suscripción. Si es false, solo se replicarán los cambios futuros. 
```





### Querys para validar información 
 ```
select * from pglogical.tables;
select * from pglogical.node; 
SELECT * FROM pglogical.show_subscription_status();
select * from pglogical.replication_set_table;
select * from pglogical.local_sync_status;
select * from pglogical.depend;


SELECT pglogical.replicate_ddl_command('ALTER TABLE public.people ADD COLUMN notes TEXT');

select pglogical.drop_subscription('subscriptionB');
SELECT pglogical.drop_node('maestro1');


SELECT pglogical.synchronize_sequence(seqoid) FROM pglogical.sequence_state;
select pglogical.alter_subscription_disable('subscriber_name');
SELECT slot_name, confirmed_flush_lsn from pg_replication_slots  ;
SELECT * FROM pg_stat_replication;

 ```




---

### Eliminar laboratorio
```sql
/usr/pgsql-16/bin/pg_ctl stop -D  /sysx/data16/DATANEW/data_maestro1
/usr/pgsql-16/bin/pg_ctl stop -D  /sysx/data16/DATANEW/data_maestro2
rm -r /sysx/data16/DATANEW/data_maestro1
rm -r /sysx/data16/DATANEW/data_maestro2

```

###  Consideraciones importantes

- **Conflictos**: pglogical no resuelve conflictos automáticamente. Debes evitar colisiones de claves primarias.
- **Esquema**: ambos nodos deben tener el mismo esquema.
- **Cambios DDL**: deben aplicarse manualmente o usando `pglogical.replicate_ddl_command`.
- Evita conflictos de escritura simultánea en las mismas filas desde ambos nodos.
- Puedes usar `forward_origins` para evitar bucles de replicación.
- Asegúrate de que las claves primarias estén bien definidas en todas las tablas replicadas.

---

### Blibliografia 
```sql

pglogical -> https://github.com/2ndQuadrant/pglogical
Bidirectional replication in PostgreSQL using pglogical -> https://www.jamesarmes.com/2023/03/bidirectional-replication-postgresql-pglogical.html
pglogical -> https://gist.github.com/edib/402d7d29d54a025265c2a5b4d0ee7fe6
PostgreSQL pglogical extension -> https://docs.aws.amazon.com/dms/latest/sbs/chap-manageddatabases.postgresql-rds-postgresql-full-load-pglogical.html
Setting up replication in PostgreSQL with pglogical -> https://medium.com/@Navmed/setting-up-replication-in-postgresql-with-pglogical-8212e77ebc1b
Migración PostgreSQL con pglogical -> https://ifgeekthen.nttdata.com/s/post/migracion-postgresql-con-pglogical-MCVUL3MI2E7ZBZZEEES64PSP5UEA?language=es
Using pglogical for Logical Replication -> https://www.tencentcloud.com/document/product/409/64755
How to Use pglogical for Bidirectional Replication in PostgreSQL with Conflict Handling -> https://www.cybrosys.com/research-and-development/postgres/how-to-use-pglogical-for-bidirectional-replication-in-postgresql-with-conflict-handling

```
