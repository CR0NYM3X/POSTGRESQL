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
sudo nano /etc/postgresql/<versión>/main/postgresql.conf
```

Busca y ajusta estas líneas:

```conf
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'
log_connections = on
log_disconnections = on
log_line_prefix = '%m %u %d %r %p %a '
log_statement = none
```

> Reemplaza `<versión>` por la versión que tengas instalada, por ejemplo `14`.

Guarda y reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

---

## 🧩 Paso 2: Crear el filtro personalizado para PostgreSQL

Crea el archivo de filtro:

```bash
sudo nano /etc/fail2ban/filter.d/postgresql-auth.conf
```

Agrega el siguiente contenido:

```ini
[Definition]
failregex = ^.* (?P<host>\d+\.\d+\.\d+\.\d+)\(\d+\).*FATAL:  password authentication failed for user .*
ignoreregex =
```

Este filtro detecta líneas como:

```
FATAL:  password authentication failed for user "usuario" host=192.168.1.100
```

---

## 🧩 Paso 3: Crear el jail para PostgreSQL

Edita el archivo `jail.local`:

```bash
sudo nano /etc/fail2ban/jail.local
```

Agrega al final:

```ini
[postgresql-auth]
enabled = true
port     = 5432
filter   = postgresql-auth
logpath  = /var/log/postgresql/postgresql.log
maxretry = 3
findtime = 600
bantime  = 3600
```

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

Y verifica si la IP fue bloqueada:

```bash
sudo iptables -L -n
```


--- 

## ✅ Comando para desbanear una IP

```bash
sudo fail2ban-client set <nombre_del_jail> unbanip <IP>
```

### 🔧 Ejemplo para PostgreSQL:

```bash
sudo fail2ban-client set postgresql-auth unbanip 172.19.0.4
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
sudo fail2ban-regex /var/log/postgresql/postgresql.log /etc/fail2ban/filter.d/postgresql-auth.conf
```

Esto te mostrará si la IP fue detectada correctamente.
