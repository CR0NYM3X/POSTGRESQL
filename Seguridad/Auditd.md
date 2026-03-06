# **Auditd** (Linux Audit Daemon) 
 Es el sistema oficial de **vigilancia del Kernel** de Linux.

A diferencia de un log común que registra errores, `auditd` captura **acciones en tiempo real**: registra quién entró a un archivo, qué comando ejecutó y si tuvo éxito o no, incluso antes de que la acción termine.

Es como una **caja negra de un avión** para tu servidor: si algo cambia en tu configuración de PostgreSQL, `auditd` te dirá exactamente qué usuario fue el responsable, sin importar si usó `sudo` o cambió de identidad.

 

### Sus tres pilares:

1. **Vigilancia:** Mira archivos y directorios (`-w`).
2. **Interceptación:** Rastrea llamadas al sistema (syscalls).
3. **Inmutabilidad:** Sus reglas pueden bloquearse para que ni siquiera el administrador pueda borrarlas sin reiniciar.


### 1. ¿Cómo guarda la información? (El flujo de datos)

`Auditd` no funciona como un programa normal que "lee" archivos. Funciona a través de **syscalls** (llamadas al sistema).

1. **Interceptación:** Cuando alguien intenta abrir `/sysx/data/postgresql.conf`, el **Kernel** de Linux detiene la acción un milisegundo.
2. **Generación:** El Kernel genera un evento de auditoría.
3. **Transferencia:** El demonio `auditd` recoge ese evento del kernel y lo escribe en el disco duro, específicamente en un archivo de log crudo.
4. **Escritura:** Por defecto, el destino es: **`/var/log/audit/audit.log`**.

--- 
# (Laboratorio): Monitoreo de Configuración PostgreSQL

### Objetivo

* **Archivos a proteger:** `/sysx/data/postgresql.conf` y `/sysx/data/pg_hba.conf`.
* **Objetivo:** Detectar quién lee o modifica la configuración y permitir que el usuario `postgres` audite su propio entorno.



---

## Paso 1: Instalación y Preparación (Hardening Inicial)

Antes de crear reglas, debemos asegurar que el "motor" sea robusto.

1. **Instalar el servicio:**
```bash
sudo apt install auditd audispd-plugins -y  # Debian/Ubuntu
sudo yum install audit -y                   # RHEL/CentOS

```


2. **Configuración de supervivencia (Consideración de Elastic):**
Edita `/etc/audit/auditd.conf` para evitar que el sistema se detenga si los logs se llenan:
* `max_log_file = 100` (Aumenta a 100MB si tienes mucho tráfico).
* `max_log_file_action = ROTATE` (Evita que el disco se llene y bloquee el server).
* `admin_space_left_action = SUSPEND` (Suspende la auditoría pero no el sistema si queda poco espacio).

2. **Configuración de Retención (`/etc/audit/auditd.conf`):**
Modifica estos parámetros para evitar la pérdida de eventos:
* `max_log_file = 100` (MB)
* `max_log_file_action = ROTATE`
* `disk_full_action = SYSLOG`


---

## Paso 2: Creación de Reglas Persistentes

No uses el comando `auditctl` directamente para cambios permanentes, ya que se pierden al reiniciar. Edita el archivo de reglas:
`sudo nano /etc/audit/rules.d/audit.rules`

Añade estas reglas específicas para tus archivos en `/sysx/data`:

```bash
## 1. Limpiar reglas previas
-D

## 2. Configurar el buffer (Recomendación de rendimiento)
-b 8192

## REGLAS PARA POSTGRESQL EN /sysx/data
# 1. Detectar escritura y cambios de atributos (chmod/chown)
-w /sysx/data/postgresql.conf -p wa -k postgres_conf_mod
-w /sysx/data/pg_hba.conf -p wa -k postgres_auth_mod

# 2. Detectar intentos de lectura (Exfiltración de configuración)
-w /sysx/data/postgresql.conf -p r -k postgres_conf_read
-w /sysx/data/pg_hba.conf -p r -k postgres_auth_read

## 4. Inmutabilidad (El toque del experto)
# Una vez cargadas, nadie puede cambiar las reglas sin reiniciar el sistema
#-e 2

```

**¿Por qué estas reglas?**

* `-w`: La ruta del archivo a vigilar (watch).
* `-p wa`: Monitorea escritura (**w**rite) y cambios de atributos (**a**ttribute, como permisos o dueño  (`chmod`/`chown`)).
* **`-p r`**: En Hardening avanzado, saber quién *leyó* la configuración es vital, ya que ahí pueden verse rutas de certificados o parámetros de red.
* **`-k [key]`**: Etiquetas que usaremos para buscar en los logs.

---

## Paso 3: Aplicar y Cargar

Para que los cambios tengan efecto sin reiniciar el servicio (lo cual podría interrumpir la captura):

```bash
sudo augenrules --load
sudo auditctl -l  # Lista las reglas activas

```



  
## 3. Delegación de Permisos al usuario `postgres`

Por defecto, solo `root` puede ver los logs de auditoría de la ruta `/var/log/`. Para que el administrador de la base de datos (`postgres`) pueda monitorear sin usar `sudo` ya que los logs de la herramienta se guardan en esta ruta `/var/log/audit/`, 
y no se recomienda usar chmod para otorgar el permiso, se recomienda hacer a postgres miembro del grupo audit :

### A. Permisos de Grupo

`auditd` permite definir un grupo que tenga permisos de lectura sobre los logs.

1. Añade al usuario `postgres` al grupo `audit`:
```bash
sudo groupadd -r audit
sudo gpasswd -a postgres audit

```


2. Configura `auditd` para que asigne los logs a ese grupo. Edita `/etc/audit/auditd.conf`:
```ini
log_group = audit

```


3. Reinicia el servicio: `sudo systemctl restart auditd`

```ini
sudo /usr/bin/systemctl status auditd*
sudo /usr/bin/systemctl stop auditd*
sudo /usr/bin/systemctl start auditd*
sudo /usr/bin/systemctl restart auditd*

sudo /usr/bin/systemctl disable auditd*
sudo /usr/bin/systemctl enable auditd*

```

### B. Binarios necesarios para el usuario `postgres`

Para que el usuario `postgres` analice las auditorías, necesita acceso y ejecución de las herramientas de `auditd`. Asegúrate de que tenga permisos de ejecución en:

* **/sbin/ausearch**: Se utiliza para **buscar eventos específicos** en los logs. Permite filtrar por llaves (`-k`), fechas o usuarios, convirtiendo los datos crudos en información legible.
* **/sbin/aureport**: Se utiliza para **generar resúmenes y reportes estadísticos**. Es ideal para obtener una visión general de cuántas veces se intentó acceder a los archivos de configuración en un periodo de tiempo.
* **/sbin/auditctl**: Se utiliza para **administrar el sistema de reglas y el estado del kernel**. Con este binario se cargan, eliminan o visualizan las reglas activas que vigilan la ruta `/sysx/data`.



**Consideración de Hardening:** No cambies los permisos de `/sbin/` a 777. Al haber agregado al usuario al grupo `audit` y tener permisos de ejecución sobre el binario, podrá ejecutar:

```bash
/sbin/ausearch -k postgres_auth_mod -i
```






--- 
## Paso 4: Pruebas de Ataque (Simulación)

Para validar tu laboratorio, realiza estas acciones como un usuario normal (no root si es posible):

1. **Lectura:** `cat /sysx/data/postgresql.conf`
2. **Modificación:** `echo "# Test" >> /sysx/data/pg_hba.conf`
3. **Cambio de permisos:** `chmod 644 /sysx/data/postgresql.conf`

---

## Paso 5: Análisis de Resultados (Uso de `ausearch`)

Aquí es donde aplicamos el conocimiento de **IzyKnows** para interpretar la "sopa de letras" de los logs.

**Para ver quién intentó cambiar la autenticación:**

```bash
sudo ausearch -k pg_auth_critical -i

```

* **`-k`**: Filtra por la llave que creamos.
* **`-i`**: **Interpretación**. Convierte el `UID 1000` en "juan" y los tiempos en formato legible.

> **Nota de experto:** Si ves que el campo `exe` apunta a `/usr/bin/nano` o `vi`, alguien entró manualmente. Si apunta al binario de un script, podrías tener una tarea automatizada (o un exploit) modificando accesos.


**Lo que debes buscar en el reporte:**

* `type=SYSCALL`: El comando ejecutado.
* `exe=`: El binario usado (ej: `/usr/bin/nano` o `/usr/bin/python3`).
* `auid`: El **Audit User ID**. Aunque el atacante haga `sudo su`, el `auid` registrará el usuario original que inició sesión.

---



## Consideraciones Finales y Cuidados (Hardening Mindset)

El uso de `auditd` requiere responsabilidad. Aquí están los puntos donde la mayoría falla:


1. **Orden de las reglas:**  `auditd` lee de arriba hacia abajo. Pon las reglas más específicas (tus archivos de Postgres) arriba para que se procesen más rápido.

2. **Cuidado con el flag `-p r` (Lectura):** Si PostgreSQL lee sus archivos de configuración miles de veces por segundo (poco común, pero posible según la versión), el log crecerá muy rápido. Monitorea el tamaño de `/var/log/audit/audit.log` los primeros días.

3. **Rendimiento del Kernel** Cada regla de auditoría añade una pequeña carga al procesador por cada llamada al sistema (syscall).

* **Evita:** Auditar archivos que PostgreSQL escribe constantemente (como los archivos de datos `.dat` o los WAL logs). Limítate a los de **configuración**.


4. **Centralización:** En un entorno real, no guardes los logs solo en el servidor. Usa un plugin como `audisp-remote` para enviarlos a un SIEM (como Wazuh o Elastic), porque si el hacker entra, lo primero que hará será borrar `/var/log/audit/`.

5. **Integridad de Reglas (`-e 2`):** Ten cuidado. Si pones `-e 2` y te equivocas en una regla, tendrás que **reiniciar el servidor físico/virtual** para poder corregirla. Úsalo solo cuando estés seguro de que tus reglas son perfectas.

* **Efecto:** Esto bloquea la configuración de `auditd`. Nadie (ni siquiera root) podrá cambiar las reglas hasta que el sistema se reinicie. Es vital contra atacantes que intentan borrar sus huellas.


6. **AUID vs UID:** Al revisar los logs con `ausearch`, fíjate siempre en el `auid` (Audit User ID). Si un usuario hizo `sudo su` para modificar el archivo, el `uid` dirá "root", pero el `auid` te dirá quién era el usuario **antes** de escalar privilegios.
 

7. **Ruta `/sysx/data`:** Asegúrate de que `auditd` tenga visibilidad sobre este punto de montaje. Si `/sysx` es un sistema de archivos remoto (NFS), la auditoría debe configurarse en el **servidor de origen**, no en el cliente, para que sea fiable.

8. **Binarios Protegidos:** No otorgues permisos de escritura al grupo `audit` sobre los archivos de log, solo lectura (`log_group = audit` ya maneja esto de forma segura).


9. **Gestión de Logs (El "Disk Full" es real)** `auditd` puede generar gigabytes de logs en minutos si auditas carpetas con mucho movimiento.

* **Cuidado:** Revisa `/etc/audit/auditd.conf`.
* **Ajuste:** Configura `max_log_file` (ej. 50MB) y `max_log_file_action = ROTATE` para evitar que el disco se llene y bloquee el sistema.


 
 

----

# Pasos para cambiar la ruta

1. **Editar el archivo de configuración:**
Debes entrar como `root` o con `sudo`:
```bash
sudo nano /etc/audit/auditd.conf

```


2. **Modificar el parámetro `log_file`:**
Busca la línea que dice `log_file = /var/log/audit/audit.log` y cámbiala por tu nueva ruta. Por ejemplo, si tienes un disco montado en `/sysx/`:
```ini
log_file = /sysx/audit_logs/audit.log

```


3. **Preparar el nuevo directorio:**
`auditd` es muy estricto con los permisos. Debes crear la carpeta y darle los permisos correctos antes de reiniciar el servicio:
```bash
sudo mkdir -p /sysx/audit_logs
sudo chmod 700 /sysx/audit_logs
sudo chown root:root /sysx/audit_logs

```


4. **Reiniciar el servicio:**
```bash
sudo systemctl restart auditd

```



---

### Consideraciones Críticas (Hardening Mindset)

Mover los logs no es solo "cambiar una ruta"; hay tres factores que podrían romper tu laboratorio si no los cuidas:

#### 1. SELinux (El obstáculo más común)

Si usas RHEL, CentOS o Rocky Linux, **SELinux** bloqueará a `auditd` si intenta escribir en una ruta no estándar (como `/sysx`).

* **Solución:** Debes decirle a SELinux que la nueva carpeta es para auditoría:
```bash
sudo semanage fcontext -a -t auditd_log_t "/sysx/audit_logs(/.*)?"
sudo restorecon -Rv /sysx/audit_logs

```



#### 2. Permisos para el usuario `postgres`

Recuerda que en tu solicitud pediste que el usuario `postgres` pudiera ver las auditorías. Si mueves la ruta, asegúrate de que el parámetro `log_group = audit` siga presente en el `.conf` y que la nueva carpeta pertenezca al grupo `audit`:

```bash
sudo chgrp audit /sysx/audit_logs
sudo chmod 750 /sysx/audit_logs

```

#### 3. El riesgo de "Disk Full"

Si mueves los logs a la misma partición donde están los datos de PostgreSQL (`/sysx/data`), corres un riesgo: **Si los logs de auditoría llenan el disco, la base de datos se detendrá.**

* **Recomendación:** Siempre es mejor tener los logs de auditoría en una partición o disco físico independiente de los datos de la base de datos.

### ¿Cómo verificar que funcionó?

Una vez reiniciado, ejecuta:

```bash
sudo auditctl -s | grep "log_file"

```

O simplemente intenta generar un evento (como leer un archivo vigilado) y revisa si aparece en la nueva ruta:

```bash
tail -f /sysx/audit_logs/audit.log

```
 

---
```text

https://www.elastic.co/es/security-labs/linux-detection-engineering-with-auditd
https://computernewage.com/2023/02/04/gnu-linux-audit-framework-tutorial/
https://izyknows.medium.com/linux-auditd-for-threat-detection-d06c8b941505

```
