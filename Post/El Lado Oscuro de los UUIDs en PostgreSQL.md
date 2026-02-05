# 🚨 El Lado Oscuro de los UUIDs en PostgreSQL: Rendimiento, Riesgos y Recomendaciones

Cuando diseñamos una base de datos, elegir la clave primaria no es solo una decisión de diseño: es una estrategia de rendimiento. Los UUIDs (Identificadores Únicos Universales) se han vuelto populares por su capacidad de garantizar unicidad global, especialmente en sistemas distribuidos. Pero ¿qué pasa cuando los usamos como claves primarias en PostgreSQL?

Este artículo expone los **riesgos ocultos**, **impactos en el rendimiento** y **alternativas recomendadas** para ayudarte a tomar decisiones informadas y evitar cuellos de botella silenciosos en tus sistemas.



## 🧠 ¿Qué es un UUID y por qué se usa?

Un UUID es un valor de 128 bits diseñado para ser único en tiempo y espacio. PostgreSQL ofrece funciones como `gen_random_uuid()` para generar UUIDv4 (completamente aleatorios).

### ✅ Ventajas:
- **Unicidad global** sin coordinación entre sistemas.
- **Seguridad**: difíciles de adivinar.
- **Escalabilidad**: ideales para sistemas distribuidos.
- **Exposición segura**: aptos para APIs públicas.

### ❌ Desventajas:
- **Aleatoriedad total** → problemas de rendimiento.
- **Mayor tamaño** → más espacio en disco y memoria.
- **Fragmentación de índices** → inserciones lentas.
- **Ineficiencia en caché** → más I/O y menos hits.



## ⚠️ Problemas Clave al Usar UUIDs como Clave Primaria

### 1. 📦 Aumento del Tamaño de Almacenamiento

Un UUID ocupa 16 bytes, mientras que un entero (INT o BIGINT) ocupa 4 u 8 bytes. Esto afecta no solo la columna principal, sino también las claves foráneas y los índices.

```sql
-- UUID
550e8400-e29b-41d4-a716-446655440000  -- 16 bytes

-- Integer
123456789                             -- 4 bytes
```

🔍 **Impacto**: Más espacio → más I/O → menor rendimiento.



### 2. 🌪️ Fragmentación de Índices

PostgreSQL usa índices B-tree, que funcionan mejor con datos secuenciales. Los UUIDv4, al ser aleatorios, provocan inserciones en posiciones impredecibles, lo que fragmenta el índice.

📉 **Consecuencias**:
- Páginas parcialmente llenas.
- Más operaciones de split.
- Mayor mantenimiento (vacuum, reindex).



### 3. 🧊 Ineficiencia en Caché

Los sistemas de caché funcionan mejor con datos secuenciales. Los UUIDs dispersan los datos en múltiples páginas, reduciendo los aciertos en caché.

```sql
-- Secuencia INT: 1, 2, 3, 4 → alta eficiencia de caché
-- Secuencia UUID: aleatoria → baja eficiencia de caché
```

📛 **Resultado**: Más lecturas desde disco, menos rendimiento.



### 4. 🐢 Joins y Búsquedas Más Lentas

Las operaciones JOIN con UUIDs como claves foráneas son más lentas debido al tamaño y la fragmentación de índices.

```sql
SELECT o.order_id, c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date = '2023-01-01';
```

🔍 **Comparación**: Este JOIN es más eficiente con claves INT que con UUIDs.



## 🔄 Comparativa: UUID vs BigSerial

| Característica         | UUID                          | BigSerial                      |
||-|--|
| Tamaño                 | 16 bytes                      | 8 bytes                        |
| Rendimiento            | Bajo (por aleatoriedad)       | Alto (por secuencialidad)      |
| Seguridad              | Alta (difícil de adivinar)    | Baja (predecible)              |
| Escalabilidad          | Alta (ideal para distribuidos)| Media                          |
| Legibilidad            | Media                         | Baja                           |
| Mantenimiento          | Alto                          | Bajo                           |



## ✅ Recomendaciones Profesionales

### 1. Usa `BIGSERIAL` para identificadores internos

Ideal cuando el rendimiento y la simplicidad son prioridad.

```sql
CREATE TABLE orders (
  order_id BIGSERIAL PRIMARY KEY,
  customer_id INT,
  order_date DATE
);
```



### 2. Usa UUIDs como identificadores externos

Perfectos para APIs, URLs o sistemas distribuidos. Úsalos como claves secundarias.

```sql
CREATE TABLE orders (
  order_id BIGSERIAL PRIMARY KEY,
  uuid UUID UNIQUE,
  customer_id INT,
  order_date DATE
);
```



### 3. Enfoque híbrido: Prefijo secuencial + UUID

Combina lo mejor de ambos mundos: rendimiento y unicidad.

```sql
-- Ejemplo de ID híbrido
order_id: "0001-550e8400e29b41d4a716446655440000"
```



### 4. Consideraciones adicionales

- **Separar identificadores internos y externos**.
- **Usar hashing para acortar IDs**.
- **Revisar requisitos legales** (ej. facturación secuencial).


 

##   ¿Cuándo Usar UUIDs y Cuándo Evitarlos?

Elegir entre UUIDs y claves secuenciales como `BIGSERIAL` depende del contexto técnico, los requisitos del sistema y las prioridades del proyecto. Aquí te dejo una guía práctica para tomar decisiones informadas:

 

### ✅ Cuándo Usar UUIDs

1. **Sistemas distribuidos o microservicios**
   - Cuando múltiples nodos generan datos simultáneamente sin coordinación.
   - Ejemplo: aplicaciones con múltiples servidores que insertan registros en paralelo.

2. **Exposición pública de identificadores**
   - Cuando los IDs se muestran en URLs, APIs o interfaces externas.
   - UUIDs son más seguros y difíciles de adivinar que los enteros secuenciales.

3. **Requisitos de unicidad global**
   - Cuando se necesita evitar colisiones entre sistemas independientes.
   - Ejemplo: sincronización de datos entre bases de datos de diferentes regiones.

4. **Privacidad y seguridad**
   - Cuando se quiere evitar que los usuarios deduzcan el volumen de datos o el orden de inserción.

5. **Integración con sistemas externos**
   - Cuando otros sistemas ya usan UUIDs como identificadores estándar.

---

### ❌ Cuándo No Usar UUIDs

1. **Bases de datos con alto volumen de escritura**
   - UUIDs aleatorios fragmentan los índices y reducen el rendimiento de inserciones.

2. **Consultas frecuentes con JOINs**
   - Las operaciones de unión son más lentas con UUIDs por su tamaño y dispersión.

3. **Sistemas que requieren eficiencia en caché**
   - Los UUIDs reducen la efectividad del caché por su naturaleza no secuencial.

4. **Simplicidad y legibilidad**
   - En sistemas internos donde los IDs no se exponen, los enteros son más fáciles de manejar y entender.

5. **Requisitos legales de numeración secuencial**
   - Por ejemplo, facturas o folios que deben seguir un orden numérico por regulación.

 


## 🧭 Conclusión

Los UUIDs ofrecen ventajas claras en sistemas distribuidos, pero su uso como clave primaria en PostgreSQL puede convertirse en una trampa silenciosa de rendimiento. Fragmentación de índices, baja eficiencia de caché y joins lentos son solo algunos de los problemas que pueden surgir.

🔧 **Recomendación final**: Usa UUIDs con criterio. Evalúa tus necesidades de unicidad, rendimiento y escalabilidad. Considera enfoques híbridos o secundarios para mantener tu base de datos rápida, eficiente y preparada para crecer.


# Links de referencias
```
https://medium.com/@Tom1212121/postgresql-uuid-and-bigserial-c943531d07c5
```
