# Descripcón rápida de Views:
[Documentación Oficial](https://www.postgresql.org/docs/current/sql-createview.html) <br>

Las vistas son objetos de base de datos que representan una consulta SQL almacenada en forma de tabla virtual. Estas vistas se utilizan para simplificar consultas complejas, restringir el acceso a datos sensibles y mejorar el rendimiento de las consultas.


**`Ventajas:`** 

`Seguridad de datos:` Puedes utilizar vistas para restringir el acceso a datos sensibles. <br>
`Simplificación de consultas:` Puedes crear vistas que encapsulen lógica de consulta compleja.<br>
`Abstracción de datos:` Las vistas permiten a los usuarios acceder a datos complejos sin necesidad de conocer los detalles subyacentes de la base de datos.


### Diferencias entre una Vista y una Vista Materializada

1. **Almacenamiento**:
   - **Vista (View)**: No almacena datos físicamente. Es una consulta almacenada que se ejecuta cada vez que se accede a la vista.
   - **Vista Materializada (Materialized View)**: Almacena los datos físicamente en una tabla que genera automaticamente Postgresql. Los datos se actualizan periódicamente o manualmente.

2. **Rendimiento**:
   - **Vista**: Puede ser más lenta si la consulta es compleja, ya que se ejecuta cada vez que se accede.
   - **Vista Materializada**: Es más rápida para consultas repetitivas, ya que los datos ya están almacenados y no necesitan ser recalculados.

3. **Actualización de Datos**:
   - **Vista**: Siempre muestra los datos más recientes, ya que ejecuta la consulta en tiempo real.
   - **Vista Materializada**: Puede no estar completamente actualizada, dependiendo de la frecuencia de actualización.

4. **Index**:
   - **Vista**: no se pueden crear .
   - **Vista Materializada**: sí se pueden crear index.

### Cuándo usar cada una

- **Usar una Vista**:
  - Cuando necesitas siempre los datos más recientes.
  - Para consultas que no se ejecutan frecuentemente o no son muy complejas.

- **Usar una Vista Materializada**:
  - Para mejorar el rendimiento de consultas complejas y repetitivas.
  - Cuando los datos no cambian con frecuencia o es aceptable que no estén completamente actualizados en tiempo real.


# Ejemplo de uso:

## Buscar View y su contenido:
```
select * from pg_views where viewname= 'pg_tables' ;
```

## Crear una View 
Supongamos que tienes una base de datos de una tienda en línea con una tabla de "productos" y una tabla de "ventas". Puedes crear una vista que muestre información sobre los productos más vendidos de la siguiente manera:
```
CREATE VIEW productos_mas_vendidos AS
SELECT p.nombre AS producto, COUNT(v.id) AS cantidad_vendida
FROM productos p
INNER JOIN ventas v ON p.id = v.producto_id
GROUP BY p.nombre
ORDER BY cantidad_vendida DESC;
```

**Así se consulta una view**
```
SELECT * FROM productos_mas_vendidos;
```


## Eliminar una view
```
DROP VIEW IF EXISTS nombre_de_la_vista;
```
---

# Vistas Materializada 
### Crear una MATERIALIZED VIEW 
```sql
CREATE MATERIALIZED VIEW nombre_vista AS
SELECT columna1, columna2 FROM tabla WHERE condiciones;
```

### Borrar 
    DROP MATERIALIZED VIEW nombre_vista;

