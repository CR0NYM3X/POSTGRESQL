**Citus** es una extensión de PostgreSQL que permite **escalar bases de datos distribuidas**, ideal para manejar grandes volúmenes de datos y mejorar el rendimiento en sistemas con múltiples nodos. Citus usa logical decoding para mover datos entre nodos.  esta herramienta se recomienda usar en sistemas donde requieran realizar analisis de una gran cantidad de datos. convierte a postgresql OLTP (Procesamiento de Transacciones en Línea) en un OLAP (Procesamiento Analítico en Línea)

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

#  Que puedes hacer con Citus

## ✅ **1. Distribución de Tablas**

*   **create\_distributed\_table()**: Convierte una tabla en distribuida, dividiéndola en *shards* que se reparten entre nodos.
*   Métodos de distribución:
    *   **Hash**: Ideal para multi-tenant (por `tenant_id`).
    *   **Append**: Para datos que crecen en el tiempo (eventos, logs).

## ✅ **2. Tablas de Referencia**

*   **create\_reference\_table()**: Replica tablas pequeñas en todos los nodos para joins rápidos (ej. catálogos, países).

## ✅ **3. Particionamiento Temporal**

*   **create\_time\_partitions()**: Crea particiones por rango de tiempo sobre tablas distribuidas.
*   Permite **retención automática** (drop partitions) y optimización de consultas por fecha.

## ✅ **4. Consultas Distribuidas**

*   Ejecuta **consultas paralelas** en todos los nodos.
*   Compatible con:
    *   **JOINs** entre tablas distribuidas y de referencia.
    *   **Aggregates** (SUM, COUNT, AVG) distribuidos.
    *   **Subconsultas** y **CTEs** (con ciertas limitaciones).

## ✅ **5. Escalabilidad Horizontal**

*   Añadir nodos para aumentar capacidad.
*   Redistribuir shards con **rebalanceo automático**.

## ✅ **6. Alta Disponibilidad**

*   Integración con **replicación** (streaming replication).
*   Failover y resiliencia ante caídas.

## ✅ **7. Integración con PostgreSQL**

*   Compatible con **índices**, **constraints**, **triggers** (con restricciones).
*   Soporte para **Postgres 16+** y características modernas.

## ✅ **8. Herramientas Avanzadas**

*   **pg\_cron** + Citus: Automatización de tareas (crear/dropear particiones).
*   **Citus MX**: Para cargas mixtas OLTP + OLAP.
*   **Columnar Storage**: Para analítica (almacenamiento por columnas).

## ✅ **9. Casos de Uso**

*   **SaaS multi-tenant**: Distribuir por `tenant_id`.
*   **Analítica en tiempo real**: Distribuir por tiempo y agregar datos masivos.
*   **IoT / Logs**: Particiones por fecha + distribución por dispositivo.


 
---

### **🖥️ Escenario del laboratorio**
Se crearon **cuatro servidores** en una red privada que formarán el clúster, Este esquema permitirá repartir la carga de trabajo y escalar el sistema de manera eficiente.
se utilizara citus columnar para mejorar  la compresión y acelerar las consultas, reduciendo el uso de disco y mejorando el rendimiento en agregaciones como avg(), sum() etc... insertaremos mil millones de registros. si no usaramos citus columar se necesitarian 350GB en disco. utilizaremos unicamente las configuraciones por default de postgresql y nuestro servidor tiene 24 GB de Ram, 15 nucleos y S.O Red Hat .

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
psql -p 55164 -c "CREATE EXTENSION citus;" -- este ya instala la extension de citus_columnar
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

### Crear tabla columnar y insertar registros en el coordinador
Las tablas columnares Son más de análisis y funcionan mejor con consultas agregadas y escaneo masivo.
Las consultas agregadas son aquellas que utilizan funciones como SUM(), AVG(), COUNT(), MIN(), MAX(), entre otras, para resumir datos.
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    is_active BOOLEAN DEFAULT true
)  USING columnar;
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


### Visualizar 
```sql
postgres@postgres# \dt+
                                    List of relations
+--------+-------+-------+----------+-------------+---------------+-------+-------------+
| Schema | Name  | Type  |  Owner   | Persistence | Access method | Size  | Description |
+--------+-------+-------+----------+-------------+---------------+-------+-------------+
| public | users | table | postgres | permanent   | columnar      | 16 kB | NULL        |
+--------+-------+-------+----------+-------------+---------------+-------+-------------+
(1 row)

postgres@postgres# \d users
                            Table "public.users"
+------------+-----------------------------+-----------+----------+---------+
|   Column   |            Type             | Collation | Nullable | Default |
+------------+-----------------------------+-----------+----------+---------+
| id         | bigint                      |           | not null |         |
| username   | text                        |           | not null |         |
| email      | text                        |           | not null |         |
| created_at | timestamp without time zone |           |          | now()   |
| is_active  | boolean                     |           |          | true    |
+------------+-----------------------------+-----------+----------+---------+
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)
    "idx_users_created_at" btree (created_at)
    "idx_users_email" btree (email)
    "idx_users_username" btree (username, email)

```


### **🔹 Paso 1: Agregar el nuevo nodo**
 
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

---


###   Crear tabla `puestos` (como referencia)

```sql
CREATE TABLE puestos (
    id SMALLINT PRIMARY KEY,
    nombre TEXT NOT NULL
);

-- Replica tablas pequeñas en todos los nodos para joins rápidos (ej. catálogos, países).
SELECT create_reference_table('puestos');
```

 
###  Insertar datos de ejemplo

```sql
INSERT INTO puestos (id, nombre) VALUES
(1, 'Director General'),
(2, 'Gerente de Área'),
(3, 'Jefe de Departamento'),
(4, 'Analista'),
(5, 'Desarrollador'),
(6, 'Soporte Técnico'),
(7, 'Practicante');
```

---

###   En el servidor coordinador agregar nueva columna
Puedes ahora agregar una columna `puesto_id` a la tabla `users`:
```sql
ALTER TABLE users ADD COLUMN puesto_id SMALLINT;
```

 

---


### Insertar mil millones de registros
Esta operacion tarda tiempo
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


ps -fea | grep generate_series

```



### Consultar espacio de cada nodo  

```sql
psql -p 55164 -c "SELECT pg_size_pretty(pg_database_size('postgres'));" # Coordinador  tamaño 9748 kB 
psql -p 55165 -c "SELECT pg_size_pretty(pg_database_size('postgres'));" # Worker1 tamaño  111 GB sin tabla columnar a 82 GB con tabla columnar 
psql -p 55165 -c "SELECT pg_size_pretty(pg_database_size('postgres'));" # Worker1  tamaño 111 GB
psql -p 55165 -c "SELECT pg_size_pretty(pg_database_size('postgres'));"  # Worker1  tamaño 111 GB

du -lh /sysx/data16/DATANEW/ | grep "/sysx/data16/DATANEW/$"

SELECT * FROM citus_tables;

```


### Consultas de prueba para medir el rendiemiento;
Esta consulta se puede realizar en cualquier nodo coordinador o worker, los resultados debe variar en los 20 o 30ms
```sql

select * from users where username in('user_558121771', 'user_546225936', 'user_104260803', 'user_435382393', 'user_436477677', 'user_480562912', 'user_220547089', 'user_465849719', 'user_922686500', 'user_67022343', 'user_864700256', 'user_96992106', 'user_97821595', 'user_804278165', 'user_634866347', 'user_910340103', 'user_797078547', 'user_252314339', 'user_127316864', 'user_255343492', 'user_32945176', 'user_397205450', 'user_922289404', 'user_989248229', 'user_95656', 'user_674104665', 'user_926157642', 'user_759415215', 'user_343356717', 'user_746892625', 'user_296891570', 'user_952883649', 'user_552850535', 'user_765911606', 'user_811833978', 'user_249614931', 'user_760638493', 'user_77138948', 'user_816895258', 'user_152084701', 'user_870678589', 'user_767589769', 'user_735472977', 'user_579996699', 'user_633072027', 'user_313737799', 'user_79859741', 'user_377459834', 'user_430415774', 'user_62891351');

```


 


### Ver la distribucion del sharding
```sql
SELECT 'select * from ' || shard_name || '; -- Ejecutar en Server: ' || nodename || ' - Port: ' ||nodeport FROM citus_shards where shard_size != 16384;


-- Querys monitoreo
SELECT * FROM citus_schemas;
SELECT * FROM citus_tables;
SELECT p.nodename, p.nodeport,s.* FROM pg_dist_shard s JOIN pg_dist_shard_placement p ON s.shardid = p.shardid;
SELECT * FROM citus_shards;
SELECT * FROM citus_stat_statements  LIMIT 10;
SELECT * FROM citus_stat_activity;
SELECT * FROM pg_dist_partition;
SELECT * from pg_dist_placement;
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

 
###   ¿Cuál es el objetivo de una tabla de referencia?

Las **tablas de referencia** se usan para **evitar la redistribución de datos** durante los `JOINs` en consultas distribuidas. Se replican en **todos los nodos del clúster**, lo que permite que cada nodo tenga acceso local a esa información sin necesidad de hacer consultas remotas.


###   Ejemplo práctico

Supón que tienes:

- Una tabla distribuida: `ventas(distribuida por id_cliente)`
- Una tabla pequeña: `paises(id, nombre)`

Si haces muchas consultas como:

```sql
SELECT v.id, p.nombre
FROM ventas v
JOIN paises p ON v.pais_id = p.id;
```


###  Flujo de ejecución con tabla de referencia

1. El coordinador recibe la consulta.
2. Detecta que `ventas` está distribuida y `paises` es una tabla de referencia.
3. Envía la consulta a cada nodo **junto con la lógica del `JOIN`**.
4. Cada nodo ejecuta la consulta **localmente**, porque ya tiene una copia de `paises`.
5. Los resultados se agregan y devuelven al cliente.


###   ¿Qué pasa si no usas tabla de referencia?

Si `paises` no es una tabla de referencia:

- El sistema tendría que **redistribuir los datos** de `paises` o de `ventas` para hacer el `JOIN`, lo cual es **costoso y lento**.
- Podrías tener errores si los datos no están disponibles en todos los nodos.


 
###   2. ¿Se pueden usar claves foráneas (foreign keys) en Citus?

**No directamente entre tablas distribuidas y de referencia.** PostgreSQL permite claves foráneas, pero **Citus no las aplica ni las valida automáticamente** en entornos distribuidos. Aquí los detalles:

| Tipo de tabla | ¿Soporta claves foráneas? | Comentario |
|---------------|----------------------------|------------|
| Local         | ✅ Sí                      | Comportamiento normal de PostgreSQL |
| Distribuida   | ⚠️ No                      | Citus ignora las `FOREIGN KEY` por rendimiento y escalabilidad |
| Referencia    | ⚠️ Parcialmente            | Puedes definirlas, pero **no se aplican ni validan automáticamente** |

> Puedes definir la clave foránea para documentación o herramientas de modelado, pero **Citus no la hará cumplir**.

---

###  Alternativas recomendadas

- Validar integridad referencial **a nivel de aplicación**.
- Usar **triggers** si necesitas validación estricta (aunque puede impactar el rendimiento).
- Si ambas tablas son de referencia, puedes usar claves foráneas normalmente.

 
 
---


## 4) Ejemplo de **`create_time_partitions`** (partición por tiempo sobre una tabla distribuida)

Este patrón (Hash + time range partitioning) es **el recomendado** para logs/eventos/IoT/analítica con retención: te permite **indices pequeños**, **pruning** efectivo y **drops** de particiones antiguas. [\[citusdata.com\]](https://www.citusdata.com/blog/2023/08/04/understanding-partitioning-and-sharding-in-postgres-and-citus/), [\[github.com\]](https://github.com/mwendwa5/postgres-citus)

```sql
-- 1. Partimos de la tabla distribuida por HASH (por entidad) 
--    que definimos antes: public.events (distributed on tenant_id)

-- 2. Creamos particiones mensuales para los próximos 12 meses
SELECT create_time_partitions(
  table_name         := 'public.events',
  partition_interval := '1 month',
  end_at             := now() + interval '12 months'
);

-- 3. (Opcional) Ver las particiones generadas por Citus
SELECT partition
FROM time_partitions
WHERE parent_table = 'public.events'::regclass;

-- 4. (Operativa) Con pg_cron puedes:
--    - Asegurar que siempre existan N particiones futuras
--    - Dropear particiones antiguas para retención
-- Ejemplo conceptual:
-- SELECT run_command_on_schedule(
--   job_name := 'events_partitions_maintenance',
--   schedule := '0 2 * * *',  -- diario a las 02:00
--   command  := $$ 
--     SELECT ensure_time_partitions(
--       'public.events', '1 month', now(), now() + interval '12 months'
--     );
--     SELECT drop_old_time_partitions(
--       'public.events', older_than := now() - interval '18 months'
--     );
--   $$ 
-- );
```


 
### ✅ ¿Qué significa *multi‑tenant*?

*   **Tenant** = “inquilino” o “cliente” en un sistema compartido.
*   **Multi‑tenant** = una sola aplicación/base de datos sirve a **muchos clientes** (tenants), pero cada uno ve **solo sus datos**.

# **Consideraciones, recomendaciones y buenas prácticas con Citus**:


## ✅ **1. Elección de la columna de distribución**

*   **Distribuye por la columna que más usas en filtros y JOINs** (p. ej., `tenant_id` en multi‑tenant o `device_id` en IoT).
*   Evita distribuir por columnas que cambian frecuentemente (updates costosos).
*   Si no hay una clave natural, considera una **clave sintética**.



## ✅ **2. Co‑location para JOINs**

*   Si varias tablas se consultan juntas, distribúyelas por la **misma columna** para que los JOINs ocurran en el mismo nodo.
*   Usa **reference tables** para catálogos pequeños (replicadas en todos los nodos).



## ✅ **3. Particionamiento por tiempo**

*   Combina **Hash distribution** con **particiones por tiempo** para:
    *   **Pruning** (consultas más rápidas).
    *   **Drops instantáneos** para retención.
*   Usa `create_time_partitions()` y automatiza con **pg\_cron**.



## ✅ **4. Índices y mantenimiento**

*   Crea índices en columnas de filtro (por shard/partición).
*   Ajusta parámetros como `work_mem`, `maintenance_work_mem` para consultas distribuidas.
*   Usa **ANALYZE** regularmente para estadísticas correctas.



## ✅ **5. Evita scatter‑gather innecesario**

*   Si no filtras por la columna de distribución, la consulta será **global** (scatter‑gather).
*   Para analítica pesada, considera **vistas materializadas** o **tablas agregadas**.



## ✅ **6. Escalabilidad y rebalanceo**

*   Empieza con **1 coordinator + 3 workers** mínimo.
*   Usa `rebalance_table_shards()` cuando agregues nodos.
*   Planifica shards suficientes desde el inicio (ej. 32‑64 shards por tabla).



## ✅ **7. Alta disponibilidad**

*   Configura **replicación streaming** en cada worker.
*   Usa **Patroni** o similar para failover automático.



## ✅ **8. Monitoreo y alertas**

*   Monitorea:
    *   Latencia de consultas distribuidas.
    *   Estado de shards (`pg_dist_shard`).
    *   Espacio por nodo.
*   Herramientas: **pg\_stat\_statements**, Prometheus + Grafana.



## ✅ **9. Seguridad**

*   Roles y permisos centralizados en el **coordinator**.
*   Cifrado en tránsito (SSL) y en reposo si aplica.
*   Limita acceso directo a workers (solo coordinator expuesto).
 

## ✅ **10. Actualizaciones y compatibilidad**

*   Usa versiones recientes de PostgreSQL y Citus (>= 12).
 

 

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
https://docs.citusdata.com/en/v13.0/
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

Manejo de miles de millones de filas en PostgreSQL ( TimescaleDB ) -> https://medium.com/timescale/handling-billions-of-rows-in-postgresql-80d3bd24dabb

```
