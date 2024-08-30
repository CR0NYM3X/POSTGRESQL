
## Introducción
La extensión `tablefunc` en PostgreSQL es una extensión que proporciona funciones adicionales para trabajar con tablas.

- **crosstab**: Esta función te permite convertir filas en columnas, algo muy útil para crear reportes donde quieres ver datos agrupados de manera más clara.
- **connectby**: Sirve para trabajar con datos jerárquicos, como estructuras de árbol. Por ejemplo, si tienes una tabla de empleados y sus jefes, esta función te ayuda a visualizar la jerarquía.
- **normal_rand**: Genera números aleatorios que siguen una distribución normal, útil para simulaciones estadísticas.
 


### Instalación:
    sudo yum install postgresql-contrib


## Ejemplos de uso:

### `crosstab`
La función `crosstab` convierte filas en columnas. Es especialmente útil para crear tablas pivotadas.

```sql
SELECT *
FROM crosstab(
    $$SELECT 1 as rowid, name, setting FROM pg_settings WHERE name IN ('server_version', 'data_directory', 'config_file', 'hba_file', 'ident_file', 'log_directory')$$
) AS ct(rowid int, server_version text, data_directory text, config_file text, hba_file text, ident_file text, log_directory text);
```



### normal_rand
Genera una tabla de números aleatorios con distribución normal.
```sql
SELECT * FROM normal_rand(100, 10, 5);
```
