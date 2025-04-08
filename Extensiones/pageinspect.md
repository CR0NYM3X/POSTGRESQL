

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


# Referencias 
```sql
-- pageinspect
 https://www.postgresql.org/docs/current/pageinspect.html

-- Understanding PostgreSQL Block Page Layout, Part 2
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-1-cd1ad0b8d503
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-2-6e61b7af6667
   https://medium.com/@nikolaykudinov/understanding-postgresql-block-page-layout-part-3-517e567079ee

-- Internals of MVCC in Postgres: Hidden costs of Updates vs Inserts
   https://medium.com/@rohanjnr44/internals-of-mvcc-in-postgres-hidden-costs-of-updates-vs-inserts-381eadd35844

-- pg_visibility (El mapa de visibilidad es una estructura que mantiene información sobre qué páginas de una relación )
  https://tomasz-gintowt.medium.com/postgresql-extensions-pg-visibility-876c57e8aa81
  https://www.postgresql.org/docs/current/pgvisibility.html

```sql
 
