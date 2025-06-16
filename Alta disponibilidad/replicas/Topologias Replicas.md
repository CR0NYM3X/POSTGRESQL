# **topologías de replicación** 

###  **1. replicación direccional - Primario-Secundario (Master-Slave)**
- **Descripción**: Un nodo primario acepta escrituras y lecturas, mientras que uno o más nodos secundarios solo aceptan lecturas.
- **Uso común**: Escalar lecturas, alta disponibilidad.
- **Tipo**: Asíncrona o síncrona.


###  **2. Replicación en Cadena (Cascada)**
- **Descripción**: Un nodo secundario replica desde otro nodo secundario en lugar del primario.
- **Ventaja**: Reduce la carga en el nodo primario.
- **Ejemplo**: Primario → Secundario A → Secundario B.

###  **3. Replicación Multimaestro (Multi-Master)**
- **Descripción**: Todos los nodos pueden aceptar lecturas y escrituras.
- **Complejidad**: Alta, requiere manejo de conflictos.
- **Implementación**: No nativa en PostgreSQL, pero posible con herramientas como **BDR (Bi-Directional Replication)** o **PostgreSQL-XL**.


###  **4. Replicación Lógica**
- **Descripción**: Replica datos a nivel de tabla o base de datos, no a nivel de bloque.
- **Ventaja**: Permite replicar solo ciertas tablas, transformar datos, o replicar entre versiones distintas.
- **Uso común**: Migraciones, integración de datos.
- **Herramientas**: pglogical


###  **5. Replicación en la Nube / Geo-replicación**
- **Descripción**: Replicación entre regiones o zonas geográficas distintas.
- **Uso común**: Alta disponibilidad global, recuperación ante desastres.
- **Ejemplo**: Usado en servicios como Amazon RDS for PostgreSQL o Google Cloud SQL.



#### 6. **Replicación basada en triggers (disparadores)**
- **Herramientas**: Slony-I, Bucardo.
- **Características**:
  - Permite replicación selectiva (solo ciertas tablas).
  - Asíncrona.
  - Útil para entornos heterogéneos o con lógica de negocio compleja.

---

#### 7. **Replicación lógica personalizada**
- **Herramientas**: `pglogical`, `Debezium`, `Kafka Connect`.
- **Características**:
  - Permite replicar entre versiones distintas de PostgreSQL.
  - Ideal para integración con sistemas externos o microservicios.

---

#### 8. **Replicación circular (Ring Topology)**
- **Descripción**: Cada nodo replica al siguiente formando un anillo.
- **Ventaja**: Distribución balanceada de carga.
- **Desventaja**: Mayor complejidad y riesgo de inconsistencia si un nodo falla.

---

#### 9. **Replicación en estrella (Star Topology)**
- **Descripción**: Un nodo central (hub) replica hacia múltiples nodos hoja.
- **Uso común**: Distribución de datos desde un centro de datos principal a sucursales.

---

#### 10. **Replicación híbrida**
- **Descripción**: Combinación de replicación física y lógica.
- **Ejemplo**: Replicación física para alta disponibilidad + lógica para integración de datos.

---

#### 11. **Replicación con balanceo de carga (Load-balanced Replication)**
- **Herramientas**: `Pgpool-II`, `Patroni`, `HAProxy`.
- **Función**: Distribuye las consultas de lectura entre réplicas para mejorar el rendimiento.

---

#### 12. **Replicación con failover automático**
- **Herramientas**: `Patroni`, `repmgr`, `Stolon`.
- **Función**: Detecta fallos en el nodo primario y promueve automáticamente una réplica.


