## 🛡️ ¿Qué es Fail2Ban?

Fail2Ban Es una herramienta gratuita y de código abierto, licenciada bajo la GPL (General Public License), es un **sistema de prevención de intrusos** que analiza los archivos de log de servicios como SSH, PostgreSQL, Apache, Nginx, etc., y **bloquea automáticamente las IPs** que muestran comportamientos maliciosos (como múltiples intentos fallidos de login).

---

## ✅ Ventajas de usar Fail2Ban

### 1. **Automatización de la defensa**
- Detecta y bloquea ataques de fuerza bruta sin intervención manual.
- Reduce la carga de trabajo del administrador del sistema.

### 2. **Flexible y extensible**
- Puedes crear filtros personalizados para cualquier servicio que genere logs.
- Compatible con `iptables`, `nftables`, `firewalld`, y más.

### 3. **Ligero y eficiente**
- No consume muchos recursos.
- Ideal para servidores con recursos limitados.

### 4. **Protección en tiempo real**
- Bloquea IPs en segundos tras detectar actividad sospechosa.
- Evita que atacantes sigan intentando vulnerar el sistema.

### 5. **Compatible con múltiples servicios**
- SSH, FTP, SMTP, Apache, Nginx, PostgreSQL, MySQL, y más.
- Puedes proteger servicios críticos con reglas específicas.

### 6. **Configuración granular**
- Puedes definir el número de intentos permitidos, tiempo de bloqueo, IPs ignoradas, etc.

---

## 🔐 Importancia en producción

Fail2Ban es **crítico en producción** por estas razones:

- **Mitiga ataques automatizados** que buscan vulnerabilidades comunes.
- **Protege credenciales** de acceso a servicios como SSH y bases de datos.
- **Complementa otras medidas de seguridad** como firewalls, autenticación multifactor y monitoreo.
- **Evita saturación de logs y recursos** por intentos maliciosos constantes.

---

## 🧪 ¿Es recomendable en producción?

**Sí, absolutamente.** Pero con estas consideraciones:

### 🔍 Recomendaciones para producción:
- **Configura correctamente los filtros y jails.**
- **Agrega tus IPs administrativas a `ignoreip`** para evitar bloqueos accidentales.
- **Monitorea los logs de Fail2Ban** para ajustar parámetros como `maxretry` y `bantime`.
- **Integra con herramientas de monitoreo** como Zabbix, Prometheus o Grafana si es necesario.
- **Haz pruebas antes de aplicar en servicios críticos.**

---

## 🧰 ¿Quieres más?

Puedo ayudarte a:
- Crear una política de seguridad con Fail2Ban.
- Integrarlo con alertas por correo o Telegram.
- Configurarlo para múltiples servicios en tu infraestructura.



## 🔧 Dependencias de Fail2Ban

Fail2Ban es bastante ligero y no requiere muchas dependencias externas. Sin embargo, **sí depende de algunos componentes del sistema** para funcionar correctamente:

### ✅ **Dependencias principales**
1. **Python 3**  
   Fail2Ban está escrito en Python, por lo que necesita Python 3 instalado. Ubuntu ya lo incluye por defecto.

   Verifica con:
   ```bash
   python3 --version
   ```

2. **Systemd o SysVinit**  
   Para gestionar el servicio (`systemctl`), Fail2Ban usa systemd (presente en Ubuntu moderno).

3. **iptables o nftables**  
   Fail2Ban usa reglas de firewall para bloquear IPs. Por defecto usa `iptables`, pero también puede trabajar con `nftables`.

   Verifica con:
   ```bash
   sudo iptables -L
   ```

4. **Log files del servicio que deseas proteger**  
   Por ejemplo, para proteger SSH, Fail2Ban necesita acceso al archivo `/var/log/auth.log`.

---

## ⚠️ Consideraciones antes de implementar

### 🔐 1. **Acceso a logs**
Fail2Ban analiza los logs para detectar intentos maliciosos. Asegúrate de que:
- Los servicios que deseas proteger estén generando logs.
- Fail2Ban tenga permisos para leer esos logs.

### 🧱 2. **Firewall activo**
Si ya tienes reglas de firewall configuradas (como `ufw` o `iptables`), asegúrate de que Fail2Ban no interfiera o las sobrescriba.

### 🧪 3. **Pruebas antes de producción**
Implementa Fail2Ban primero en un entorno de pruebas si es posible, para evitar bloqueos accidentales de IPs legítimas.

### 🧠 4. **IPs confiables**
Agrega tus IPs administrativas a la lista de exclusión (`ignoreip`) para evitar que te bloquees por error.

### 📦 5. **Servicios personalizados**
Si tienes servicios propios (por ejemplo, APIs, bases de datos, etc.), necesitarás crear filtros personalizados para que Fail2Ban pueda protegerlos.

### 📊 6. **Monitoreo y alertas**
Considera integrar Fail2Ban con herramientas de monitoreo o configurar alertas por correo para saber cuándo se bloquea una IP.

---

## 🧰 Recomendaciones adicionales

- **Backup del archivo `jail.local`** antes de hacer cambios.
- **Documenta cada regla que implementes**, especialmente si trabajas en equipo.
- **Revisa los logs de Fail2Ban regularmente** para ajustar parámetros como `maxretry` o `bantime`.

--- 

## 🛡️ Manual completo para instalar y configurar Fail2Ban en Ubuntu

### ✅ **Paso 1: Actualizar el sistema**
Antes de instalar cualquier paquete, asegúrate de que tu sistema esté actualizado.

```bash
sudo apt update && sudo apt upgrade -y
```

---

### ✅ **Paso 2: Instalar Fail2Ban**

```bash
sudo apt install fail2ban -y
```

Esto instalará el servicio y sus archivos de configuración.

---

### ✅ **Paso 3: Verificar el estado del servicio**

```bash
sudo systemctl status fail2ban
```

Deberías ver algo como `active (running)`. Si no está activo, puedes iniciarlo con:

```bash
sudo systemctl start fail2ban
```

Y habilitarlo para que se inicie automáticamente:

```bash
sudo systemctl enable fail2ban
```





## 🧩 Paso 1: Verifica que PostgreSQL esté generando logs de autenticación

##  Verifica el log
```bash
tail -f /var/lib/postgresql/data/log/postgresql-2025-09-18.log
```

Edita el archivo de configuración de PostgreSQL:

```bash
sudo vim  /etc/postgresql/<versión>/main/postgresql.conf
```

Busca y ajusta estas líneas:

```conf
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'
log_connections = on
log_disconnections = on
log_line_prefix = '<%t %r %a %d %u %p %c %i>'
log_statement = none
```

> Reemplaza `<versión>` por la versión que tengas instalada, por ejemplo `14`.

Guarda y reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
/usr/lib/postgresql/16/bin/pg_ctl restart -D /var/lib/postgresql/data
```

---

## 🧩 Paso 2: Crear el filtro personalizado para PostgreSQL

Crea el archivo de filtro:

```bash
sudo vim  /etc/fail2ban/filter.d/postgresql-auth.conf
```

Agrega el siguiente contenido:

```ini
[Definition]
failregex = ^<.* <HOST>\(\d+\) .*>FATAL:  password authentication failed for user ".*"$
ignoreregex =
```

Este filtro detecta líneas como:

```
2025-09-18 08:06:33.249 UTC postgres postgres 172.19.0.4(56520) 32888 [unknown] FATAL:  password authentication failed for user "postgres"
```

---

## 🧩 Paso 3: Crear el jail para PostgreSQL

Edita el archivo `jail.local`:

```bash
sudo vim  /etc/fail2ban/jail.local
```

Agrega al final:

```ini
[postgresql-auth]
enabled = true
ignoreip = 127.0.0.1/8 ::1
port     = 5432
filter   = postgresql-auth
logpath  = /var/lib/postgresql/data/log/postgresql-$(date +%Y-%m-%d).log
maxretry = 3
findtime = 600
bantime  = 3600
backend = auto 

```

- `ignoreip`: IPs que nunca serán bloqueadas.
- `bantime`: Tiempo en segundos que una IP estará bloqueada.
- `findtime`: Tiempo en el que se cuentan los intentos fallidos.
- `maxretry`: Número de intentos fallidos antes de bloquear.
-  `backend = auto`  : Fail2Ban detecta automáticamente si debe usar systemd o polling, dependiendo de si el servicio genera logs en el journal o en archivos.

---

## 🧩 Paso 4: Reiniciar Fail2Ban

```bash
sudo systemctl restart fail2ban
```

---

## 🧩 Paso 5: Verificar que el jail esté activo

```bash
sudo fail2ban-client status
```

Deberías ver `postgresql-auth` en la lista. Para ver detalles:

```bash
sudo fail2ban-client status postgresql-auth

********************** Salida de la terminal **********************
Status for the jail: postgresql-auth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     9
|  `- File list:        /var/lib/postgresql/data/log/postgresql-2025-09-18.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     1
   `- Banned IP list:

```

---

## 🧪 Paso 6: Probar el funcionamiento

Intenta hacer login con un usuario incorrecto desde otra máquina o con `psql`:

```bash
psql -h <ip_del_servidor> -U usuario_invalido -d basededatos
```

Luego revisa el log:

```bash
sudo tail -f /var/log/fail2ban.log
```

### 🧩 Paso 5: Verifica errores en el log de Fail2Ban

```bash
sudo journalctl -xeu fail2ban
sudo journalctl -u fail2ban
```

Y verifica si la IP fue bloqueada:

```bash
sudo iptables -L -n

*************** Salida Terminal **************
root@kdc:/var/lib/postgresql/data# sudo iptables -L -n
Chain f2b-postgresql-auth (1 references)
target     prot opt source               destination
REJECT     0    --  172.19.0.4           0.0.0.0/0            reject-with icmp-port-unreachable
RETURN     0    --  0.0.0.0/0            0.0.0.0/0

```


--- 

## ✅ Comando para desbanear una IP

```bash
sudo fail2ban-client set <nombre_del_jail> unbanip <IP>

### Desbanear 
sudo fail2ban-client set postgresql-auth unbanip 172.19.0.4

 ## Banear
sudo fail2ban-client set postgresql-auth banip 172.19.0.4
```

---

## 📋 ¿Cómo saber el nombre del jail?

Si no estás seguro del nombre del jail, puedes listar los jails activos con:

```bash
sudo fail2ban-client status
```

Y luego ver los detalles de cada uno:

```bash
sudo fail2ban-client status postgresql-auth
```

---

## 🧼 ¿Cómo limpiar todos los bans (no recomendado en producción)?

Si quieres eliminar todos los bans de todos los jails (por ejemplo, en pruebas):

```bash
sudo fail2ban-client unban --all
```

> ⚠️ Esto eliminará todas las IPs bloqueadas, así que úsalo con precaución.
 
## ✅ Verifica que el filtro funcione

Usa este comando para probarlo:

```bash
sudo fail2ban-regex /var/lib/postgresql/data/log/postgresql-$(date +%Y-%m-%d).log /etc/fail2ban/filter.d/postgresql-auth.conf

****************************** Salida Terminal ****************************************
root@kdc:/var/lib/postgresql/data# sudo fail2ban-regex /var/lib/postgresql/data/log/postgresql-$(date +%Y-%m-%d).log /etc/fail2ban/filter.d/postgresql-auth.conf

Running tests
=============

Use   failregex filter file : postgresql-auth, basedir: /etc/fail2ban
Use         log file : /var/lib/postgresql/data/log/postgresql-2025-09-18.log
Use         encoding : UTF-8


Results
=======

Failregex: 1 total
|-  #) [# of hits] regular expression
|   1) [1] ^<.* <HOST>\(\d+\) .*>FATAL:  password authentication failed for user ".*"$
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [4] {^LN-BEG}ExYear(?P<_sep>[-/.])Month(?P=_sep)Day(?:T|  ?)24hour:Minute:Second(?:[.,]Microseconds)?(?:\s*Zone offset)?
`-

Lines: 4 lines, 0 ignored, 1 matched, 3 missed
[processed in 0.00 sec]

|- Missed line(s):
|  <2025-09-18 09:22:13 UTC 172.19.0.4(48138) [unknown] [unknown] [unknown] 33755 68cbcf45.83db >LOG:  connection received: host=172.19.0.4 port=48138
|  <2025-09-18 09:22:13 UTC 172.19.0.4(48154) [unknown] [unknown] [unknown] 33756 68cbcf45.83dc >LOG:  connection received: host=172.19.0.4 port=48154
|  <2025-09-18 09:22:13 UTC 172.19.0.4(48154) [unknown] postgres postgres 33756 68cbcf45.83dc authentication>DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 119: "host    all             all              172.19.0.4/32            md5"
`-
```

Esto te mostrará si la IP fue detectada correctamente.


#### 6. **Recargar configuración sin reiniciar**
```bash
sudo fail2ban-client reload
```
Recarga todos los jails sin reiniciar el servicio.



---

# Extras 

## ✅ Paso 1: Verificar si iptables está activo

Ejecuta el siguiente comando:

```bash
sudo iptables -L -n -v
```

Este comando lista todas las reglas actuales de iptables con detalles. Si ves algo como:

```
Chain INPUT (policy ACCEPT)
Chain FORWARD (policy ACCEPT)
Chain OUTPUT (policy ACCEPT)
```

...significa que iptables está activo pero **no tiene reglas configuradas** (lo cual es común en servidores recién instalados).

---

## ✅ Paso 2: Verificar si el servicio está instalado

Aunque iptables es parte del núcleo de Linux, puedes verificar si el paquete de herramientas está instalado:

```bash
dpkg -l | grep iptables
```

Si no aparece nada, instálalo con:

```bash
sudo apt install iptables -y
```

---

## ✅ Paso 3: Verificar si se está usando `iptables` o `nftables`

Ubuntu 20.04+ puede usar `nftables` como reemplazo moderno de `iptables`. Verifica cuál está en uso:

```bash
sudo update-alternatives --display iptables
```

Si ves que está apuntando a `iptables-legacy`, estás usando el sistema clásico. Si apunta a `nftables`, estás usando el nuevo sistema.

---

## ✅ Paso 4: Activar iptables si no está funcionando

Si por alguna razón iptables no está funcionando, puedes reiniciar el servicio de red para que se cargue correctamente:

```bash
sudo systemctl restart networking
```

También puedes asegurarte de que el módulo esté cargado:

```bash
sudo modprobe ip_tables
```

---

## ✅ Paso 5: Activar reglas básicas (opcional)

Puedes agregar una regla simple para verificar que iptables está funcionando:

```bash
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

Esto permite conexiones SSH. Luego verifica que la regla se haya agregado:

```bash
sudo iptables -L
```

---

## ✅ Paso 6: Guardar reglas para que persistan tras reinicio

Por defecto, las reglas de iptables **no se guardan** tras reiniciar el servidor. Para hacerlo:

1. Instala el paquete de persistencia:

   ```bash
   sudo apt install iptables-persistent -y
   ```

2. Guarda las reglas actuales:

   ```bash
   sudo netfilter-persistent save
   ```


Bibliografías:
 ```sql
https://gist.github.com/rc9000/fd1be13b5c8820f63d982d0bf8154db1
 https://github.com/rc9000/postgres-fail2ban-lockout  
 https://blog.unixpad.com/2023/05/26/bloquear-accesos-no-autorizados-en-postgres-usando-fail2ban/
 https://warlord0blog.wordpress.com/2022/09/14/fail2ban-postgresql/
 https://jpcarmona.github.io/web/blog/fail2ban/
 
 https://docs.iredmail.org/fail2ban.sql.html
 https://www.saas-secure.com/online-services/read-fail2ban-ip-from-database-and-lock.html
 https://confluence.atlassian.com/conf89/using-fail2ban-to-limit-login-attempts-1387596371.html
 https://serverfault.com/questions/627169/how-to-secure-an-open-postgresql-port
 
 
 https://serverfault.com/questions/1032015/fail2ban-postgresql-filter-not-working
 https://github.com/fail2ban/fail2ban/discussions/3660
 https://www.reddit.com/r/sysadmin/comments/16dklqn/fail2ban_regex_filter_for_postgresql/?rdt=61321
 
 
 
 https://talk.plesk.com/threads/howto-secure-a-standard-postgres-port-with-fail2ban.355984/
 
 ```



