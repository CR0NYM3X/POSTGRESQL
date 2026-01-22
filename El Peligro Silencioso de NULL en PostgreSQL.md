
# El Peligro Silencioso de NULL en PostgreSQL: Guía de Supervivencia

En SQL, `NULL` no es un valor, es un **estado**: la ausencia de información o una incógnita. No entender su naturaleza técnica puede llevar a reportes financieros erróneos, errores de lógica en aplicaciones y fallos de integridad.

## 1. La Raíz del Problema: Lógica Trivalente

A diferencia de los lenguajes de programación con lógica booleana simple (`true`/`false`), SQL utiliza **Three-Valued Logic (3VL)**:

1. **TRUE**
2. **FALSE**
3. **UNKNOWN** (Representado por `NULL`)

> **La Regla de Oro:** Cualquier operación lógica o aritmética con un `NULL` suele dar como resultado `UNKNOWN`. Si intentas filtrar algo que es "desconocido", PostgreSQL simplemente lo descarta porque no puede confirmar que cumpla la condición.

---

## 2. Los Peligros del "Efecto Contagioso"

### A. El Veneno en los Strings y Matemáticas

El `NULL` es contagioso. Si un componente de una operación es nulo, el resultado final se invalida.

* **Strings:** al concatenar `'Usuario: ' || NULL` , al comparar  **(`'hola'=NULL` o `'hola'!=NULL`):** y otras, el  resulta sera `NULL`  . (Borra toda la cadena).
* **Aritmética:** `100 + NULL` resulta en `NULL`.

### B. El Error "Mortal" del `NOT IN`

Si intentas excluir valores usando una lista que contiene un nulo, la consulta devolverá **cero resultados**.

* `WHERE id NOT IN (1, 2, NULL)` -> PostgreSQL no puede asegurar que tu ID no sea igual a ese valor "desconocido", por lo que invalida toda la condición y no retornara nada.

### C. Métricas Engañosas (Funciones de Agregación)

* `SUM`, `AVG`, `MIN`, `MAX`: **Ignoran** los nulos. Si promedias salarios y la mitad son nulos, el promedio será solo sobre la mitad que tiene datos, falseando la métrica real de la empresa.
* `COUNT(*)` vs `COUNT(columna)`: El primero cuenta filas, el segundo solo cuenta donde la columna no es nula.

---

## 3. Herramientas para "Domar" los NULLs

PostgreSQL ofrece operadores específicos para manejar la incertidumbre de forma segura:

| Si quieres... | Usa esta función / operador | ¿Qué hace exactamente? | Ejemplo práctico |
| --- | --- | --- | --- |
| **Saber si un campo está vacío** | `IS NULL` | Devuelve `verdadero` si el valor no existe. | `WHERE telefono IS NULL` (Dame los que no tienen teléfono) |
| **Saber si un campo tiene datos** | `IS NOT NULL` | Devuelve `verdadero` si el campo tiene cualquier valor. | `WHERE email IS NOT NULL` (Dame solo los que sí tienen email) |
| **Cambiar un NULL por otro valor** | `COALESCE(valor, reemplazo)` | Si el valor es `NULL`, pone lo que tú digas (ej. un cero). | `COALESCE(comision, 0)` (Si no tiene comisión, que sea 0 para poder sumar) |
| **Comparar dos cosas (incluyendo nulos)** | `IS DISTINCT FROM` | Compara dos valores y **no se rompe** si uno es `NULL`. | `WHERE categoria IS DISTINCT FROM 'Web'` (Trae todo lo que no sea 'Web', **incluyendo los nulos**) |
| **Evitar errores matemáticos** | `NULLIF(a, b)` | Si los dos valores son iguales, devuelve `NULL`. | `100 / NULLIF(divisor, 0)` (Si el divisor es 0, lo vuelve NULL y evita que la base de datos explote) |

### Control de Ordenamiento (`ORDER BY`)

Por defecto, los `NULL` son "más grandes" (van al final en `ASC`). Puedes controlarlo:

| Comando | Ubicación de los NULL |
| --- | --- |
| `ORDER BY precio ASC` | Al final (comportamiento por defecto) |
| `ORDER BY precio DESC` | Al principio (comportamiento por defecto) |
| `ORDER BY precio ASC NULLS FIRST` | **Al principio** |
| `ORDER BY precio DESC NULLS LAST` | **Al final** |


---

## 4. Configuración Avanzada: `transform_null_equals`

Existe un parámetro para aplicaciones legadas (como Microsoft Access) que intentan hacer `columna = NULL`.
```SQL
SET transform_null_equals = on;
```
* **`off` (Por defecto):** `x = NULL` es siempre *Unknown*.
* **`on`:** Transforma automáticamente `x = NULL` a `x IS NULL`.

**⚠️ Advertencia de Arquitectura:** No se recomienda activarlo. Rompe el estándar SQL, no funciona comparando dos columnas entre sí y dificulta la depuración para otros desarrolladores.

---

## 5. Laboratorio: Caso de la Vida Real

Imagina un inventario donde algunos productos no tienen categoría asignada (`NULL`). El jefe pide un reporte de **"Todos los productos que NO sean de Computación"**.

### Preparación del Escenario

```sql
-- DROP TABLE inventario;
--  truncate table inventario  RESTART IDENTITY ;
-- Crear la tabla
CREATE TABLE inventario (
    id SERIAL PRIMARY KEY,
    producto VARCHAR(50),
    categoria TEXT, -- Columna 3: Solo 3 registros serán NULL
    precio NUMERIC(10, 2)
);

INSERT INTO inventario (producto, categoria, precio) VALUES
('Laptop Pro', 'Computación', 1200.00),
('Smartphone X', 'Telefonía', 800.00),
('Teclado RGB', NULL, 45.00),         -- Sin categoría
('Monitor 4K', 'Monitores', 350.00),
('Mouse Pad', NULL, 15.00);           -- Sin categoría


select * from inventario;
+----+--------------+-------------+---------+
| id |   producto   |  categoria  | precio  |
+----+--------------+-------------+---------+
|  1 | Laptop Pro   | Computación | 1200.00 |
|  2 | Smartphone X | Telefonía   |  800.00 |
|  3 | Teclado RGB  | NULL        |   45.00 |
|  4 | Monitor 4K   | Monitores   |  350.00 |
|  5 | Mouse Pad    | NULL        |   15.00 |
+----+--------------+-------------+---------+
(5 rows)



```

### El Error Comúnes (Pérdida de Datos)

```sql
-- Esto SOLO devuelve 'Smartphone X' y 'Monitor 4K'.
-- ¡Los productos con categoría NULL desaparecieron del reporte!
SELECT * FROM inventario WHERE categoria != 'Computación';

+----+--------------+-----------+--------+
| id |   producto   | categoria | precio |
+----+--------------+-----------+--------+
|  2 | Smartphone X | Telefonía | 800.00 |
|  4 | Monitor 4K   | Monitores | 350.00 |
+----+--------------+-----------+--------+
(2 rows)


```

### Las 3 Soluciones Profesionales


1. **La Elegante (Específica de Postgres):**
```sql
-- Trata el NULL como un valor comparable
SELECT * FROM inventario WHERE categoria IS DISTINCT FROM 'Computación';

+----+--------------+-----------+--------+
| id |   producto   | categoria | precio |
+----+--------------+-----------+--------+
|  2 | Smartphone X | Telefonía | 800.00 |
|  3 | Teclado RGB  | NULL      |  45.00 |
|  4 | Monitor 4K   | Monitores | 350.00 |
|  5 | Mouse Pad    | NULL      |  15.00 |
+----+--------------+-----------+--------+
(4 rows)
```

2. **La Explícita (Recomendada para legibilidad):**
```sql
SELECT * FROM inventario WHERE categoria != 'Computación' OR categoria IS NULL;

+----+--------------+-----------+--------+
| id |   producto   | categoria | precio |
+----+--------------+-----------+--------+
|  2 | Smartphone X | Telefonía | 800.00 |
|  3 | Teclado RGB  | NULL      |  45.00 |
|  4 | Monitor 4K   | Monitores | 350.00 |
|  5 | Mouse Pad    | NULL      |  15.00 |
+----+--------------+-----------+--------+

```


3. **La Preventiva (Transformación):**
```sql

-- Recordemos que COALESCE si encuntra que el valor es nulo lo remplaza con el valor que colocas en el segundo parámetro
SELECT * FROM inventario WHERE COALESCE(categoria, 'N/A') != 'Computación';

+----+--------------+-----------+--------+
| id |   producto   | categoria | precio |
+----+--------------+-----------+--------+
|  2 | Smartphone X | Telefonía | 800.00 |
|  3 | Teclado RGB  | NULL      |  45.00 |
|  4 | Monitor 4K   | Monitores | 350.00 |
|  5 | Mouse Pad    | NULL      |  15.00 |
+----+--------------+-----------+--------+
(4 rows)


```

---

### Ejemplos Extras 

```SQL

postgres@postgres# select * from inventario;
+----+--------------+-------------+---------+
| id |   producto   |  categoria  | precio  |
+----+--------------+-------------+---------+
|  1 | Laptop Pro   | Computación | 1200.00 |
|  2 | Smartphone X | Telefonía   |  800.00 |
|  3 | Teclado RGB  | NULL        |   45.00 |
|  4 | Monitor 4K   | Monitores   |  350.00 |
|  5 | Mouse Pad    | NULL        |   15.00 |
+----+--------------+-------------+---------+
(5 rows)

Time: 1.613 ms

postgres@postgres#  select id,producto, concat(categoria || ' - Dato Extra') from inventario;
+----+--------------+--------------------------+
| id |   producto   |          concat          |
+----+--------------+--------------------------+
|  1 | Laptop Pro   | Computación - Dato Extra |
|  2 | Smartphone X | Telefonía - Dato Extra   |
|  3 | Teclado RGB  |                          |
|  4 | Monitor 4K   | Monitores - Dato Extra   |
|  5 | Mouse Pad    |                          |
+----+--------------+--------------------------+
(5 rows)


postgres@postgres# select * from inventario where categoria != 'Telefonía' ;
+----+------------+-------------+---------+
| id |  producto  |  categoria  | precio  |
+----+------------+-------------+---------+
|  1 | Laptop Pro | Computación | 1200.00 |
|  4 | Monitor 4K | Monitores   |  350.00 |
+----+------------+-------------+---------+
(2 rows)

Time: 0.823 ms
postgres@postgres# select * from inventario where categoria != 'Telefonía' OR categoria is null;
+----+-------------+-------------+---------+
| id |  producto   |  categoria  | precio  |
+----+-------------+-------------+---------+
|  1 | Laptop Pro  | Computación | 1200.00 |
|  3 | Teclado RGB | NULL        |   45.00 |
|  4 | Monitor 4K  | Monitores   |  350.00 |
|  5 | Mouse Pad   | NULL        |   15.00 |
+----+-------------+-------------+---------+
(4 rows)

Time: 0.371 ms




postgres@postgres# select * from inventario where categoria not in('Telefonía','Computación');
+----+------------+-----------+--------+
| id |  producto  | categoria | precio |
+----+------------+-----------+--------+
|  4 | Monitor 4K | Monitores | 350.00 |
+----+------------+-----------+--------+
(1 row)

Time: 0.909 ms
postgres@postgres# select * from inventario where categoria not in('Telefonía','Computación',null);
+----+----------+-----------+--------+
| id | producto | categoria | precio |
+----+----------+-----------+--------+
+----+----------+-----------+--------+
(0 rows)

Time: 0.580 ms
postgres@postgres# select * from inventario where categoria not in( select categoria from inventario where categoria = 'Telefonía' or categoria  is null);
+----+----------+-----------+--------+
| id | producto | categoria | precio |
+----+----------+-----------+--------+
+----+----------+-----------+--------+
(0 rows)

Time: 0.817 ms
postgres@postgres# select * from inventario where categoria  in('Telefonía','Computación',null);
+----+--------------+-------------+---------+
| id |   producto   |  categoria  | precio  |
+----+--------------+-------------+---------+
|  1 | Laptop Pro   | Computación | 1200.00 |
|  2 | Smartphone X | Telefonía   |  800.00 |
+----+--------------+-------------+---------+
(2 rows)

Time: 0.465 ms
postgres@postgres# select COUNT(*) from inventario ;
+-------+
| count |
+-------+
|     5 |
+-------+
(1 row)

Time: 0.367 ms
postgres@postgres# select COUNT(categoria) from inventario ;
+-------+
| count |
+-------+
|     3 |
+-------+
(1 row)

Time: 1.047 ms


postgres@postgres#  SELECT NULL IS NOT DISTINCT FROM NULL;
+----------+
| ?column? |
+----------+
| t        |
+----------+
(1 row)

Time: 0.321 ms
postgres@postgres# SELECT NULL IS DISTINCT FROM NULL;
+----------+
| ?column? |
+----------+
| f        |
+----------+
(1 row)

Time: 0.214 ms
postgres@postgres# SELECT NULL IS DISTINCT FROM 5;
+----------+
| ?column? |
+----------+
| t        |
+----------+
(1 row)

Time: 0.274 ms
postgres@postgres# SELECT NULL !=  5;
+----------+
| ?column? |
+----------+
| NULL     |
+----------+
(1 row)

Time: 0.227 ms


```
---

## Recomendaciones Finales de Diseño

1. **Usa `NOT NULL` por defecto en las columnas:** Si el dato es vital para la lógica de negocio (ej. `activo BOOLEAN`), usa `NOT NULL DEFAULT false`.
2. **Permite `NULL` solo con intención:** Úsalo únicamente cuando "desconocido" sea un estado válido del negocio (ej. "Fecha de defunción").
3. **Prefiere `IS DISTINCT FROM`:** Es la forma más robusta de comparar variables en procedimientos almacenados donde los parámetros pueden llegar nulos.

