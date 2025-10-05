# Subconsultas

## 🔍 1. Subconsulta **no correlacionada**

### 📘 Definición:
Una subconsulta **no correlacionada** es aquella que **no depende de la fila actual** de la consulta externa. Se ejecuta **una sola vez**, y su resultado se reutiliza. 

### ✅ Características:
- Independiente de la consulta principal.
- Se evalúa primero.
- Puede usarse en `SELECT`, `WHERE`, `FROM`, etc.

### 🧪 Ejemplo:

```sql
SELECT nombre, salario
FROM empleados
WHERE salario > (
    SELECT AVG(salario)
    FROM empleados
);
```

 

## 🔍 2. Subconsulta **correlacionada**

### 📘 Definición:
Una subconsulta **correlacionada** depende de la **fila actual** de la consulta externa. Se ejecuta **una vez por cada fila** de la consulta principal.
Se recalculan por cada fila, lo que puede ser costoso en términos de rendimiento.  Se recalculan por cada fila, lo que puede ser costoso en términos de rendimiento. mejor utilizar Joins o CTE


### ✅ Características:
- Usa columnas de la consulta externa.
- Se evalúa múltiples veces.
- Más costosa en rendimiento.

### 🧪 Ejemplo:

```sql
SELECT e.nombre
FROM empleados e
WHERE salario > (
    SELECT AVG(salario)
    FROM empleados
    WHERE departamento_id = e.departamento_id
);
```
 

## ⚖️ Comparación rápida

| Tipo de subconsulta     | ¿Usa columnas externas? | ¿Se ejecuta por fila? | Rendimiento |
|-------------------------|-------------------------|------------------------|-------------|
| No correlacionada       | ❌ No                   | ❌ No                  | ✅ Mejor    |
| Correlacionada          | ✅ Sí                   | ✅ Sí                  | ⚠️ Más costosa |
 
---

1. Evita usar SELECT *

Alternativa: Especifica solo las columnas necesarias.
Motivo:

Incrementa la carga de red al transferir datos innecesarios.

Impide que el optimizador utilice índices cubiertos (que incluyen todas las columnas de la consulta).

Hace las consultas menos predecibles si cambian los esquemas de las tablas.



---

2. Prefiere CROSS JOIN LATERAL sobre subconsultas en ciertas condiciones

Cómo no usarlo: No utilices subconsultas correlacionadas que se ejecuten repetidamente en bucles.
Alternativa: Usa CROSS JOIN LATERAL o WITH (CTE) cuando tengas que reutilizar lógica compleja.
Motivo:

Subconsultas correlacionadas a menudo ejecutan la misma operación múltiples veces, aumentando el costo exponencialmente.

Los LATERAL y CTE son más legibles y manejables por el optimizador.



---

3. Usa índices adecuados según el tipo de consulta

Cómo no usarlo:

Evita crear un solo índice para todas las columnas, pensando que cubrirá todos los casos.

No uses índices en columnas con alta cardinalidad si no filtras con ellas.
Alternativa:

Usa índices compuestos para consultas con filtros múltiples.

Implementa índices GIN o GiST para búsquedas en arrays o documentos JSON.
Motivo:

Los índices mal diseñados generan overhead en las escrituras.

Diseñar índices alineados con tus consultas reduce significativamente los tiempos de ejecución.



---

4. Evita funciones no determinísticas en consultas repetitivas

Cómo no usarlo: No utilices funciones como NOW() o RANDOM() directamente en filtros o joins.
Alternativa: Evalúa las funciones una sola vez y almacena el resultado en una variable o tabla temporal.
Motivo:

Las funciones no determinísticas se evalúan repetidamente, ralentizando las consultas.

Esto impacta el rendimiento en tablas grandes o joins complejos.



---


---

6. Evita operaciones en columnas dentro de los filtros

Cómo no usarlo: No filtres con expresiones como WHERE DATE(column) = '2024-12-14'.
Alternativa:

Reescribe las consultas como WHERE column >= '2024-12-14 00:00:00' AND column < '2024-12-15 00:00:00'.
Motivo:

Aplicar funciones en columnas desactiva el uso de índices.

Usar rangos es más eficiente y permite que el índice sea utilizado.



____

18. No ignores el costo del ordenamiento (ORDER BY)

Cómo no usarlo: No realices operaciones de ordenamiento sin índices que puedan ayudar.
Alternativa:

Usa índices que coincidan con el orden requerido:

CREATE INDEX idx_order ON table (column ASC);

Revisa consultas con LIMIT y OFFSET para evitar cargar grandes conjuntos de datos.
Motivo:

El ordenamiento en memoria puede ser costoso para grandes cantidades de datos.

Los índices ordenados evitan escaneos completos y operaciones en memoria.




___

4. Evita cláusulas DISTINCT innecesarias

Cómo no usarlo: No uses DISTINCT para eliminar duplicados que no existen:

SELECT DISTINCT col1 FROM table WHERE condition;

Alternativa: Usa filtros específicos para prevenir duplicados desde el inicio.
Motivo:

DISTINCT puede ser costoso, ya que fuerza un ordenamiento interno antes de eliminar duplicados., válida que es mejor el grupo by o distinct

---

1. = ANY (array)

Sintaxis:

SELECT * FROM tabla WHERE columna = ANY(ARRAY[valor1, valor2, valor3]);

Ventajas:

Funciona de forma similar a IN pero es más eficiente en algunos casos porque PostgreSQL optimiza internamente el uso de arrays.

Especialmente útil cuando ya tienes un array en tu aplicación que deseas pasar como parámetro.


Cuándo usarlo:

Cuando los valores que deseas comparar ya están en un array en tu aplicación.

Para consultas parametrizadas en las que se trabaja con múltiples valores.



---

2. EXISTS

Sintaxis:

SELECT * FROM tabla t 
WHERE EXISTS (
    SELECT 1 
    FROM otra_tabla o 
    WHERE o.columna = t.columna
);

Ventajas:

Evita trabajar con listas grandes dentro de un IN.

Más eficiente cuando la lista es resultado de una subconsulta, especialmente en tablas grandes.



---
