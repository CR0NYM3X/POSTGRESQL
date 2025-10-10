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


```
https://ebac.mx/blog/normalizacion-de-bases-de-datos
https://www.freecodecamp.org/espanol/news/normalizacion-de-base-de-datos-formas-normales-1nf-2nf-3nf-ejemplos-de-tablas/
https://www.datacamp.com/es/tutorial/normalization-in-sql
```
