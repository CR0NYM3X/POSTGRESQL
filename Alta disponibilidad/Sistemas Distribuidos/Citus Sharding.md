**Citus** es una extensión de PostgreSQL que permite **escalar bases de datos distribuidas**, ideal para manejar grandes volúmenes de datos y mejorar el rendimiento en sistemas con múltiples nodos. Citus usa logical decoding para mover datos entre nodos.  

### **¿Por qué esto es potente?**
1. **Escalabilidad horizontal** → En lugar de que un solo servidor maneje toda la carga, los datos se distribuyen en múltiples workers, mejorando el rendimiento.
2. **Procesamiento paralelo** → Las consultas se ejecutan en todos los workers simultáneamente, reduciendo los tiempos de respuesta.
3. **Carga distribuida** → Si tienes millones de registros, cada worker maneja solo una parte, evitando que el coordinador se convierta en un cuello de botella.
4. **Alta disponibilidad** → Si un worker falla, los shards pueden reasignarse, evitando pérdida de datos y permitiendo recuperación rápida.


 ### **Conceptos clave de Citus**
  
1. **Coordinador** → Es el nodo principal que recibe las consultas y  distribuye la consulta a los **workers nodes**. El coordinador no almacena los datos, solo dirige las consultas hacia los workers. el coordinador es donde se administra la distribucion y se consulta la información, por lo tanto ahí solo se debe hacer los UPDATE,DELETE , INSERT.
2. **Workers** → Almacenan fragmentos shard de la tabla  y procesan las consultas asignadas por el coordinador, asi dividiendo el trabajo en varios nodos. también se puede consultar las tablas desde los worker
3. **sharding** → Es el proceso de dividir una tabla grande en muchas tablas más pequeñas (fragmentos o shards) y repartirlas entre los nodos trabajadores. Citus automáticamente asigna y gestiona estos shards en cada worker node, pero no los trata como tablas convencionales en el catálogo de PostgreSQL (pg_class).

#### **🔹 ¿Cómo se distribuyen los datos en Citus?**
Cuando creas una tabla distribuida con `create_distributed_table()`, Citus **divide los registros en shards** y los asigna a distintos workers nodes. Así, en lugar de almacenar toda la tabla en un solo servidor, los datos se distribuyen entre los nodos.

  **Ejemplo de flujo en Citus**
- **Inserción de datos** → El Coordinador decide en qué Worker debe ir cada fila.
- **Consultas** → El Coordinador consulta a los Workers y combina los resultados.
- **Paralelismo** → Cada Worker procesa parte de la carga, mejorando el rendimiento.

 
## **Qué pasa si un **worker node** se pierde**
los datos que estaban en ese nodo pueden volverse inaccesibles**, afectando las consultas distribuidas. 

### **🔹 Impacto de perder un worker**
📌 **Si un worker falla, ocurre lo siguiente:**  
1. **Las consultas que dependen de los shards en ese nodo pueden fallar**, mostrando errores de conexión.  
2. **El coordinador seguirá funcionando**, pero no podrá recuperar datos almacenados en el nodo caído.  
3. **Si la tabla distribuida es replicada, otro nodo puede asumir la carga y evitar pérdida de datos.**  


 

### **🖥️ Escenario del laboratorio**
Imagina que tienes **cuatro servidores** en una red privada que formarán el clúster, Este esquema permitirá repartir la carga de trabajo y escalar el sistema de manera eficiente.

- **Coordinador**: 127.0.0.1 Puerto 55164 *(Maneja las consultas y distribuye los datos)*
- **Worker 1**: 127.0.0.1 Puerto 55165 *(Almacena parte de los datos y ejecuta queries)*
- **Worker 2**: 127.0.0.1 Puerto 55166 *(Almacena parte de los datos y ejecuta queries)*
- **Worker 3**: 127.0.0.1 Puerto 55167 *(Nuevo nodo integrado ya despues de la implementación)*

---
 ![Logo de GitHub](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Alta%20disponibilidad/Sistemas%20Distribuidos/img/diagrama.jpeg)



### **Crear las carpetas donde se guarda el data de postgresql**
```bash
mkdir -p  /sysx/data16/DATANEW/data_coordinador
mkdir -p  /sysx/data16/DATANEW/data_worker1
mkdir -p  /sysx/data16/DATANEW/data_worker2
mkdir -p  /sysx/data16/DATANEW/data_worker3
```

### **Iniciarlizar los data**
```bash
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_coordinador --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker1 --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker2 --data-checksums  &>/dev/null
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker3 --data-checksums  &>/dev/null
```

### **configurar el postgresql.auto.conf de cada nodo**
```bash
# Habilita la nivel de wal logico
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf
echo "wal_level = logical" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf

# Cargar la liberia citus en todos los nodos 
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf

# Cambiar los puertos en cada nodo
echo "port = 55164" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "port = 55165" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "port = 55166" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf
echo "port = 55166" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf

# Permitir las conexiones externas 
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_coordinador/postgresql.auto.conf
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_worker1/postgresql.auto.conf
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_worker2/postgresql.auto.conf
echo "listen_addresses = '*'" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf
```

### **configurar el pg_hba.conf de cada nodo**
[NOTA] -> Esto es opcional solo si en tu laboratorio ya tienes los servidores , en mi caso como yo lo estoy haciendo en local, no ocupo configurarlo ya que por defaul cuando inicializas el data ya tiene permiso trust en local
```
host    all    all    127.0.01/32    trust
```

### **Iniciar el servicio de todos los nodos**
```
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_coordinador
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker1
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker2
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker3
```

### **Instalar la extension en todos los nodos**
```
psql -p 55164 -c "CREATE EXTENSION citus;"
psql -p 55165 -c "CREATE EXTENSION citus;"
psql -p 55166 -c "CREATE EXTENSION citus;"
psql -p 55167 -c "CREATE EXTENSION citus;"
```

### Configurar el servidor  coordinador puerto 55164
```sql
--# Indica quien es el nodo coordinador
SELECT citus_set_coordinator_host('127.0.0.1', 55164);

--#  Indicar quien son los nodos workers 
SELECT * FROM citus_add_node('127.0.0.1', 55165);
SELECT * FROM citus_add_node('127.0.0.1', 55166);

-- #  Ver los nodos workers 
SELECT * FROM citus_get_active_worker_nodes();
```

### Crear tabla y insertar registros en el coordinador
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    is_active BOOLEAN DEFAULT true
);
```

### Empezar a distribuir la tabla
```sql
SELECT create_distributed_table('users', 'id');
```

### Crear index para la tabla 
```sql
-- Índice para búsquedas por nombre de usuario
CREATE INDEX idx_users_username ON users(username,email);

-- Índice para búsquedas por correo electrónico
CREATE INDEX idx_users_email ON users(email);

-- Índice para consultas por fecha de creación (útil para rangos de tiempo)
CREATE INDEX idx_users_created_at ON users(created_at);
```


### Insertar los datos 

```bash
psql -p 55164 -c "INSERT INTO users (id, username, email, created_at, is_active)
SELECT i, 'user_' || i, 'user_' || i || '@example.com', now() - (i % 10000) * interval '1 second', (i % 2 = 0)
FROM generate_series(1, 250000000) AS i;" &

psql -p 55164  -c "INSERT INTO users (id, username, email, created_at, is_active)
SELECT i, 'user_' || i, 'user_' || i || '@example.com', now() - (i % 10000) * interval '1 second', (i % 2 = 0)
FROM generate_series(250000001, 500000000) AS i;" &

psql -p 55164  -c "INSERT INTO users (id, username, email, created_at, is_active)
SELECT i, 'user_' || i, 'user_' || i || '@example.com', now() - (i % 10000) * interval '1 second', (i % 2 = 0)
FROM generate_series(500000001, 750000000) AS i;" &

psql -p 55164  -c "INSERT INTO users (id, username, email, created_at, is_active)
SELECT i, 'user_' || i, 'user_' || i || '@example.com', now() - (i % 10000) * interval '1 second', (i % 2 = 0)
FROM generate_series(750000001, 1000000000) AS i;" &

```



### Consultar datos en los nodos 
```sql
psql -p 55164 -c "SELECT count(*) FROM users ;" 
psql -p 55165 -c "SELECT count(*) FROM users ;" 
psql -p 55166 -c "SELECT count(*) FROM users ;" 
```

### Ver la distribucion del sharding
```sql
SELECT 'select * from ' || shard_name || '; -- Ejecutar en Server: ' || nodename || ' - Port: ' ||nodeport FROM citus_shards where shard_size != 16384;


-- Querys monitoreo
SELECT * FROM citus_tables;
SELECT p.nodename, p.nodeport,s.* FROM pg_dist_shard s JOIN pg_dist_shard_placement p ON s.shardid = p.shardid;
SELECT * FROM citus_shards;
SELECT * FROM citus_stat_statements  LIMIT 10;
SELECT * FROM citus_stat_activity;
SELECT * FROM pg_dist_partition;
SELECT * from pg_dist_placement;
```

---
 
### **🔹 Paso 1: Agregar el nuevo nodo**
Configurar el data y servicio del nuevo nodo 
```sql
mkdir -p  /sysx/data16/DATANEW/data_worker3
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_worker3 --data-checksums  &>/dev/null
echo "port = 55167" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf
echo "shared_preload_libraries = 'citus'" >> /sysx/data16/DATANEW/data_worker3/postgresql.auto.conf
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_worker3
psql -p 55167 -c "CREATE EXTENSION citus;"
```

Conéctate al **coordinador** y registra el nuevo worker:
```sql
SELECT * FROM citus_add_node('192.168.1.103', 5432);
```

### **🔹 Paso 2: Verificar nodos activos**
Antes de redistribuir los datos, asegúrate de que el nuevo nodo está activo:
```sql
SELECT * FROM citus_get_active_worker_nodes();
```

### **🔹 Paso 3: Redistribuir shards**
Ahora que el nuevo nodo está disponible, redistribuye los datos entre todos los workers:
```sql
SELECT rebalance_table_shards('users');

-- select * from citus_rebalance_status();

```

### **🔹 Paso 4: Verifica la nueva redistribución con:**
```sql
SELECT * FROM citus_shards;
```

### Borrar el laboratorio 
```sql
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_coordinador
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_worker1
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_worker2
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_worker3

rm -r  /sysx/data16/DATANEW/data_coordinador
rm -r  /sysx/data16/DATANEW/data_worker1
rm -r  /sysx/data16/DATANEW/data_worker2
rm -r  /sysx/data16/DATANEW/data_worker3
```

---

## Info extra 
```
postgres@postgres# \dx+ citus

postgres@postgres# select proname from pg_proc where proname ilike '%balan%';
+---------------------------------------------+
|                   proname                   |
+---------------------------------------------+
| citus_validate_rebalance_strategy_functions |
| citus_set_default_rebalance_strategy        |
| rebalance_table_shards                      |
| get_rebalance_table_shards_plan             |
| citus_rebalance_start                       |
| citus_rebalance_stop                        |
| citus_rebalance_wait                        |
| get_rebalance_progress                      |
| citus_rebalance_status                      |
| pg_dist_rebalance_strategy_trigger_func     |
| citus_add_rebalance_strategy                |

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
