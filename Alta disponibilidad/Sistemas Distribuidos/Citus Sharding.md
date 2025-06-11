**Citus** es una extensión de PostgreSQL que permite **escalar bases de datos distribuidas**, ideal para manejar grandes volúmenes de datos y mejorar el rendimiento en sistemas con múltiples nodos. Algunas de sus aplicaciones clave incluyen:

- **Sharding automático**: Divide los datos en múltiples nodos para distribuir la carga y mejorar la velocidad de consulta.
- **Replicación y alta disponibilidad**: Permite configurar réplicas para garantizar la continuidad del servicio en caso de fallos.
- **Paralelización de consultas**: Ejecuta consultas en múltiples nodos simultáneamente, reduciendo tiempos de respuesta.
- **Balanceo de carga**: Distribuye las consultas entre los nodos para evitar sobrecarga en un solo servidor.
- **Optimización para análisis de datos**: Mejora el rendimiento en consultas analíticas y agregaciones en grandes volúmenes de información.

 
---

### **🖥️ Escenario del laboratorio**
Imagina que tienes **tres servidores** en una red privada que formarán el clúster:
- **Coordinador**: 192.168.1.100 *(Maneja las consultas y distribuye los datos)*
- **Worker 1**: 192.168.1.101 *(Almacena parte de los datos y ejecuta queries)*
- **Worker 2**: 192.168.1.102 *(Otro nodo de almacenamiento y ejecución)*

Este esquema permitirá repartir la carga de trabajo y escalar el sistema de manera eficiente.

### **🔹 4. ¿Cuál es el objetivo del laboratorio?**
El laboratorio te ayuda a entender:
- **Cómo funciona la distribución de datos** en PostgreSQL con Citus.
- **Cómo dividir una tabla en varios nodos**, mejorando la escalabilidad.
- **Cómo ejecutar consultas en paralelo** en múltiples servidores.
- **Cómo optimizar grandes volúmenes de datos** para cargas intensivas.

### **🔹 2. ¿Cuáles son las restricciones en Citus?**
- **Las consultas deben ejecutarse en el Coordinador**: Solo el Coordinador puede distribuir datos y manejar la lógica de consulta distribuida.
- **Las tablas deben estar distribuidas** con `create_distributed_table()`, de lo contrario, funcionarán como tablas normales en PostgreSQL.
- **Algunas operaciones están limitadas**: Las transacciones distribuidas son posibles, pero tienen restricciones en operaciones como `FOREIGN KEYS` y `SEQUENCES`.
- **Esquema centralizado**: Cualquier cambio en el esquema (`ALTER TABLE`, `CREATE INDEX`, etc.) debe hacerse en el Coordinador y luego aplicarse a los Workers.


---

### **🔹 Conceptos clave**
- **Coordinador**: Nodo principal que recibe las consultas y las distribuye a los workers.
- **Workers**: Servidores que almacenan los datos de manera distribuida y procesan consultas en paralelo.
- **Sharding**: Técnica para dividir los datos en fragmentos y distribuirlos entre múltiples nodos.
- **Distribución**: Citus divide las tablas en varias partes y las asigna a los workers.

---

## **⚙️ Paso 1: Instalación en cada nodo**
Todos los servidores (coordinador y workers) deben tener PostgreSQL y Citus instalados.

### **En cada nodo (192.168.1.100, 192.168.1.101, 192.168.1.102)**
1. **Instalar PostgreSQL y Citus**
   ```bash
   sudo apt update
   sudo apt install postgresql-15 postgresql-contrib postgresql-15-citus
   ```

2. **Configurar PostgreSQL para aceptar conexiones remotas**
   En **postgresql.conf**, modifica:
   ```bash
   listen_addresses = '*'
   ```

3. **Configurar permisos en pg_hba.conf**
   Agrega estas líneas en todos los nodos para permitir conexiones internas:
   ```
   host    all    all    192.168.1.0/24    trust
   ```

4. **Reiniciar PostgreSQL**
   ```bash
   sudo systemctl restart postgresql
   ```

---

## **🚀 Paso 2: Configurar el Coordinador (192.168.1.100)**
1. **Habilitar la extensión Citus**
   ```sql
   CREATE EXTENSION citus;
   ```

2. **Agregar los workers al clúster**
   ```sql
   SELECT * FROM citus_add_node('192.168.1.101', 5432);
   SELECT * FROM citus_add_node('192.168.1.102', 5432);
   ```

---

## **🖥️ Paso 3: Configurar los Workers (192.168.1.101 y 192.168.1.102)**
1. **Habilitar la extensión en cada worker**
   ```sql
   CREATE EXTENSION citus;
   ```

2. **Verificar que los nodos están conectados**
   Desde el coordinador:
   ```sql
   SELECT * FROM citus_get_active_worker_nodes();
   ```

---

## **📊 Paso 4: Crear una tabla distribuida**
En el **coordinador (192.168.1.100)**:
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);

SELECT create_distributed_table('users', 'id');
```

Esto hará que los datos se almacenen en **Worker 1 y Worker 2**, dividiendo los registros según la clave `id`.

---

## **📌 Paso 5: Insertar datos y consultar la distribución**
Prueba insertando registros desde el coordinador:
```sql
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com'), ('Bob', 'bob@example.com');

SELECT * FROM users;
```

Citus distribuirá automáticamente los registros entre los workers.

---
 

https://docs.citusdata.com/en/v10.2/cloud/availability.html
https://www.citusdata.com/blog/2018/02/21/three-approaches-to-postgresql-replication/

