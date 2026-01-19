# 📘 Normalización de Bases de Datos

## ¿Qué es la normalización de base de datos?

La **normalización** es un proceso sistemático que organiza los datos en una base de datos relacional para reducir la **redundancia** y mejorar la **integridad**. Se basa en dividir grandes tablas en otras más pequeñas y definir relaciones entre ellas.

En términos simples: es como ordenar una bodega para que todo esté en su lugar, sin duplicados y fácil de encontrar.

---

## ¿Cuál es el propósito de la normalización?

- **Evitar duplicidad de datos**.
- **Mejorar la consistencia** de la información.
- **Facilitar el mantenimiento** de la base de datos.
- **Optimizar el almacenamiento** y las consultas.

---

## ¿Cuál es el objetivo?

El objetivo principal es **garantizar que cada dato esté almacenado una sola vez**, en el lugar correcto, y que las relaciones entre datos sean claras y eficientes.

---

## ✅ Ventajas

- Reducción de redundancia.
- Mayor integridad de datos.
- Facilidad para actualizar y mantener.
- Mejora en el rendimiento de consultas complejas.

## ❌ Desventajas

- Mayor complejidad en el diseño.
- Más relaciones entre tablas (más JOINs).
- Puede afectar el rendimiento en consultas simples si no se optimiza bien.

---

## 🧩 Casos reales

1. **Sistema de nómina**: Evitar duplicar información de empleados en cada pago.
2. **E-commerce**: Separar productos, categorías y proveedores para mantener datos limpios.
3. **Hospitales**: Dividir pacientes, médicos y tratamientos para evitar errores en historiales clínicos.

---

## ¿Cuántas formas normales existen?

Existen **7 formas normales**, pero en la práctica se utilizan principalmente las primeras tres:

1. **Primera Forma Normal (1NF)**
2. **Segunda Forma Normal (2NF)**
3. **Tercera Forma Normal (3NF)**
4. Cuarta Forma Normal (4NF)
5. Quinta Forma Normal (5NF)
6. Forma Normal de Boyce-Codd (BCNF)
7. Sexta Forma Normal (6NF)

---

🔹 0NF – Cero Forma Normal

Definición: Es el estado en el que los datos no están normalizados. Sirve como punto de partida para aplicar las formas normales (1NF, 2NF, etc.). Pueden contener:

Repeticiones de grupos de datos.
Campos con múltiples valores (listas, arrays).
Redundancias y dependencias mal estructuradas.



## 🔢 Explicación de 1NF, 2NF y 3NF con ejemplos en PostgreSQL
 
## 🧪 EJEMPLO INICIAL (NO NORMALIZADO)

### Tabla: `ventas_super`

```sql
CREATE TABLE ventas_super (
  id_venta SERIAL PRIMARY KEY,
  cliente TEXT,
  direccion TEXT,
  productos TEXT,         -- Ejemplo: 'Arroz,Leche,Pan'
  cantidades TEXT,        -- Ejemplo: '2,1,3'
  precios_unitarios TEXT, -- Ejemplo: '20,15,10'
  total NUMERIC
);
```

### Datos simulados:

| id_venta | cliente | direccion       | productos         | cantidades | precios_unitarios | total |
|----------|---------|------------------|-------------------|------------|--------------------|-------|
| 1        | Laura   | Calle 1 #123     | Arroz,Leche,Pan   | 2,1,3      | 20,15,10           | 85    |
| 2        | Pedro   | Calle 2 #456     | Leche             | 2          | 15                 | 30    |

---



¡Claro! Aquí tienes la sección corregida con el formato que pediste, explicando claramente **qué norma de normalización se incumple**, **por qué**, y **cómo se llama esa norma**:

 
## ❌ INCUMPLIMIENTOS DE NORMALIZACIÓN

### 🔴 1NF – Grupos repetitivos  
**Incumplimiento: múltiples valores en una sola celda.**  
**Normalización: Primera Forma Normal (1NF)**  
- Las columnas `productos`, `cantidades` y `precios_unitarios` contienen **listas separadas por comas**, lo cual **viola la 1NF**.
- La 1NF exige que **cada celda contenga un solo valor atómico**, no listas ni estructuras internas.
- Esto dificulta búsquedas, filtrado y operaciones SQL eficientes.


### 🔴 2NF – Dependencias parciales  
**Incumplimiento: atributos que dependen solo de parte de la clave primaria.**  
**Normalización: Segunda Forma Normal (2NF)**  
- Si consideramos `(id_venta, producto)` como clave compuesta, los campos `cliente` y `direccion` **dependen solo de `id_venta`**, no de toda la clave.
- La 2NF exige que Todos los atributos no clave deben depender de toda la clave primaria, no solo de una parte.
- Esto genera redundancia y dificulta el mantenimiento de datos.

### 🔴 3NF – Dependencias transitivas  
**Incumplimiento: atributos que dependen de otro atributo no clave.**  
**Normalización: Tercera Forma Normal (3NF)**  
- El campo `precios_unitarios` **depende del producto**, no directamente de la clave primaria `id_venta`.
- La 3NF exige que **no haya dependencias transitivas**, es decir, que los atributos dependan **solo de la clave primaria**, no de otros atributos no clave. Ningún atributo no clave debe depender de otro atributo no clave.
- Esto puede causar inconsistencias si el precio de un producto cambia y no se actualiza en todas las filas.



---

## ✅ CORRECCIÓN: MODELO NORMALIZADO

### 🔹 Tabla: `cliente`

```sql
CREATE TABLE cliente (
  id_cliente SERIAL PRIMARY KEY,
  nombre TEXT,
  direccion TEXT
);

-- Datos
INSERT INTO cliente VALUES (1, 'Laura', 'Calle 1 #123');
INSERT INTO cliente VALUES (2, 'Pedro', 'Calle 2 #456');
```

---

### 🔹 Tabla: `producto`

```sql
CREATE TABLE producto (
  id_producto SERIAL PRIMARY KEY,
  nombre TEXT,
  precio_unitario NUMERIC
);

-- Datos
INSERT INTO producto VALUES (1, 'Arroz', 20);
INSERT INTO producto VALUES (2, 'Leche', 15);
INSERT INTO producto VALUES (3, 'Pan', 10);
```

---

### 🔹 Tabla: `venta`

```sql
CREATE TABLE venta (
  id_venta SERIAL PRIMARY KEY,
  id_cliente INTEGER REFERENCES cliente(id_cliente),
  fecha DATE DEFAULT CURRENT_DATE
);

-- Datos
INSERT INTO venta (id_cliente) VALUES (1); -- Laura
INSERT INTO venta (id_cliente) VALUES (2); -- Pedro
```

---

### 🔹 Tabla: `detalle_venta`

```sql
CREATE TABLE detalle_venta (
  id_venta INTEGER REFERENCES venta(id_venta),
  id_producto INTEGER REFERENCES producto(id_producto),
  cantidad INTEGER,
  PRIMARY KEY (id_venta, id_producto)
);

-- Datos
-- Venta 1: Laura compró Arroz (2), Leche (1), Pan (3)
INSERT INTO detalle_venta VALUES (1, 1, 2); -- Arroz
INSERT INTO detalle_venta VALUES (1, 2, 1); -- Leche
INSERT INTO detalle_venta VALUES (1, 3, 3); -- Pan

-- Venta 2: Pedro compró Leche (2)
INSERT INTO detalle_venta VALUES (2, 2, 2); -- Leche
```

---

## 🧪 Consulta final para ver la venta completa

```sql
SELECT 
  v.id_venta,
  c.nombre AS cliente,
  c.direccion,
  p.nombre AS producto,
  dv.cantidad,
  p.precio_unitario,
  (dv.cantidad * p.precio_unitario) AS total_producto
FROM venta v
JOIN cliente c ON v.id_cliente = c.id_cliente
JOIN detalle_venta dv ON v.id_venta = dv.id_venta
JOIN producto p ON dv.id_producto = p.id_producto;
```

### 🖥️ Resultado:

| id_venta | cliente | direccion     | producto | cantidad | precio_unitario | total_producto |
|----------|---------|---------------|----------|----------|------------------|----------------|
| 1        | Laura   | Calle 1 #123  | Arroz    | 2        | 20               | 40             |
| 1        | Laura   | Calle 1 #123  | Leche    | 1        | 15               | 15             |
| 1        | Laura   | Calle 1 #123  | Pan      | 3        | 10               | 30             |
| 2        | Pedro   | Calle 2 #456  | Leche    | 2        | 15               | 30             |






## 🧾 Conclusión

La normalización es una herramienta poderosa para diseñar bases de datos limpias, eficientes y seguras. Aunque puede parecer compleja al principio, sus beneficios a largo plazo en mantenimiento, escalabilidad y rendimiento son indiscutibles.

> En PostgreSQL, aplicar estas formas normales es sencillo gracias a su robusto sistema de relaciones y claves foráneas.


---

# Normalizacion explicación coloquial

explicar las reglas de normalización (las famosas Formas Normales), imagina que estamos organizando el **clóset de la casa**. Si tiras todo adentro sin orden, vas a encontrar lo que buscas, pero vas a tardar horas y probablemente rompas algo en el camino.

Aquí te explico las primeras tres reglas como si estuviéramos tomando un café:

 

## 1. Primera Forma Normal (1FN): "Un lugar para cada cosa"

La regla de oro aquí es: **Nada de grupos ni listas en una sola celda.**

* **El problema:** Imagina una tabla de "Usuarios" donde en la columna `telefonos` guardas tres números separados por una coma: `"555-123, 555-456, 555-789"`.
* **La solución:** Esto es un pecado en bases de datos. La 1FN dice que cada celda debe tener **un solo valor atómico** (indivisible). Si un usuario tiene tres teléfonos, o creas tres filas para ese usuario o, mejor aún, llevas los teléfonos a otra tabla.
* **En resumen:** Prohibido guardar "combos" o listas en un solo cuadrito.

 
## 2. Segunda Forma Normal (2FN): "Si no depende del jefe, no va en esta oficina"

Para aplicar esta, primero ya debes cumplir la 1FN. Esta regla trata sobre la **dependencia de la llave primaria**.

* **El problema:** Imagina una tabla de `Pedidos` donde la llave es el `ID_Pedido`. Si en esa misma tabla pones el `Nombre_del_Cliente`, estás cometiendo un error. ¿Por qué? Porque el nombre del cliente no depende del *pedido* en sí, sino del *cliente*.
* **La solución:** Si un dato no depende directamente de la "llave" principal de esa tabla, sácalo de ahí y llévalo a su propia tabla (`Clientes`).
* **En resumen:** Cada columna de la tabla debe decir algo sobre la **llave principal**, y nada más que sobre la llave.

 
## 3. Tercera Forma Normal (3FN): "Cero chismes (Elimina dependencias transitorias)"

Esta es la más sutil. Dice que una columna no debe depender de otra columna que **no sea la llave**.

* **El problema:** Tienes una tabla de `Empleados`. La llave es `ID_Empleado`. Tienes las columnas `Nombre`, `Codigo_Postal` y `Ciudad`.
* Aquí hay un "chisme": La `Ciudad` depende del `Codigo_Postal`, no directamente del `ID_Empleado`. Si cambias el código postal, la ciudad debería cambiar sola.


* **La solución:** Crea una tabla de `Codigos_Postales` donde guardes qué ciudad le toca a cada código. En la tabla de `Empleados` solo dejas el `Codigo_Postal`.
* **En resumen:** No busques atajos. Si el dato A depende de B, y B depende de la Llave, entonces A y B se van a su propia tabla.

 

### ¿Por qué tanto lío?

Si no normalizas, cuando un cliente cambie de nombre, vas a tener que buscar en 500 filas de pedidos para cambiarlo en todos lados (**Redundancia**). Si te olvidas de una fila, tendrás datos inconsistentes (**Anomalías**).


# Resumen 

### 1FN: Cero amontonamiento

* **Regla:** Cada celda debe tener **un solo dato**.
* **Prohibido:** Guardar listas (ej: "Salsa, Reggaetón") o varios teléfonos en un solo campo.
* **Objetivo:** Que los datos sean "atómicos" (indivisibles).

### 2FN: Cero arrimados

* **Regla:** Todo debe depender de la **llave primaria** (el ID).
* **Prohibido:** Tener datos de "otra cosa" en la tabla. Si en la tabla de *Ventas* tienes el nombre del cliente, ese nombre está "arrimado", porque depende del cliente, no de la venta.
* **Objetivo:** Eliminar la redundancia (no repetir nombres en cada fila).

### 3FN: Cero chismes

* **Regla:** Ninguna columna debe depender de otra que **no sea la llave**.
* **Prohibido:** Dependencias indirectas. Si el *Estado* depende del *Código Postal*, y el CP depende del *ID*, entonces el Estado no debe estar ahí. Es una carambola que ensucia la tabla.
* **Objetivo:** Que cada dato tenga un único lugar lógico para existir.


---
# Estrategia de normalización
Igual todo depende del crecimiento a futuro de la tabla y la cantidad de registros actual y si la tabla se realiza muchas escrituras o lecturas.


### La "Prueba del Join"
Si sientes que estás guardando un dato solo para "ahorrarte el Join", pregúntate esto:

¿Si este dato cambia, tengo que ir a actualizar 1,000 filas? * Si la respuesta es SÍ, entonces ese dato no pertenece a esa tabla.

### Ahorro de espacio 
1. **Datos de tipo texto:** Los textos largos repetidos miles de veces (como el nombre de una categoría o una dirección) ocupan mucho más espacio en disco que un simple `ID` numérico.
2. **Relación con la Llave:** Si el dato (ej. `Nombre_Proveedor`) no tiene nada que ver con la llave primaria (ej. `ID_Producto`), estás mezclando "entidades". El producto es una cosa y el proveedor es otra.




 
---


```

https://ebac.mx/blog/normalizacion-de-bases-de-datos
https://www.freecodecamp.org/espanol/news/normalizacion-de-base-de-datos-formas-normales-1nf-2nf-3nf-ejemplos-de-tablas/
https://www.datacamp.com/es/tutorial/normalization-in-sql

https://www.youtube.com/watch?v=kvt2wE-q-yY
```


