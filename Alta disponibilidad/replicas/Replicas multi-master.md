
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





##  Laboratorio: Replicación Multi-Maestro con `pglogical`

###  Requisitos

- PostgreSQL 14 o superior
- Extensión `pglogical` instalada en ambos nodos
- Dos instancias PostgreSQL (pueden ser contenedores, VMs o servidores físicos)
- Acceso de red entre ambos nodos

---

###  Configuración base en ambos nodos

#### 1. `postgresql.conf`

```conf
listen_addresses = '*'
wal_level = logical
max_worker_processes = 10
max_replication_slots = 10
max_wal_senders = 10
shared_preload_libraries = 'pglogical'
track_commit_timestamp = on
```

#### 2. `pg_hba.conf`

Permitir replicación entre nodos:

```conf
host    all             all             0.0.0.0/0               trust
host    replication     all             0.0.0.0/0               trust
```

---

###  Crear usuario y base de datos

En ambos nodos:

```bash
createuser -s --replication pguser
createdb -O pguser pgdb
```

---

###  Crear la extensión `pglogical`

En ambos nodos:

```sql
CREATE EXTENSION pglogical;
```

---

###  Crear tabla de prueba

En ambos nodos:

```sql
CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    data TEXT
);
```

---

###  Configurar nodos y replicación

#### En **Nodo A**:

```sql
SELECT pglogical.create_node(
    node_name := 'node_a',
    dsn := 'host=10.0.0.1 port=5432 dbname=pgdb user=pguser'
);

SELECT pglogical.create_replication_set('replica_set');

SELECT pglogical.replication_set_add_all_tables('replica_set', ARRAY['public']);
```

#### En **Nodo B**:

```sql
SELECT pglogical.create_node(
    node_name := 'node_b',
    dsn := 'host=10.0.0.2 port=5432 dbname=pgdb user=pguser'
);

SELECT pglogical.create_replication_set('replica_set');

SELECT pglogical.replication_set_add_all_tables('replica_set', ARRAY['public']);
```

---

###  Crear suscripciones cruzadas (multi-maestro)

#### En **Nodo A**:

```sql
SELECT pglogical.create_subscription(
    subscription_name := 'sub_from_b',
    provider_dsn := 'host=10.0.0.2 port=5432 dbname=pgdb user=pguser',
    replication_sets := ARRAY['replica_set']
);
```

#### En **Nodo B**:

```sql
SELECT pglogical.create_subscription(
    subscription_name := 'sub_from_a',
    provider_dsn := 'host=10.0.0.1 port=5432 dbname=pgdb user=pguser',
    replication_sets := ARRAY['replica_set']
);
```

---

###  Verificación

- Inserta un dato en `Nodo A` y verifica que aparece en `Nodo B`.
- Inserta un dato en `Nodo B` y verifica que aparece en `Nodo A`.

---

###  Consideraciones importantes

- **Conflictos**: pglogical no resuelve conflictos automáticamente. Debes evitar colisiones de claves primarias.
- **Esquema**: ambos nodos deben tener el mismo esquema.
- **Cambios DDL**: deben aplicarse manualmente o usando `pglogical.replicate_ddl_command`.



### Blibliografia 
```sql

Bidirectional replication in PostgreSQL using pglogical -> https://www.jamesarmes.com/2023/03/bidirectional-replication-postgresql-pglogical.html
pglogical -> https://gist.github.com/edib/402d7d29d54a025265c2a5b4d0ee7fe6
PostgreSQL pglogical extension -> https://docs.aws.amazon.com/dms/latest/sbs/chap-manageddatabases.postgresql-rds-postgresql-full-load-pglogical.html
Setting up replication in PostgreSQL with pglogical -> https://medium.com/@Navmed/setting-up-replication-in-postgresql-with-pglogical-8212e77ebc1b
Migración PostgreSQL con pglogical -> https://ifgeekthen.nttdata.com/s/post/migracion-postgresql-con-pglogical-MCVUL3MI2E7ZBZZEEES64PSP5UEA?language=es
Using pglogical for Logical Replication -> https://www.tencentcloud.com/document/product/409/64755
How to Use pglogical for Bidirectional Replication in PostgreSQL with Conflict Handling -> https://www.cybrosys.com/research-and-development/postgres/how-to-use-pglogical-for-bidirectional-replication-in-postgresql-with-conflict-handling

```
