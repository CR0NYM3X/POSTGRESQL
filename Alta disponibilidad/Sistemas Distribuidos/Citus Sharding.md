**Citus** es una extensión de PostgreSQL que permite **escalar bases de datos distribuidas**, ideal para manejar grandes volúmenes de datos y mejorar el rendimiento en sistemas con múltiples nodos. Algunas de sus aplicaciones clave incluyen:

- **Sharding automático**: Divide los datos en múltiples nodos para distribuir la carga y mejorar la velocidad de consulta.
- **Replicación y alta disponibilidad**: Permite configurar réplicas para garantizar la continuidad del servicio en caso de fallos.
- **Paralelización de consultas**: Ejecuta consultas en múltiples nodos simultáneamente, reduciendo tiempos de respuesta.
- **Balanceo de carga**: Distribuye las consultas entre los nodos para evitar sobrecarga en un solo servidor.
- **Optimización para análisis de datos**: Mejora el rendimiento en consultas analíticas y agregaciones en grandes volúmenes de información.

 ### **¿Cómo funciona Citus en un sistema distribuido?**
Citus convierte **PostgreSQL en una base de datos distribuida** al dividir los datos en múltiples nodos (**sharding**) y ejecutando consultas en paralelo. En un sistema **Citus distribuido**, hay dos componentes clave:

1. **Coordinador** → Es el nodo principal que recibe las consultas y las distribuye a los **workers**.
2. **Workers** → Almacenan fragmentos de las tablas y procesan las consultas asignadas por el coordinador.

**[NOTA]** -> Citus permite UPDATE y DELETE en los workers si los datos ya están ahí. Sin embargo, las inserciones deben controlarse desde el coordinador para garantizar la correcta distribución.

#### **🔹 ¿Cómo se distribuyen los datos en Citus?**
Cuando creas una tabla distribuida con `create_distributed_table()`, Citus **divide los registros en shards** y los asigna a distintos workers. Así, en lugar de almacenar toda la tabla en un solo servidor, los datos se distribuyen entre los nodos.

  **Ejemplo de flujo en Citus**
- **Inserción de datos** → El Coordinador decide en qué Worker debe ir cada fila.
- **Consultas** → El Coordinador consulta a los Workers y combina los resultados.
- **Paralelismo** → Cada Worker procesa parte de la carga, mejorando el rendimiento.

### **Qué es  shard?** 
Es un fragmento de una tabla distribuida que se almacena en los workers. Citus automáticamente asigna y gestiona estos shards, pero no los trata como tablas convencionales en el catálogo de PostgreSQL (pg_class).

---

### **🖥️ Escenario del laboratorio**
Imagina que tienes **tres servidores** en una red privada que formarán el clúster:
- **Coordinador**: 192.168.1.100 *(Maneja las consultas y distribuye los datos)*
- **Worker 1**: 192.168.1.101 *(Almacena parte de los datos y ejecuta queries)*
- **Worker 2**: 192.168.1.102 *(Otro nodo de almacenamiento y ejecución)*

Este esquema permitirá repartir la carga de trabajo y escalar el sistema de manera eficiente.

 
### **🔹 2. ¿Cuáles son las restricciones en Citus?**
- **Las consultas deben ejecutarse en el Coordinador**: Solo el Coordinador puede distribuir datos y manejar la lógica de consulta distribuida.
- **Las tablas deben estar distribuidas** con `create_distributed_table()`, de lo contrario, funcionarán como tablas normales en PostgreSQL.
- **Algunas operaciones están limitadas**: Las transacciones distribuidas son posibles, pero tienen restricciones en operaciones como `FOREIGN KEYS` y `SEQUENCES`.
- **Esquema centralizado**: Cualquier cambio en el esquema (`ALTER TABLE`, `CREATE INDEX`, etc.) debe hacerse en el Coordinador y luego aplicarse a los Workers.


---

### **🔹 Conceptos clave**
- **Coordinador**: Nodo principal que recibe las consultas y las distribuye a los workers.
- **Workers**: Servidores que almacenan los datos de manera distribuida y procesan consultas en paralelo.
- **Sharding**: Técnica para dividir los datos en fragmentos y distribuirlos entre múltiples nodos.
- **Distribución**: Citus divide las tablas en varias partes y las asigna a los workers.

---

## **⚙️ Paso 1: Instalación en cada nodo**
Todos los servidores (coordinador y workers) deben tener PostgreSQL y Citus instalados.

### **En cada nodo (192.168.1.100, 192.168.1.101, 192.168.1.102)**
1. **Habilitar la extensión Citus en el  y los worker**
   ```sql
   CREATE EXTENSION citus;
   ```
2. **Configurar PostgreSQL para aceptar conexiones remotas**
   En **postgresql.conf**, modifica:
   ```bash
   listen_addresses = '*'
   ```

3. **Configurar permisos en pg_hba.conf**
   Agrega estas líneas en todos los nodos para permitir conexiones internas:
   ```
   host    all    all    192.168.1.100/32    trust
   host    all    all    192.168.1.101/32    trust
   host    all    all    192.168.1.102/32    trust
   ```

4. **Reiniciar PostgreSQL**
   ```bash
   sudo systemctl restart postgresql
   ```

---




## ** Paso 2: Configurar el Coordinador (192.168.1.100)**
1. **Agregar los workers al clúster y indicar quien es el coordinador**
   ```sql
   SELECT citus_set_coordinator_host('192.168.1.100', 5432);
   SELECT * FROM citus_add_node('192.168.1.101', 5432);
   SELECT * FROM citus_add_node('192.168.1.102', 5432);
   ```

 
2. ** Crear una tabla distribuida**
En el **coordinador (192.168.1.100)**:
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);

SELECT create_distributed_table('users', 'id');
```

Esto hará que los datos se almacenen en **Worker 1 y Worker 2**, dividiendo los registros según la clave `id`.

---

3. ** Insertar datos y consultar la distribución**
Prueba insertando registros desde el coordinador:
```sql
--INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com'), ('Bob', 'bob@example.com');

INSERT INTO users (name, email)
SELECT 
  INITCAP(left(md5(random()::text), 8)),  -- Genera nombres aleatorios con formato capitalizado
  left(md5(random()::text), 10) || '@' || 
  (ARRAY['gmail.com', 'yahoo.com', 'outlook.com', 'example.com'])[random() * 4 + 1]
FROM generate_series(1, 10000);


SELECT * FROM users limit 20;
```

Citus distribuirá automáticamente los registros entre los workers.

---


4. **Verificar que los nodos están conectados**
   Desde el coordinador:
   ```sql
   SELECT * FROM citus_get_active_worker_nodes();
   ```


## Info extra 
```
postgres@postgres# \dx+ citus

```

## Guia rápida 
```sql
# Crear directorios donde esta los datas 
mkdir -p  /sysx/data16/DATANEW/data_coordinador
mkdir -p  /sysx/data16/DATANEW/data_worker1
mkdir -p  /sysx/data16/DATANEW/data_worker2

# Iniciarlizar el data 
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_coordinador --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker1 --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker2 --data-checksums  &>/dev/null

# Cambiar los puertos 
echo "port = 55164" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "port = 55165" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "port = 55166" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf

# Cargar la liberia citus en todos los nodos 
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf

# Iniciar el servicio de todos los nodos 
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_coordinador
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker1
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker2

# Habilitar la extension en todos los nodos 
psql -p 55164 -c "CREATE EXTENSION citus;"
psql -p 55165 -c "CREATE EXTENSION citus;"
psql -p 55166 -c "CREATE EXTENSION citus;"


--# Configurar el coordinador 
SELECT citus_set_coordinator_host('127.0.0.1', 55164);

--# en el servidor coordinador Indicar quien son los workers 
SELECT * FROM citus_add_node('127.0.0.1', 55165);
SELECT * FROM citus_add_node('127.0.0.1', 55166);

-- # en el servidor coordinador Ver los nodos workers 
SELECT * FROM citus_get_active_worker_nodes();

-- en el servidor coordinador Crear tabla 
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);

-- en el servidor coordinador Inidcar que distribuya la tabla con la columna id 
SELECT create_distributed_table('users', 'id');

-- en el servidor coordinador Incertar datos 
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com'), ('Bob', 'bob@example.com');

-- consultar los datos 
psql -p 55164 -c "SELECT * FROM users;" 
psql -p 55165 -c "SELECT * FROM users;" 
psql -p 55166 -c "SELECT * FROM users;" 

-- Lugar donde se guardaron los datos 
postgres@postgres# SELECT 'select * from ' || shard_name || '; -- Ejecutar en Server: ' || nodename || ' - Port: ' ||nodeport FROM citus_shards where shard_size != 16384;
+----------------------------------------------------------------------------+
|                                  ?column?                                  |
+----------------------------------------------------------------------------+
| select * from users_102009; -- Ejecutar en Server: 127.0.0.1 - Port: 55166 |
| select * from users_102023; -- Ejecutar en Server: 127.0.0.1 - Port: 55166 |
| select * from users_102032; -- Ejecutar en Server: 127.0.0.1 - Port: 55165 |
+----------------------------------------------------------------------------+
(3 rows)


-- Querys monitoreo
SELECT p.nodename, p.nodeport,s.* FROM pg_dist_shard s JOIN pg_dist_shard_placement p ON s.shardid = p.shardid;
SELECT * FROM citus_shards;
SELECT * FROM citus_stat_statements  LIMIT 10;
SELECT * FROM citus_stat_activity;
SELECT * FROM citus_tables;
SELECT * FROM pg_dist_partition;
SELECT * from pg_dist_placement;

 

--- Borrar el laboratorio 
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_coordinador
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_worker1
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_worker2

rm -r  /sysx/data16/DATANEW/data_coordinador
rm -r  /sysx/data16/DATANEW/data_worker1
rm -r  /sysx/data16/DATANEW/data_worker2
```

## Bibliografía
```
https://docs.citusdata.com/en/v10.2/cloud/availability.html
https://www.citusdata.com/blog/2018/02/21/three-approaches-to-postgresql-replication/
https://github.com/citusdata/citus
Citus 12: Schema-based sharding for PostgreSQL -> https://www.citusdata.com/blog/2023/07/18/citus-12-schema-based-sharding-for-postgres/
Sharding Postgres on a single Citus node, how why & when -> https://www.citusdata.com/blog/2021/03/20/sharding-postgres-on-a-single-citus-node/
Citus 11.1 shards your Postgres tables without interruption -> https://www.citusdata.com/blog/2022/09/19/citus-11-1-shards-postgres-tables-without-interruption/

citus — distributed database and columnar storage functionality  -> https://postgrespro.com/docs/enterprise/16/citus.html
Postgres + Citus + Partman, Your IoT Database -> https://www.crunchydata.com/blog/postgres-citus-partman-your-iot-database
Citus: Sharding your first table -> https://www.cybertec-postgresql.com/en/citus-sharding-your-first-table/
Citus: The Misunderstood Postgres Extension -> https://www.crunchydata.com/blog/citus-the-misunderstood-postgres-extension


Scaling Horizontally on PostgreSQL: Citus’s Impact on Database Architecture -> https://demirhuseyinn-94.medium.com/scaling-horizontally-on-postgresql-cituss-impact-on-database-architecture-295329c72c62
Insights from paper: Citus: Distributed PostgreSQL for Data-Intensive Applications -> https://hemantkgupta.medium.com/insights-from-paper-citus-distributed-postgresql-for-data-intensive-applications-6224a12af32d
Scaling PostgreSQL with Citus: A Practical Guide -> https://oluwatosin-amokeodo.medium.com/scaling-postgresql-with-citus-a-practical-guide-14d86c87ccfb
Debezium’s adventures with Citus -> https://robert-ganowski.medium.com/debeziums-adventures-with-citus-a5883cc60856
Sharding PostgreSQL with Citus and Golang -> https://medium.com/@bhadange.atharv/sharding-postgresql-with-citus-and-golang-on-gofiber-21a0ef5efb30
Multi-Node Setup using Citus -> https://medium.com/@bhadange.atharv/citus-multi-node-setup-69c900754da3
How to find table size in Citus? -> https://medium.com/@smaranraialt/table-size-in-citus-c1fb579159fb
Mastering PostgreSQL Scaling: A Tale of Sharding and Partitioning -> https://doronsegal.medium.com/scaling-postgres-dfd9c5e175e6
Scaling for millions: PostgreSQL -> https://medium.com/@sabawasim.it/scaling-for-millions-postgresql-4898acfb0abe
Data Redundancy With the PostgreSQL Citus Extension -> https://www.percona.com/blog/data-redundancy-with-the-postgresql-citus-extension/

PostgreSQL: 1 trillion rows in Citus -> https://www.cybertec-postgresql.com/en/postgresql-1-trillion-rows-in-citus/

Bases de datos distribuidas PostgreSQL al límite -> https://www.youtube.com/watch?v=5SZVJgg94k4

```
