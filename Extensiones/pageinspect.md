

### pageinspect 
es una extensión de PostgreSQL que permite examinar el contenido de las páginas de la base de datos a bajo nivel. Mostrar información detallada sobre tuplas (filas) individuales


 
### Instalación de la extensión

Primero, asegúrate de tener la extensión instalada:

```sql
CREATE EXTENSION IF NOT EXISTS pageinspect;
```
 
### Ejemplos reales de uso

#### Inspección de una página de una tabla

Para inspeccionar una página específica de una tabla y obtener información detallada:

```sql
-- Obtener la página cruda
SELECT get_raw_page('mi_tabla', 0) AS page;

-- Obtener el encabezado de la página
SELECT * FROM page_header(get_raw_page('mi_tabla', 0));

-- Obtener los elementos de la página
SELECT * FROM heap_page_items(get_raw_page('mi_tabla', 0));
```


#### Verificación de checksum de una página

Para verificar el checksum de una página y compararlo con el almacenado:

```sql
-- Obtener el checksum de la página
SELECT page_checksum(get_raw_page('mi_tabla', 0), 0);

-- Comparar con el checksum del encabezado
SELECT (page_header(get_raw_page('mi_tabla', 0))).checksum;
```

#### Inspección de índices B-Tree

Para inspeccionar los índices B-Tree:

```sql
-- Obtener los elementos de una página de índice B-Tree
SELECT * FROM bt_page_items('mi_indice', 0);
```
# Saber cantidad de paginas de una tabla
```
SELECT relname, relpages FROM pg_class  WHERE relname = 'cat_servidores';

SELECT pg_relation_size('cat_servidores') as size_bytes, pg_relation_size('cat_servidores')  / current_setting('block_size')::int AS total_pages;

-- Primero instalas la extensión (si no la tienes)
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- Consultas la tabla
SELECT table_len / current_setting('block_size')::int AS total_pages FROM pgstattuple('cat_servidores');
```

--- 
# Ejemplos de como observar los datos 
```
CREATE EXTENSION IF NOT EXISTS pageinspect;

 
create table test2 (nombre varchar,numero int);
insert into  test2 select 'jose',100;
insert into  test2 select 'maria',200;
delete from test2 where nombre = 'jose';



WITH h AS (
  SELECT lp, t_data, t_infomask, t_infomask2, t_bits,
  case when t_xmax = 0  then false else true end as is_delete
  FROM heap_page_items(get_raw_page('test2', 0))
),
split AS (
  SELECT lp,is_delete,
         tuple_data_split('test2'::regclass,
                          t_data, t_infomask, t_infomask2, t_bits,
                          true) AS attrs  -- do_detoast = true
  FROM h
)
SELECT lp,is_delete,
       convert_from(attrs[1], 'UTF8') AS nombre,                            -- texto legible
       (get_byte(attrs[2],0)
        + get_byte(attrs[2],1)*256
        + get_byte(attrs[2],2)*65536
        + get_byte(attrs[2],3)*16777216)::int AS numero                     -- int4 little-endian
FROM split;

+----+-----------+--------+--------+
| lp | is_delete | nombre | numero |
+----+-----------+--------+--------+
|  1 | t         | jose   |    100 |
|  2 | f         | maria  |    200 |
+----+-----------+--------+--------+
(2 rows)



-----------------



create table test(name varchar(7));
insert into test values('a');
insert into test values('bb');
insert into test values('ccc');
delete from test  where name = 'a';
update test set name = 'zzz' where name = 'bb';


postgres@test# SELECT t_data, convert_from(('\x' ||substring(t_data::text , 5))::bytea, 'UTF8') AS texto_legible FROM heap_page_items(get_raw_page('test', 0));
+------------+---------------+
|   t_data   | texto_legible |
+------------+---------------+
| \x0561     | a             |
| \x076262   | bb            |
| \x09636363 | ccc           |
| \x0561     | a             |
| \x097a7a7a | zzz           |
+------------+---------------+
(5 rows)


--- vista de la tabla
postgres@test# select * from test;
+------+
| name |
+------+
| ccc  |
| a    |
| zzz  |
+------+
(3 rows)

-- Validando cuantas tuplas tiene
postgres@test# SELECT relname, relpages FROM pg_class  WHERE relname = 'test';
+---------+----------+
| relname | relpages |
+---------+----------+
| test    |        0 |
+---------+----------+
(1 row)

--- Viendo las cabeceras de la tupla 0 
Time: 0.398 ms
postgres@test# SELECT * FROM page_header(get_raw_page('test', 0));
+-----------+----------+-------+-------+-------+---------+----------+---------+-----------+
|    lsn    | checksum | flags | lower | upper | special | pagesize | version | prune_xid |
+-----------+----------+-------+-------+-------+---------+----------+---------+-----------+
| 2/A068120 |        0 |     0 |    44 |  8032 |    8192 |     8192 |       4 |      2723 |
+-----------+----------+-------+-------+-------+---------+----------+---------+-----------+
(1 row)

-- Viendo las filas de la tupla 0
Time: 0.547 ms
postgres@test# SELECT * FROM heap_page_items(get_raw_page('test', 0));
+----+--------+----------+--------+--------+--------+----------+--------+-------------+------------+--------+--------+-------+------------+
| lp | lp_off | lp_flags | lp_len | t_xmin | t_xmax | t_field3 | t_ctid | t_infomask2 | t_infomask | t_hoff | t_bits | t_oid |   t_data   |
+----+--------+----------+--------+--------+--------+----------+--------+-------------+------------+--------+--------+-------+------------+
|  1 |   8160 |        1 |     26 |   2715 |   2723 |        0 | (0,1)  |        8193 |       1282 |     24 | NULL   |  NULL | \x0561     |
|  2 |   8128 |        1 |     27 |   2717 |   2725 |        0 | (0,5)  |       16385 |       1282 |     24 | NULL   |  NULL | \x076262   |
|  3 |   8096 |        1 |     28 |   2718 |      0 |        0 | (0,3)  |           1 |       2306 |     24 | NULL   |  NULL | \x09636363 |
|  4 |   8064 |        1 |     26 |   2724 |      0 |        0 | (0,4)  |           1 |       2306 |     24 | NULL   |  NULL | \x0561     |
|  5 |   8032 |        1 |     28 |   2725 |      0 |        0 | (0,5)  |       32769 |      10498 |     24 | NULL   |  NULL | \x097a7a7a |
+----+--------+----------+--------+--------+--------+----------+--------+-------------+------------+--------+--------+-------+------------+
(5 rows)

```


##  1. ¿Qué es `page_header(get_raw_page(...))`?

Esta función muestra el **encabezado de la página física** (8 KB por defecto) donde se almacenan los tuples. Sirve para diagnosticar el estado interno de la página.

### Columnas y su función:

| Columna        | ¿Qué indica?                                | Valor en tu ejemplo | Explicación                                                                  |
| -------------- | ------------------------------------------- | ------------------- | ---------------------------------------------------------------------------- |
| **lsn**        | Log Sequence Number                         | `2/A068120`         | Última posición en el WAL que modificó esta página.                          |
| **checksum**   | Verificación                                | `0`                 | Si está habilitado, valida integridad (0 = no usado).                        |
| **flags**      | Estado de la página                         | `0`                 | 0 = normal, otros valores indican condiciones especiales.                    |
| **lower**      | Offset del final del array de line pointers | `44`                | Hay 5 line pointers (cada uno 8 bytes), por eso 44 bytes ocupados al inicio. |
| **upper**      | Offset donde empieza el espacio libre       | `8032`              | Después del último tuple, queda espacio libre desde 8032 hasta 8192.         |
| **special**    | Área especial                               | `8192`              | En heap no se usa, apunta al final de la página.                             |
| **pagesize**   | Tamaño de página                            | `8192`              | Tamaño estándar en PostgreSQL.                                               |
| **version**    | Versión del formato                         | `4`                 | Formato actual de página.                                                    |
| **prune\_xid** | XID más antiguo que necesita pruning        | `2723`              | Indica que hay tuples que podrían limpiarse por VACUUM.                      |

***

##  2. ¿Qué es `heap_page_items(get_raw_page(...))`?

Esta función lista **cada tuple (fila)** dentro de la página, con metadatos y datos crudos. Sirve para inspeccionar visibilidad, tamaño y contenido.

### Columnas y su función (con tus valores):

| Columna                        | ¿Qué indica?                    | Ejemplo                   | Explicación                                                                      |
| ------------------------------ | ------------------------------- | ------------------------- | -------------------------------------------------------------------------------- |
| **lp**                         | Número de line pointer          | `1..5`                    | Identifica la posición del tuple en la página.                                   |
| **lp\_off**                    | Offset físico                   | `8160, 8128, ...`         | Dónde empieza el tuple en la página (se colocan desde el final hacia el inicio). |
| **lp\_flags**                  | Estado del slot                 | `1`                       | 1 = tuple normal, otros valores indican redirección o borrado.                   |
| **lp\_len**                    | Longitud del tuple              | `26..28`                  | Bytes que ocupa cada tuple (cabecera + datos).                                   |
| **t\_xmin**                    | XID que insertó                 | `2715..2725`              | Transacción que creó la fila.                                                    |
| **t\_xmax**                    | XID que borró                   | `0` o `2723`              | 0 = no borrado, otro valor = borrado por esa transacción.                        |
| **t\_field3**                  | MultiXact ID                    | `0`                       | Usado para bloqueos compartidos (aquí no aplica).                                |
| **t\_ctid**                    | Identificador lógico            | `(0,1)..(0,5)`            | Página y posición del tuple.                                                     |
| **t\_infomask2 / t\_infomask** | Flags internos                  | `8193,1282,...`           | Indican visibilidad, HOT updates, etc.                                           |
| **t\_hoff**                    | Offset donde empiezan los datos | `24`                      | Cabecera ocupa 24 bytes.                                                         |
| **t\_bits**                    | Bitmap de columnas NULL         | `NULL`                    | No hay columnas NULL.                                                            |
| **t\_oid**                     | OID del tuple                   | `NULL`                    | Tabla sin OIDs.                                                                  |
| **t\_data**                    | Datos crudos                    | `\x0561`, `\x076262`, ... | Contenido binario: header varlena + texto (`a`, `bb`, `ccc`, `a`, `zzz`).        |


###  Interpretación rápida de tus filas:

*   Fila 1: `t_data = \x0561` → Header varlena + `61` (ASCII `a`).
*   Fila 2: `\x076262` → `bb`.
*   Fila 3: `\x09636363` → `ccc`.
*   Fila 4: `\x0561` → `a`.
*   Fila 5: `\x097a7a7a` → `zzz`.

Algunas filas tienen `t_xmax ≠ 0` (ej. fila 1 y 2), lo que indica que fueron **borradas** por la transacción `2723` (coincide con `prune_xid` en el header).


##  ¿Para qué sirve todo esto?

*   **Diagnóstico interno**: saber cómo PostgreSQL organiza datos en páginas.
*   **Auditoría**: ver transacciones que insertaron/borraron filas.
*   **Recuperación forense**: leer datos borrados antes de VACUUM.
*   **Optimización**: entender espacio libre y fragmentación.
 


---

 
##  ¿Qué es `lp_off`?

*   Es el **offset en bytes dentro de la página (8 KB)** donde **empieza el tuple**.
*   Las páginas en PostgreSQL tienen esta estructura:
        [Header] [Line Pointer Array] .......... [Free Space] .......... [Tuples]
        ^ inicio (byte 0)                                             ^ final (byte 8192)
*   **Los line pointers** (cada uno 8 bytes) se agregan al inicio.
*   **Los tuples** se insertan **desde el final hacia el inicio** para aprovechar el espacio libre en medio.

 
##  Tu ejemplo (página de 8192 bytes)

*   **special = 8192** → final de la página.
*   **upper = 8032** → espacio libre empieza en 8032.
*   Tus tuples:
        lp_off
        8160 → tuple 1
        8128 → tuple 2
        8096 → tuple 3
        8064 → tuple 4
        8032 → tuple 5
*   Observa: **cada tuple está más cerca del inicio que el anterior**, porque PostgreSQL va “empujando” los tuples hacia el inicio conforme inserta más.
 

###  Visualización (simplificada)

    Byte 0 ───────────────────────────────────────────────────────────── Byte 8192
    [Header][Line Pointers][Free Space][Tuple 5][Tuple 4][Tuple 3][Tuple 2][Tuple 1]
             lower=44       upper=8032
    Tuples:
    - Tuple 1: empieza en 8160 (casi al final)
    - Tuple 2: empieza en 8128
    - Tuple 3: empieza en 8096
    - Tuple 4: empieza en 8064
    - Tuple 5: empieza en 8032

Así, **lp\_off** es literalmente la posición física del tuple dentro de la página.

 

##  ¿Por qué se hace así?

*   Para que el espacio libre quede **contiguo** entre el array de line pointers y los tuples.
*   Cuando se inserta un nuevo tuple, PostgreSQL:
    *   Añade un **nuevo line pointer** al inicio.
    *   Coloca el tuple **en el espacio libre más cercano al inicio** (pero después del último tuple).
*   Esto permite reorganizar la página sin mover los line pointers.
 

---
## 2) ¿Qué hace este fragmento?

```sql
get_byte(attrs[2],0)
  + get_byte(attrs[2],1)*256
  + get_byte(attrs[2],2)*65536
  + get_byte(attrs[2],3)*16777216
```

Ese bloque **reconstruye un `int4`** (32‑bits) a partir de sus **4 bytes** almacenados **en little‑endian** (orden de menor a mayor significancia) dentro del `bytea` del segundo atributo (`attrs[2]`).

*   `get_byte(attrs[2],0)` → byte menos significativo (LSB).
*   `get_byte(attrs[2],1)*256` → segundo byte × 2^8.
*   `get_byte(attrs[2],2)*65536` → tercer byte × 2^16.
*   `get_byte(attrs[2],3)*16777216` → cuarto byte × 2^24.

La **suma** te da el **entero**. En máquinas x86\_64 (como la tuya), los tipos fijos (int2/int4/int8) se almacenan en el *endianness* de la plataforma; por eso al leer el `t_data` crudo necesitas esa reconstrucción cuando separas atributos con `tuple_data_split(...)`.  
(La razón de separar primero con `tuple_data_split` es que `t_data` contiene headers varlena para campos `text/varchar` y **binarios**/padding para fijos; convertir todo a UTF‑8 falla). 

> **Tip sintáctico**: puedes usar **bit-shifts** para que se vea más claro:
>
> ```sql
> (get_byte(attrs[2],0)
>  | get_byte(attrs[2],1) << 8
>  | get_byte(attrs[2],2) << 16
>  | get_byte(attrs[2],3) << 24)::int AS numero
> ```



# Referencias 
```sql
-- pageinspect
 https://www.postgresql.org/docs/current/pageinspect.html

-- Understanding PostgreSQL Block Page Layout, Part 2
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-1-cd1ad0b8d503
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-2-6e61b7af6667
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-3-517e567079ee
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-4-07260d1bbc87

-- Internals of MVCC in Postgres: Hidden costs of Updates vs Inserts
   https://medium.com/@rohanjnr44/internals-of-mvcc-in-postgres-hidden-costs-of-updates-vs-inserts-381eadd35844

-- pg_visibility (El mapa de visibilidad es una estructura que mantiene información sobre qué páginas de una relación )
  https://tomasz-gintowt.medium.com/postgresql-extensions-pg-visibility-876c57e8aa81
  https://www.postgresql.org/docs/current/pgvisibility.html

```sql
 
