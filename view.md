# Descripcón rápida de Views:
[Documentación Oficial](https://www.postgresql.org/docs/current/sql-createview.html) <br>

Las vistas son objetos de base de datos que representan una consulta SQL almacenada en forma de tabla virtual. Estas vistas se utilizan para simplificar consultas complejas, restringir el acceso a datos sensibles y mejorar el rendimiento de las consultas.


**`Ventajas:`** 

`Seguridad de datos:` Puedes utilizar vistas para restringir el acceso a datos sensibles. <br>
`Simplificación de consultas:` Puedes crear vistas que encapsulen lógica de consulta compleja.<br>
`Abstracción de datos:` Las vistas permiten a los usuarios acceder a datos complejos sin necesidad de conocer los detalles subyacentes de la base de datos.

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
