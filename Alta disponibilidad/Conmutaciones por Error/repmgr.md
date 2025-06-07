
### **Repmgr**
Es una herramienta de código abierto para la gestión de replicación y failover en PostgreSQL. Fue desarrollada originalmente por 2ndQuadrant, que luego fue adquirida por EnterpriseDB (EDB)




### ¿Para qué sirve un Witness Node?

Evita divisiones en el clúster (split-brain). ✅ Confirma el estado de los nodos primario y standby en caso de falla. ✅ Ayuda a decidir si el failover debe ocurrir y cuál nodo debe ser promovido.

1️⃣ Monitorea los nodos primario y standby. 2️⃣ En caso de caída del primario, ayuda a validar la promoción del standby. 3️⃣ Evita que ambos nodos crean que son primarios, garantizando una transición correcta.

💡 Es como un árbitro en un partido: no juega, pero decide quién gana en caso de empate.

## Bibliografía
```
https://www.repmgr.org/docs/current/index.html
https://www.repmgr.org/docs/current/configuration.html
https://www.repmgr.org/docs/current/configuration-file.html#CONFIGURATION-FILE-FORMAT

https://www.enterprisedb.com/postgres-tutorials/how-implement-repmgr-postgresql-automatic-failover?lang=en
https://medium.com/@fekete.jozsef.joe/create-a-highly-available-postgresql-cluster-in-linux-using-repmgr-and-keepalived-9d72aa9ef42f
https://medium.com/@muhilhamsyarifuddin/postgresql-ha-with-repmgr-and-keepalived-f466bb6aa437
https://medium.com/@humzaarshadkhan/postgresql-12-replication-and-failover-with-repmgr-6ffcbe24e342
https://medium.com/@mattbiondis/postgresql-streaming-replication-using-repmgr-master-slave-c742141bc3fd

```
