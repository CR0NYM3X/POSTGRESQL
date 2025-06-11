 
## **1. Introducción**  
**pg_auto_failover** fue desarrollada por Citus Data y es una extensión de PostgreSQL que permite configurar **alta disponibilidad** y **failover automático** sin necesidad de herramientas externas. Se basa en un **monitor** que supervisa los nodos y gestiona la conmutación en caso de fallos.  
 
### **Arquitectura**  
pg_auto_failover utiliza **tres componentes principales**:  
1. **Monitor**: Supervisa el estado de los nodos y decide cuándo realizar el failover.  
2. **Nodo Primario**: Servidor PostgreSQL que recibe las escrituras.  
3. **Nodo Secundario (Standby)**: Replica los datos del primario y toma el control en caso de fallo.  

### Desventaja 
**Solo soporta un nodo standby**  
- pg_auto_failover solo permite **un nodo primario y un nodo standby**, lo que limita la escalabilidad en comparación con otras soluciones como Patroni o repmgr.  
- No es ideal para arquitecturas con múltiples réplicas de lectura.


 
---
 

### **2.3. Verificar la instalación**  
```bash
pg_autoctl --version
```
Si el comando devuelve una versión, la instalación fue exitosa.

---

## **3. Configuración del Monitor**  

### **3.1. Crear el Monitor**  
El **monitor** es el nodo que supervisa el estado de los servidores PostgreSQL.  
```bash
pg_autoctl create monitor --pgdata /var/lib/postgresql/monitor --run
sudo -u postgres /usr/pgsql-12/bin/pg_autoctl create monitor --auth trust --ssl-self-signed --pgdata /var/lib/pgsql/12/data/ --pgctl /usr/pgsql-12/bin/pg_ctl
```
Esto inicia el monitor y lo deja ejecutándose en segundo plano.


### **3.2. Verificar el estado del monitor**  
```bash
pg_autoctl show state
```
Debe mostrar el estado del monitor y los nodos registrados.

--- 

## **4. Configuración del Nodo Primario**  

### **4.1. Crear el nodo primario**  
```bash
pg_autoctl create postgres --pgdata /var/lib/postgresql/primary --monitor 'postgres://autoctl_node@monitor/pg_auto_failover' --run
```
Este comando registra el nodo primario en el monitor.


 **cadena de conexión**  

```
postgres://usuario@servidor/base_de_datos
postgres://autoctl_node@monitor/pg_auto_failover

📍 **Desglose de cada parte:**  
- **`postgres://`** → Indica que se usa el protocolo PostgreSQL.  
- **`autoctl_node`** → Es el usuario que se conecta al monitor.  
- **`@monitor`** → Es el nombre del servidor donde está ejecutándose el monitor.  
- **`/pg_auto_failover`** → Es la base de datos que gestiona el estado de los nodos.  

```


### **4.2. Verificar el estado del nodo primario**  
```bash
pg_autoctl show state
```
Debe mostrar el nodo primario registrado y funcionando.

---



## **5. Configuración del Nodo Secundario (Standby)**  

### **5.1. Crear el nodo de respaldo**  
```bash
pg_autoctl create postgres --pgdata /var/lib/postgresql/standby --monitor 'postgres://autoctl_node@monitor/pg_auto_failover' --run
```
Esto configura el nodo de respaldo para replicar datos del primario.

### **5.2. Verificar la replicación**  
```bash
pg_autoctl show state
```
Debe mostrar el nodo primario y el standby sincronizados.

---



## **6. Pruebas de Failover**  

### **6.1. Simular un fallo en el nodo primario**  
```bash
pg_ctl stop -D /var/lib/postgresql/primary
```
Esto detiene el nodo primario.

### **6.2. Verificar el failover automático**  
```bash
pg_autoctl show state
```
Debe mostrar que el **standby** ha tomado el control como **nuevo primario**.

### **6.3. Restaurar el nodo primario**  
```bash
pg_ctl start -D /var/lib/postgresql/primary
```
El nodo primario vuelve a estar disponible y puede ser reintegrado.

---

## **7. Validaciones Finales**  

### **7.1. Verificar el estado del clúster**  
```bash
pg_autoctl show state
```
Debe mostrar los nodos correctamente configurados.

### **7.2. Verificar la replicación**  
```bash
psql -c "SELECT * FROM pg_stat_replication;"
```
Debe mostrar que el standby sigue sincronizado con el primario.

---


## Bibliografía
```
https://www.mydbops.com/blog/postgresql-automatic-failover-with-pg-auto-failover
https://pg-auto-failover.readthedocs.io/en/main/ref/configuration.html
https://pg-auto-failover.readthedocs.io/en/main/intro.html
https://github.com/hapostgres/pg_auto_failover
https://www.citusdata.com/blog/2019/05/30/introducing-pg-auto-failover/
https://community.microstrategy.com/s/article/How-to-configure-pg-auto-failover-on-Linux-platform?language=en_US
```
