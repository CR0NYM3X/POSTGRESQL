# Catálogo de Mantenimientos Permitidos en Nodos Réplica (Síncronos y Asíncronos)

En un entorno Fintech bancario, los nodos réplica no son servidores pasivos; son componentes críticos para la distribución de lecturas, reportes analíticos y la resiliencia del negocio. Sin embargo, debido a la naturaleza estricta de la replicación por streaming de PostgreSQL, **las réplicas operan en modo estrictamente de Solo Lectura (`Hot Standby`)**.

Como experto en bases de datos y SRE, es fundamental aclarar un concepto erróneo común: **no se pueden ejecutar comandos de escritura o alteración estructural (como `VACUUM FULL`, `REINDEX` o `ANALYZE`) directamente en una réplica**. Estos procesos deben ejecutarse obligatoriamente en el Maestro y se replicarán automáticamente a los esclavos a través del WAL.

Dicho esto, existe un catálogo extenso de mantenimientos locales (a nivel de infraestructura, sistema operativo, configuración y diagnóstico) que se pueden y deben realizar en las réplicas.

---

## 1. Tipos de Mantenimiento Permitidos en las Réplicas

### A. Mantenimiento de Infraestructura y Escalamiento Físico

Al ser nodos individuales en tu clúster de Patroni, puedes realizar tareas de escalamiento vertical sin afectar al Maestro:

* **Ampliación de Recursos Computacionales:** Incrementar CPU y Memoria RAM en caliente o mediante un breve reinicio programado (vital si las queries analíticas de PgBouncer están saturando el nodo).
* **Expansión de Almacenamiento (Disks/Volumes):** Ampliar el tamaño de los volúmenes NVMe/SSD a nivel de hipervisor o la nube, y extender el sistema de archivos en caliente utilizando LVM (`lvextend` y `resize2fs` / `xfs_growfs`).
* **Reemplazo Preventivo de Hardware:** En servidores físicos, realizar cambios de fuentes de poder, tarjetas de red (NICs) o módulos RAM defectuosos.

### B. Mantenimiento del Sistema Operativo y Capa de Seguridad (SecOps)

* **Parcheo de Seguridad (Patching):** Actualización de librerías críticas del sistema operativo (como `openssl`, `glibc`, parches del Kernel de Linux o actualizaciones menores del motor de PostgreSQL).
* **Auditoría e Inalterabilidad de Logs (pgAudit / Syslog):** Rotación, depuración y mantenimiento de los discos destinados a los logs de cumplimiento de `pgAudit`. Asegurar el correcto reenvío de logs locales hacia el SIEM centralizado del banco.
* **Tuning del Kernel de Linux:** Ajustar parámetros en el archivo `/etc/sysctl.conf` específicos para bases de datos (como `vm.swappiness`, `vm.overcommit_memory`, o *Huge Pages*) sin interrumpir la producción del maestro.

### C. Ajustes de Configuración Local y Optimización de Consultas (`Tuning`)

Existen parámetros en el archivo de configuración que son específicos para optimizar el comportamiento de los nodos esclavos:

* **Ajuste de `max_standby_streaming_delay` y `max_standby_archive_delay`:** Modificar estos tiempos para evitar los famosos "Conflictos de Replicación" (*Replication Conflicts*), que ocurren cuando una consulta de lectura larga en la réplica bloquea la aplicación de un WAL enviado por el maestro.
* **Activación de `hot_standby_feedback`:** Cambiar este parámetro a `on` de forma local para que la réplica le informe al maestro qué transacciones está leyendo, evitando que el maestro limpie filas muertas antes de tiempo (*Vacuum cleanup*) y rompa las lecturas de la réplica.

### D. Pruebas de Continuidad del Negocio (BCP / DR Drills)

* **Validación de Restauración con pgBackRest:** Utilizar la capacidad de cómputo y almacenamiento del nodo asíncrono para ejecutar pruebas de restauración controladas (*Point-In-Time Recovery - PITR*) en directorios temporales, certificando que los backups bancarios son 100% funcionales ante auditorías externas.

---

## 2. Diferencias Críticas de Impacto: Nodo Síncrono vs. Asíncrono

Aunque las tareas son similares, el riesgo operativo y el impacto en la disponibilidad del core bancario varían drásticamente según el rol del nodo que se va a intervenir:

| Tipo de Réplica | Impacto al Detener el Nodo | Nivel de Riesgo Operativo | Consideración Arquitectónica |
| --- | --- | --- | --- |
| **Réplica Asíncrona** | **Mínimo:** HAProxy la remueve del pool de lecturas. El Maestro y la réplica síncrona continúan operando con normalidad. | **Bajo** | Si el mantenimiento toma muchas horas, el Maestro acumulará archivos WAL en su directorio `pg_wal` para no perder la sincronía histórica, vigilando que no se llene el disco del líder. |
| **Réplica Síncrona** | **Moderado/Alto:** Si no tienes Quórum Dinámico, detenerla congelará las escrituras en el Maestro de inmediato. | **Crítico** | **Obligatorio:** Antes de apagarla, el DBA debe verificar que la réplica asíncrona esté al día y configurada en el pool `FIRST 1` de Patroni para que asuma la carga síncrona instantáneamente sin generar interrupciones (**RTO = 0**). |

---

## 3. Flujo Correcto para Ejecutar un Mantenimiento Local en una Réplica

Para realizar cualquiera de los mantenimientos del catálogo anterior, el DBA debe aplicar el siguiente procedimiento estricto de aislamiento:

### Paso 1: Poner el Nodo en Modo de Mantenimiento Externo

* Informar a Patroni que el nodo será intervenido manualmente para evitar que el orquestador genere alertas falsas o intente realizar un aprovisionamiento forzado:
```bash
patronictl -c /etc/patroni/patroni.yml pause --node <nombre_del_nodo_replica>

```



### Paso 2: Detener los Servicios y Aislar el Tráfico

* Detener el demonio de Patroni, lo cual apagará PostgreSQL de forma segura:
```bash
systemctl stop patroni

```


* Verificar en la consola de **HAProxy** que el nodo ha pasado a estado `DOWN` y que el pool de conexiones de **PgBouncer** ha redirigido las consultas de lectura a los nodos supervivientes.

### Paso 3: Ejecutar el Mantenimiento

* Realizar la tarea planificada (ej: añadir RAM, actualizar paquetes, expandir discos, modificar configuraciones).

### Paso 4: Reincorporación y Quitar Pausa

* Una vez finalizado el trabajo, encender los servicios:
```bash
systemctl start patroni

```


* Reanudar la supervisión automatizada quitando el estado de pausa en Patroni:
```bash
patronictl -c /etc/patroni/patroni.yml resume --node <nombre_del_nodo_replica>

```


* Monitorear el comando `patronictl list` hasta comprobar que el estado del nodo regresa a `running` y su *Lag* con respecto al Maestro vuelve a ser exactamente cero.

---

## Resumen Ejecutivo para tu Cliente

> "En nuestra arquitectura Fintech, los mantenimientos en las réplicas permiten actualizar el sistema operativo, escalar el hardware (CPU/RAM/Discos) y tunear la base de datos sin afectar al nodo Maestro. Los mantenimientos estructurales de datos (como remover bloat con Vacuum) se ejecutan únicamente en el Maestro y se heredan por replicación. Aplicando el aislamiento correcto a través de **Patroni** y confiando en el **Quórum Dinámico**, mantener una réplica síncrona o asíncrona genera un **RTO = 0** para el negocio, asegurando la continuidad total de los servicios financieros."
