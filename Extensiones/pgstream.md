
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

---




## 🔍 ¿Dónde están la Publicación y la Suscripción?

En la replicación lógica nativa de PostgreSQL, tú tienes que hacer el `CREATE PUBLICATION` y el `CREATE SUBSCRIPTION` manualmente. Sin embargo, **pgstream automatiza la creación de la infraestructura lógica** por ti para evitar errores humanos.


Cuando ejecutaste el comando `pgstream init` y luego `pgstream run`, la herramienta realizó las siguientes acciones en tu servidor `10.0.1.10`:

### 1. La Publicación (Automática)

Si entras a tu base de datos y ejecutas `SELECT * FROM pg_publication;`, verás que pgstream creó una llamada (normalmente) `pgstream_pub`.

* **Por defecto:** pgstream crea una publicación `FOR ALL TABLES`. Esto lo hace para cumplir con el objetivo del laboratorio: que cualquier tabla nueva (como `productos`) se replique sin que tú tengas que intervenir.

### 2. El Slot de Replicación (Suscripción Lógica)

En lugar de una "Suscripción" formal (que es un objeto que vive en otro Postgres), pgstream crea un **Logical Replication Slot**.

* Puedes verlo con: `SELECT * FROM pg_replication_slots;`.
* Este slot es el que mantiene el puntero (LSN) para que, si apagas pgstream, Postgres guarde los cambios en el WAL hasta que el bridge vuelva a conectarse.
 
## 🛠️ Modificación del Laboratorio: Control Manual Profesional

Si en tu empresa te exigen que **NO** se repliquen todas las tablas (por seguridad o rendimiento), debes modificar los pasos del laboratorio de la siguiente manera:

### Paso A: Crear la Publicación Manualmente (`10.0.1.10`)

Antes de correr pgstream, tú decides qué se va.

```sql
\c ecommerce_db
-- Solo queremos replicar la tabla de productos, ignorando tablas sensibles como 'pagos'
CREATE PUBLICATION pub_busqueda_productos FOR TABLE productos;

```

### Paso B: Configurar la Identidad de Replicación

Para que el CDC sepa qué registro borrar o actualizar en OpenSearch, la tabla debe tener una identidad clara.

```sql
ALTER TABLE productos REPLICA IDENTITY DEFAULT; -- Usa la Primary Key

```

### Paso C: Ejecutar pgstream apuntando a esa Publicación (`10.0.1.20`)

Ahora le dices a pgstream que no cree nada automático, sino que use tu configuración:

```bash
pgstream run \
  --postgres-url "postgres://replicador:Pass_Stream_2026@10.0.1.10:5432/ecommerce_db" \
  --publication-name "pub_busqueda_productos" \
  --replication-slot-name "slot_opensearch_prod" \
  --sink-type opensearch \
  --opensearch-url "http://10.0.1.30:9200"

```

---

## 📝 Resumen de Objetivos vs. Implementación

| Concepto | Quién lo gestiona | Ubicación | Por qué no lo viste antes |
| --- | --- | --- | --- |
| **Publicación** | pgstream (Auto) | `db-prod-01` | Para facilitar el soporte de DDL automático (`FOR ALL TABLES`). |
| **Suscripción** | pgstream (Bridge) | `stream-bridge-01` | pgstream actúa como el suscriptor dinámico; no es un objeto estático en SQL. |
| **Slot** | pgstream | `db-prod-01` | Se crea en el momento del `init` para asegurar que no se pierdan datos desde el segundo 1. |

**¿Por qué es mejor así?**
Si lo hicieras nativo (`CREATE SUBSCRIPTION`), necesitarías otro PostgreSQL en el destino. Como tu destino es **OpenSearch**, no existe el objeto "Suscripción" allá. **pgstream traduce** el protocolo de replicación de Postgres al protocolo HTTP/JSON de OpenSearch.





--- 


### 1. El corazón de todo: El WAL (Write-Ahead Log)

En Postgres, cada vez que haces un `INSERT`, `UPDATE` o `DELETE`, antes de que los datos se escriban en las tablas permanentes, se guardan en un archivo diario de transacciones llamado **WAL**. Es la "caja negra" del avión.

`pgstream` no consulta tus tablas (`SELECT * FROM...`), lo cual sería lentísimo. En su lugar, **lee el WAL de forma secuencial**.

* **Eficiencia:** Leer el WAL es extremadamente rápido y no bloquea las filas ni las tablas.
* **Granularidad:** Sabe exactamente qué columna cambió, el valor viejo y el valor nuevo.

### 2. ¿Cómo sabe qué objetos transmitir? (Publicaciones)

Aquí es donde entra la configuración. `pgstream` utiliza el concepto de **Publicaciones (Publications)** de PostgreSQL.

* **A nivel de Base de Datos:** Por defecto, puedes configurar `pgstream` para que escuche **toda la base de datos** (`FOR ALL TABLES`). Esto es útil en migraciones totales.
* **A nivel de Objeto (Tablas específicas):** En un entorno profesional, esto es lo más común. Tú defines una publicación solo para las tablas que quieres sincronizar:
```sql
-- En Postgres (db-prod-01)
CREATE PUBLICATION pgstream_pub FOR TABLE productos, clientes, pedidos;

```


Cuando arrancas `pgstream`, le indicas que use esa publicación específica. **Cualquier cambio en otras tablas será ignorado por pgstream**, ahorrando ancho de banda y CPU.

### 3. Identificación de Identidad (Replica Identity)

Para que `pgstream` sepa qué registro actualizar en el destino (por ejemplo, en OpenSearch), necesita una "llave".

* Si haces un `UPDATE`, el WAL normalmente solo trae los datos nuevos.
* Para que `pgstream` sepa cuál era el valor anterior o la llave primaria exacta, debes configurar la **Identidad de Replicación** en la tabla:
```sql
ALTER TABLE productos REPLICA IDENTITY FULL;

```


Esto le dice a Postgres: "Cuando algo cambie en esta tabla, escribe en el WAL tanto el valor viejo como el nuevo". Así `pgstream` tiene la información completa para hacer el "match" en el destino.

### 4. El flujo lógico de decisión

Cuando ocurre un evento, `pgstream` sigue este algoritmo interno:

1. **Captura:** Lee el LSN (puntero) actual del WAL.
2. **Filtro:** ¿Este cambio pertenece a una tabla incluida en mi `PUBLICATION`?
* *No:* Lo descarta inmediatamente.
* *Sí:* Pasa al siguiente paso.


3. **Decodificación:** Usa un decodificador (como el que mencionaste, `wal2json`, o el nativo `pgoutput`) para convertir los bytes binarios del WAL en un JSON estructurado.
4. **Enrutamiento:** Según el ID de la tabla, lo envía al "Sink" (destino) correspondiente.

### 5. ¿Qué pasa con los esquemas (DDL)?

Esto es lo que diferencia a `pgstream` de un simple script:
`pgstream` monitorea las tablas del sistema de Postgres (`pg_class`, `pg_attribute`). Cuando detecta un comando `ALTER TABLE`, actualiza su **caché de esquemas** interno.

* Si entra un cambio para una columna que no existía hace 10 segundos, `pgstream` consulta su caché, ve que el esquema cambió, y ajusta el mensaje que envía a OpenSearch para que el destino no rechace el dato por "formato inválido".

---

### Resumen Técnico para el Laboratorio:

* **Ámbito:** Tú decides. Puedes replicar una tabla, un grupo de tablas o la DB entera.
* **Costo de rendimiento:** Mínimo (lectura secuencial de logs).
* **Precisión:** Total. Al basarse en el WAL, si una transacción hace `ROLLBACK` en Postgres, `pgstream` nunca la verá, asegurando que solo los datos confirmados (`COMMITTED`) lleguen al destino.
 
 
---




---

### 1. Nivel Base de Datos (Default)

por defecto la configuración inicial de pgstream es "agresiva": intenta replicar **todo el esquema** de la base de datos para asegurar que no se pierda ningún cambio de estructura (DDL).

Sin embargo, en un entorno **profesional**, replicar toda la base de datos es a menudo un error de diseño (puedes saturar la red o exponer datos sensibles). Como experto, te confirmo que tienes **tres niveles de granularidad** para decidir qué se transmite:


Es lo que vimos en el primer comando. `pgstream` crea una publicación `FOR ALL TABLES`.

* **Ventaja:** Cero configuración. Ideal si el destino es un Data Lake donde quieres "todo".
* **Desventaja:** Si tienes una tabla de `logs_auditoria` con millones de registros que no necesitas en el buscador, vas a desperdiciar recursos.

### 2. Nivel por Filtro de Tabla (Recomendado)

Puedes restringir qué tablas lee el binario de `pgstream` mediante la configuración de inclusión/exclusión. Esto se hace en el comando de ejecución:

```bash
pgstream run \
  --postgres-url "..." \
  --include-tables "public.productos,public.categorias" \
  --exclude-tables "public.passwords,public.sesiones" \
  --sink-type opensearch

```

* **Cómo funciona:** `pgstream` recibe todos los cambios del WAL, pero descarta en memoria los que no coinciden con tu lista de inclusión antes de enviarlos al destino.

### 3. Nivel por Publicación (El más eficiente)

Este es el nivel "Cirujano". Tú controlas desde el mismo motor de PostgreSQL qué datos salen del disco.

1. **En Postgres:** Creas una publicación que solo incluya lo necesario.
```sql
CREATE PUBLICATION pub_buscador_ecommerce FOR TABLE productos, stock_tiendas;

```


2. **En pgstream:** Le obligas a usar esa publicación:
```bash
pgstream run --publication-name "pub_buscador_ecommerce" ...

```



* **Por qué es mejor:** Si una tabla no está en la publicación, Postgres ni siquiera se molesta en enviarla a través del slot de replicación, ahorrando CPU en el servidor de base de datos.

---

## 🛠️ El Laboratorio "Filtrado": Control de Objetos

Si quisiéramos que nuestro laboratorio profesional solo replique la tabla `productos` y no otras, el flujo real de comandos sería este:

**Servidor `10.0.1.10` (Postgres):**

```sql
-- Creamos dos tablas
CREATE TABLE productos (id int primary key, nombre text);
CREATE TABLE secretos_nomina (id int primary key, salario numeric);

-- Solo exponemos productos
CREATE PUBLICATION pub_limitada FOR TABLE productos;

```

**Servidor `10.0.1.20` (pgstream):**

```bash
pgstream run \
  --postgres-url "..." \
  --publication-name "pub_limitada" \
  --sink-type opensearch

```

**Resultado:** Cualquier `INSERT` en `productos` viajará a OpenSearch. Cualquier cambio en `secretos_nomina` será ignorado por completo por el proceso de stream.

---

### ⚠️ Una advertencia de experto: La Identidad de la Tabla

Si decides filtrar y solo enviar ciertas tablas, no olvides que cada tabla debe tener definida su **Replica Identity**. Si una tabla no tiene Primary Key y no configuras `REPLICA IDENTITY FULL`, los `UPDATE` y `DELETE` llegarán vacíos o darán error porque pgstream no sabrá a qué fila se refieren.



# Links
```
https://github.com/xataio/pgstream
https://xata.io/blog/pgstream-v100-stateless-schema-change-replication
```
