
## 1. ¿Qué es pgstream?

**pgstream** es una herramienta de captura de datos de cambios (CDC) de código abierto, diseñada específicamente para PostgreSQL. Su función principal es "escuchar" los cambios que ocurren en tu base de datos (INSERTs, UPDATEs, DELETEs) y transmitirlos en tiempo real a otros destinos.

### ¿Quién lo desarrolló y bajo qué licencia?

* **Desarrollador:** Fue creado y es mantenido principalmente por **Xata** (una plataforma de base de datos "serverless" basada en PostgreSQL).
* **Licencia:** Es **Open Source** (gratis) bajo la licencia **Apache 2.0**. No es de pago, aunque Xata lo utiliza como parte de su infraestructura comercial, el binario y el código son libres para la comunidad.

---

## 2. ¿Para qué sirve y por qué usarlo en vez del modo nativo?

Aunque PostgreSQL tiene **Replicación Lógica nativa**, tiene limitaciones que pgstream resuelve de forma elegante:

| Característica | Replicación Lógica Nativa | pgstream |
| --- | --- | --- |
| **Cambios de Esquema (DDL)** | No los replica automáticamente. Si añades una columna, la replicación se rompe. | **Soporta DDL.** Rastrea cambios de esquema y los propaga al destino. |
| **Destinos** | Principalmente otro Postgres. | Postgres, **Elasticsearch, OpenSearch, Webhooks** y Kafka. |
| **Transformación** | Limitada. | Permite transformar datos en el vuelo (ej. anonimización). |
| **Facilidad de uso** | Requiere gestión manual de slots y publicaciones. | Automatiza la creación de slots y la gestión del estado. |

**¿Por qué usarlo?** Úsalo si necesitas sincronizar tu base de datos con un motor de búsqueda (Elasticsearch), si necesitas reaccionar a eventos vía Webhooks, o si tu esquema de base de datos cambia frecuentemente y no quieres que la replicación falle cada vez que ejecutas un `ALTER TABLE`.

---

## 3. Casos de Uso Comunes

1. **Sincronización con Buscadores:** Mantener un índice de Elasticsearch/OpenSearch perfectamente sincronizado con tus tablas SQL para búsquedas rápidas.
2. **Arquitectura de Microservicios:** Notificar a otros servicios mediante Webhooks cada vez que un registro importante cambie.
3. **Auditoría y Análisis:** Enviar un flujo de cambios a un Data Lake o sistema de analítica sin sobrecargar la base de datos principal con consultas pesadas.
4. **Migraciones con Tiempo de Inactividad Cero:** Replicar datos de una base de datos antigua a una nueva, incluyendo los cambios de estructura que ocurran durante el proceso.

---

## 4. Competidores Principales

* **Debezium:** El estándar de la industria (basado en Java/Kafka). Es más potente pero mucho más complejo de configurar.
* **pglogical:** Una extensión de 2ndQuadrant (ahora EDB) que fue precursora de la replicación lógica nativa.
* **Sequin:** Una alternativa moderna enfocada en flujos de datos tipo "stream".
* **AWS Database Migration Service (DMS):** La opción gestionada si estás en la nube de Amazon.


---


# 🏗️ Escenario Profesional: Sincronización Transaccional a Motor de Búsqueda

### El Problema

Una plataforma de E-commerce tiene su base de datos **PostgreSQL** saturada por consultas de búsqueda de productos (`LIKE %termino%`). El equipo de infraestructura decide delegar las búsquedas a **OpenSearch**, pero necesitan que la sincronización sea en milisegundos y que, si el DBA agrega una columna de "Descuento" en Postgres, esta aparezca automáticamente en OpenSearch sin romper el flujo.

### Objetivos del Laboratorio

1. Configurar **PostgreSQL** como fuente de eventos (Source).
2. Desplegar **pgstream** como orquestador de CDC en un nodo intermedio.
3. Sincronizar cambios hacia **OpenSearch** (Sink).
4. Demostrar la resiliencia ante cambios de esquema (DDL).

---

## 📋 Inventario de Infraestructura

| Hostname | Dirección IP | Componente Instalado | Rol |
| --- | --- | --- | --- |
| `db-prod-01` | `10.0.1.10` | PostgreSQL 16 | Fuente de datos (Primary) |
| `stream-bridge-01` | `10.0.1.20` | **pgstream** v1.0 | Procesador de eventos |
| `search-node-01` | `10.0.1.30` | OpenSearch 2.x | Destino de búsqueda |

---

## 🛠️ Guía de Instalación y Configuración

### 1. Configuración del Servidor de Base de Datos (`10.0.1.10`)

Instalamos y preparamos Postgres para replicación lógica.

* **Archivo:** `/etc/postgresql/16/main/postgresql.conf`
```ini
listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10

```


* **Archivo:** `/etc/postgresql/16/main/pg_hba.conf`
```text
host  all  all  10.0.1.20/32  scram-sha-256
host  replication  all  10.0.1.20/32  scram-sha-256

```


* **SQL Preparación:**
```sql
CREATE USER replicador WITH REPLICATION PASSWORD 'Pass_Stream_2026';
CREATE DATABASE ecommerce_db;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO replicador;

```



### 2. Configuración del Bridge de Datos (`10.0.1.20`)

Aquí instalamos **pgstream**. No requiere base de datos propia, pero usa una tabla interna en el origen para el control de posición (LSN).

* **Instalación:**
```bash
curl -L https://github.com/xataio/pgstream/releases/download/v1.0/pgstream_linux_amd64 -o /usr/local/bin/pgstream
chmod +x /usr/local/bin/pgstream

```


* **Inicialización del esquema de control:**
```bash
pgstream init --postgres-url "postgres://replicador:Pass_Stream_2026@10.0.1.10:5432/ecommerce_db"

```



### 3. Ejecución del Flujo de Datos

Configuramos pgstream para que tome los datos de Postgres y los envíe al nodo de búsqueda.

* **Comando de Producción:**
```bash
pgstream run \
  --postgres-url "postgres://replicador:Pass_Stream_2026@10.0.1.10:5432/ecommerce_db" \
  --sink-type opensearch \
  --opensearch-url "http://10.0.1.30:9200" \
  --opensearch-index "productos_idx" \
  --handle-ddl=true

```



---

## 🧪 Pruebas de Validación (Uso Común)

### Caso A: Inserción de datos en tiempo real

En el servidor `10.0.1.10`:

```sql
\c ecommerce_db
CREATE TABLE productos (id SERIAL PRIMARY KEY, nombre TEXT, precio NUMERIC);
INSERT INTO productos (nombre, precio) VALUES ('Laptop Pro 2026', 2500.00);

```

**Resultado:** En menos de 100ms, el documento aparece en `http://10.0.1.30:9200/productos_idx/_search`.

### Caso B: Cambio de Esquema (El "Killer Feature")

A diferencia de la replicación nativa, pgstream no se detendrá aquí:

```sql
ALTER TABLE productos ADD COLUMN stock INTEGER DEFAULT 0;
UPDATE productos SET stock = 50 WHERE id = 1;

```

**Validación:** pgstream detecta el `ALTER TABLE`, actualiza el mapeo en OpenSearch y el nuevo campo `stock` es indexado automáticamente.

---

## 📈 ¿Por qué esta arquitectura es superior a la nativa?

1. **Desacoplamiento:** Si OpenSearch (`10.0.1.30`) cae, pgstream mantiene el puntero en Postgres y reanuda cuando el servicio vuelve, sin perder datos.
2. **Transformación:** Podrías añadir un flag `--transform` para que los precios se conviertan de USD a EUR antes de llegar al buscador.
3. **Mantenimiento:** No tienes que recrear suscripciones manualmente cada vez que haces un cambio en el DDL de la tabla.

# Links
```
https://github.com/xataio/pgstream

```
