## 🐳 ¿Qué es Docker?

**Docker** es una plataforma que permite crear, ejecutar y administrar aplicaciones dentro de **contenedores**. Un contenedor es una unidad ligera y portátil que incluye todo lo necesario para ejecutar una aplicación: código, librerías, dependencias, configuración, etc.

 
### 🔍 ¿Por qué es útil Docker?

Imagina que tienes una aplicación que funciona perfectamente en tu computadora, pero cuando la pasas a otro servidor, empieza a fallar. Docker resuelve este problema porque **empaqueta la aplicación con todo lo que necesita**, asegurando que se ejecute igual en cualquier entorno.

 
## 🧱 ¿Qué hace Docker?

### 1. **Empaquetar aplicaciones**
- Puedes crear una imagen que contenga tu app y sus dependencias.
- Ejemplo: una imagen con PostgreSQL + configuración personalizada.

### 2. **Ejecutar contenedores**
- Puedes iniciar múltiples instancias de tu app sin conflictos.
- Cada contenedor es aislado, como si fuera una mini máquina virtual.

### 3. **Gestionar entornos**
- Ideal para desarrollo, pruebas, producción.
- Puedes levantar entornos completos con bases de datos, APIs, frontends, etc.

### 4. **Automatizar despliegues**
- Con herramientas como Docker Compose o Kubernetes puedes automatizar el despliegue de sistemas complejos.


## 🧠 **Conceptos clave que debes aprender sobre Docker**

### 1. **Contenedor**
- Es una unidad ligera y portátil que empaqueta una aplicación y sus dependencias.
- Se ejecuta de forma aislada del sistema operativo anfitrión.

### 2. **Imagen**
- Es una plantilla inmutable que define lo que contiene el contenedor (sistema operativo, app, librerías).
- Ejemplo: `postgres:15` es una imagen oficial de PostgreSQL.

### 3. **Dockerfile**
- Archivo de texto con instrucciones para construir una imagen personalizada.

### 4. **Volumen**
- Permite persistir datos fuera del contenedor (ideal para bases de datos).
- Ejemplo: `-v pgdata:/var/lib/postgresql/data`

### 5. **Redes**
- Docker puede crear redes internas para que los contenedores se comuniquen entre sí.

### 6. **Docker Compose**
- Herramienta para definir y correr múltiples contenedores con un solo archivo `docker-compose.yml`.

### 7. **Registry**
- Lugar donde se almacenan imágenes (como Docker Hub o Azure Container Registry). [Link](https://hub.docker.com/)

---

### 🐧 **Instalación en una VM Linux (Ubuntu/Debian)**
1. **Actualizar paquetes:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Instalar dependencias:**
   ```bash
   sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
   ```

3. **Agregar la clave GPG de Docker:**
   ```bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

4. **Agregar el repositorio de Docker:**
   ```bash
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. **Instalar Docker:**
   ```bash
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
   ```

6. **Verificar instalación:**
   ```bash
   sudo systemctl enable docket
   sudo systemctl start docket
   
   sudo docker --version
   sudo compose version
   ```

7. **permiso a tu usuario actual de ejecutar comandos de Docker sin sudo**
   ```bash
   sudo usermod -aG docker $USER

   ############ Desglose del comando:  ############ 
    sudo: Ejecuta el comando con privilegios de administrador.
    usermod: Es la herramienta para modificar usoarios.
    -aG:
    -a (append): Significa "añadir". Es vital porque si lo olvidas, podrías borrar a tu usuario de otros grupos importantes.
    -G (groups): Indica que vas a trabajar con grupos.
   
   
    docker: Es el nombre del grupo al que te quieres unir.
    $USER: Es una variable de entorno que se traduce automáticamente al nombre de tu usuario actual (por ejemplo, "juan" o "admin").

   ```


8. **Conectarse al contenedor**
   ```bash
   docker exec -it nombre-contenedor bash
   ```   


 ⚠️ Nota importante de seguridad 
 Debes saber que estar en el grupo docker es técnicamente equivalente a tener privilegios de root (administrador total). Esto se debe a que un usuario en este grupo puede crear contenedores que tengan acceso a archivos sensibles de tu sistema operativo. Solo dale este permiso a usuarios en los que confíes plenamente.
 
### 🔐 **Recomendaciones de seguridad**
- Usa **Azure Defender for Cloud** para monitorear contenedores.
- Configura **NSG (Network Security Groups)** para limitar el acceso.
- Considera usar **Azure Container Instances** o **AKS (Azure Kubernetes Service)** si planeas escalar.


---


### 🐘 **Levantar PostgreSQL en Docker**

# Descargar la imagen de PostgreSQL
```bash
docker pull postgres
```

#### 1. **Crear un contenedor con PostgreSQL**
Puedes usar el siguiente comando para levantar PostgreSQL rápidamente:

```bash
docker run --name postgres-db \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -e POSTGRES_DB=mi_basedatos \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  -d postgres:15

5432:5432 -> (Derecha): Es la "puerta" interna del contenedor. | (Izquierda): Es la "ventana" que tú abres en tu computadora real para poder entrar
```
 
# Crear contenedor de PostgreSQL temporal  
```
docker run --rm -it \
  # --rm: Borra automáticamente el contenedor al salir para no dejar basura.
  # -it: Abre una terminal interactiva (permite escribir comandos dentro).
  \
  -v ~/docker/pg-replica:/var/lib/postgresql/data \
  # -v: Conecta (mapea) tu carpeta local con la carpeta de datos del contenedor.
  # Esto hace que tus bases de datos sean permanentes en tu PC real.
  \
  -e PGPASSWORD=replica@123 \
  # -e: Define variables de entorno. Aquí estableces la contraseña de la DB.
  \
  postgres:16 \
  # Especifica la imagen oficial de PostgreSQL en su versión 16.
  \
  bash
  # bash: Indica que NO inicie la base de datos, sino que te dé una terminal.
```

#### 🔍 Explicación de parámetros:
- `--name postgres-db`: nombre del contenedor.
- `-e POSTGRES_USER`: usuario administrador.
- `-e POSTGRES_PASSWORD`: contraseña.
- `-e POSTGRES_DB`: nombre de la base de datos inicial.
- `-p 5432:5432`: expone el puerto para conectarte desde fuera del contenedor.
- `-v pgdata:/var/lib/postgresql/data`: Para que los datos no se pierdan al eliminar el contenedor, usa un volumen
- `-d postgres:15`: imagen oficial de PostgreSQL versión 15.

---

### ✅ **Verificar que está corriendo**
```bash
docker ps
```

 

### 🧪 **Probar conexión**
Puedes conectarte desde tu VM con `psql` si lo tienes instalado:

```bash
psql -h localhost -U admin -d mi_basedatos
```

 

### 🔐 **Recomendaciones de seguridad**
- Cambia las credenciales por valores seguros.

---

 
### 1. ¿Qué puedes hacer dentro  de Docker?

Como entras generalmente como usuario **root** (superusuario), tienes el control total del sistema de archivos del contenedor:

* **Instalar herramientas:** Puedes usar el gestor de paquetes del contenedor (ej. `apt update && apt install vim` en Ubuntu/Debian o `apk add` en Alpine).
* **Modificar archivos:** Puedes editar archivos de configuración de la base de datos o del servidor web que esté corriendo.
* **Revisar procesos:** Puedes usar comandos como `top` o `ps` para ver qué está pasando internamente.

### 2. El gran "Pero": La Efimeridad

Esta es la regla de oro de Docker: **Los contenedores son desechables.**

* **Los cambios se pierden:** Si borras el contenedor (`docker rm`) y lo vuelves a crear con `docker run`, **todo lo que instalaste o configuraste mediante `exec` desaparecerá**. El contenedor volverá a estar exactamente como dicta su imagen original.
* **Uso correcto:** Usar `exec` para instalar cosas es excelente para **pruebas rápidas o depuración** (ej. "quiero ver si este comando funciona antes de ponerlo en mi script"). No es la forma correcta de configurar un servidor definitivo.

 

### 3. Diferencias con un Linux "Normal"

| Característica | Linux Normal (PC o VM) | Contenedor (vía `exec`) |
| --- | --- | --- |
| **Persistencia** | Los cambios son permanentes. | Los cambios son temporales (se borran con el contenedor). |
| **Herramientas** | Trae casi todo (vi, curl, ping, etc.). | Es **minimalista**. A veces no trae ni `nano` ni `ping` para ahorrar espacio. |
| **Kernel** | Tiene su propio núcleo. | **Comparte el núcleo** de tu computadora (Host). |
| **Propósito** | Multipropósito. | Generalmente corre **un solo proceso** (ej. solo la base de datos). |

 

### 4. ¿Cómo hacerlo "bien" (Permanente)?

Si descubres que necesitas instalar algo (por ejemplo, `pgmetrics` o `vim`) de forma permanente, no lo hagas con `exec`. Debes modificar el archivo llamado **Dockerfile** de tu proyecto:

> **Ejemplo de un Dockerfile:**
> ```dockerfile
> FROM postgres:15
> # Aquí es donde "instalas" para siempre
> RUN apt-get update && apt-get install -y vim pgmetrics
> 
> ```



### Mala práctica

Aunque funcione, instalar cosas manualmente con `exec` se considera una **mala práctica** en el mundo profesional por dos razones:

1. **No es reproducible:** Si tu compañero quiere el mismo entorno, tú no puedes "pasarle" ese contenedor fácilmente. Él tendría que entrar y volver a instalar todo a mano.
2. **Mantenimiento:** Si mañana quieres actualizar la versión de PostgreSQL, al bajar la nueva imagen y crear el contenedor, tendrás que volver a instalar `pgmetrics`.

### La solución definitiva: El Dockerfile

Si ya probaste que `pgmetrics` te sirve y lo quieres para siempre (incluso si borras el contenedor), lo ideal es ponerlo en el archivo de configuración.

---
 
# 🗄️ Persistencia de Datos en PostgreSQL con Docker

Por defecto, los contenedores de Docker son **efímeros**. Si detienes un contenedor, tus datos permanecen; sin embargo, si **eliminas** el contenedor, corres el riesgo de perder toda la información de tu base de datos.

Para solucionar esto, es fundamental utilizar **Volúmenes** para asegurar la persistencia. Existen dos métodos principales para manejar esto:


## 1. Guardar datos en un Volumen de Docker (Recomendado)

Docker administra el área de almacenamiento dentro del sistema de archivos del host, protegiéndola de interferencias externas.

###  Implementación

Primero, asegúrate de que no haya contenedores en conflicto:

```bash
# Detener y eliminar el contenedor actual
docker stop postgres
docker rm postgres

```

Crea un volumen dedicado y ejecuta el contenedor:

```bash
# Crear un nuevo Volumen de Docker
docker volume create pgdata

# Ejecutar el contenedor con el volumen conectado
docker run -d \
  -p 5432:5432 \
  --name postgres \
  -e POSTGRES_PASSWORD=$USER_PASSWORD \
  -v pgdata:/var/lib/postgresql/data \
  postgres 

```


## 2. Guardar datos en tu Máquina Local (Bind Mount)

Este método mapea los datos de la base de datos directamente a una carpeta específica en tu máquina host. Es ideal para desarrollo cuando necesitas inspeccionar archivos manualmente.

###  Implementación

Crea un directorio local y vincúlalo al contenedor:

```bash
# Crear un directorio en el Host
mkdir pgdata

# Ejecutar el contenedor vinculado al directorio local
docker run -d \
  -p 5432:5432 \
  --name postgres \
  -e POSTGRES_PASSWORD=$USER_PASSWORD \
  -v ~/pgdata:/var/lib/postgresql/data \
  postgres

```


## La duda más común: ¿Dónde están los datos?

La respuesta corta es: **los datos están FUERA del contenedor**, pero en un área que Docker "esconde" para protegerla.

### 1. ¿Dentro o fuera del contenedor?

Están **FUERA**. Incluso en el **Método 1 (Volúmenes)**, los datos viven en el disco duro de tu computadora real. La diferencia es que, mientras en el **Método 2** tú eliges la carpeta, en el **Método 1** Docker la elige por ti en un lugar reservado.

### 2. Ubicación física según el Sistema Operativo:

* **En Linux Nativo:** Los datos están en `/var/lib/docker/volumes/nombre_del_volumen/_data`. Necesitas permisos de administrador (`sudo`) para entrar.
* **En Windows o Mac (Docker Desktop):** Docker corre dentro de una pequeña máquina virtual ligera. Los datos están **dentro de esa máquina virtual**, por lo que no los verás directamente en tu explorador de archivos normal.

### 3. ¿Cómo revisar los datos? (3 Formas)

Como no siempre puedes abrir una carpeta y ya, usa estas formas oficiales:

#### A. La forma técnica (Inspeccionar)

Para saber la ruta y detalles técnicos:

```bash
docker volume inspect pgdata

```

#### B. La forma práctica (Contenedor Explorador)

Lanza un contenedor ligero para ver el contenido sin afectar nada:

```bash
docker run --rm -it -v pgdata:/mirar alpine ls -l /mirar

```

#### C. Entrar al contenedor de PostgreSQL

Si el contenedor está corriendo, navega directamente a la ruta interna:

```bash
docker exec -it postgres ls -l /var/lib/postgresql/data

```
 
##  Comparativa: ¿Cuál usar?

| Característica | Método 1: Volumen de Docker | Método 2: Carpeta Local |
| --- | --- | --- |
| **Gestión** | Administrado por Docker | Administrado por el Usuario |
| **Ubicación** | Oculta (Ruta interna de Docker) | Visible (Ruta elegida por ti) |
| **Rendimiento** | Optimizado para BD | Depende del sistema de archivos |
| **Ideal para...** | Servidores reales y producción | Programación y respaldos rápidos |

 

---




# Asignación de recursos

### 1. ¿Cómo se asignan los recursos?

Esta es una de las preguntas más importantes para llevar Docker a producción. Por defecto, **un contenedor no tiene límites de recursos**: puede consumir toda la memoria RAM y todo el CPU que el sistema operativo le permita, lo cual es peligroso porque un error en la base de datos podría "congelar" todo tu servidor.

Los recursos se asignan en la **capa de ejecución** (Docker Run o Docker Compose), no dentro del Dockerfile.
 

Tienes dos formas principales de hacerlo, dependiendo de cómo estés levantando tu contenedor.

#### A. Usando `docker run` (Línea de comandos)

Si lanzas el contenedor manualmente, usas banderas específicas:

* **Memoria:** `--memory="2g"` (Límite máximo de 2GB).
* **CPU:** `--cpus="1.5"` (Le permite usar el equivalente a un núcleo y medio de tu procesador).

#### B. Usando `docker-compose.yml` (Recomendado)

Es mucho más ordenado porque queda documentado en el archivo. Se utiliza la sección `deploy`.



### 2. Ejemplo Completo: Configuración de Recursos

Aquí tienes cómo se vería tu archivo de servicios con límites de hardware. Es vital que el límite de Docker sea **siempre mayor** a lo que configuraste en tu `shared_buffers`.

```yaml
services:
  db-personalizada:
    image: mi-postgres-optimizada:v1
    container_name: postgres-prod
    environment:
      POSTGRES_PASSWORD: password123
    
    #  ASIGNACIÓN DE RECURSOS 
    deploy:
      resources:
        limits:
          cpus: '2.0'        # Máximo 2 núcleos de CPU
          memory: 2048M      # Máximo 2GB de RAM (Hard Limit)
        reservations:
          cpus: '0.5'        # Reserva mínima de medio núcleo
          memory: 1024M      # Reserva mínima de 1GB de RAM (Soft Limit)
    
    ports:
      - "6432:5432"
    volumes:
      - pgdata_prod:/var/lib/postgresql/data

volumes:
  pgdata_prod:

```



### 3. Conceptos Clave: Limits vs. Reservations

Para entender bien qué estás configurando, debes diferenciar estos dos términos:

| Término | Significado | ¿Qué pasa si se supera? |
| --- | --- | --- |
| **Limits (Límites)** | Es el techo máximo. El contenedor no puede pasar de ahí. | Si Postgres intenta usar más RAM de la permitida, Docker lo "mata" (Error OOM Killer). |
| **Reservations (Reservas)** | Es lo que Docker garantiza que el contenedor tendrá siempre disponible. | Si el sistema tiene poca RAM, Docker priorizará darle este mínimo a tu base de datos. |



### 4. La relación CRÍTICA con `postgresql.conf`

Aquí es donde muchos cometen errores. Hay una jerarquía que debes respetar:

1. **RAM Total del Servidor:** (Ejemplo: 8GB)
2. **Límite de Docker (`limits.memory`):** Debe ser menor a la RAM del servidor (Ejemplo: 4GB).
3. **Configuración de Postgres (`shared_buffers`):** Debe ser menor al límite de Docker (Ejemplo: 1GB).

> **Peligro:** Si en tu `custom-postgres.conf` pusiste `shared_buffers = 2GB`, pero en tu Docker Compose pusiste un límite de `memory: 1GB`, el contenedor **nunca va a arrancar** o se cerrará inmediatamente porque Postgres intentará pedir memoria que Docker le tiene prohibida.



### 5. ¿Cómo verificar si se están respetando los límites?

Una vez que tu contenedor esté corriendo, puedes ver en tiempo real cuánto CPU y RAM está consumiendo con este comando:

```bash
docker stats

```

Este comando te mostrará una tabla con el porcentaje de uso de CPU, la memoria usada vs el límite asignado y el uso de red.

**¿Quieres que te ayude a calcular los valores ideales de CPU y RAM para tu servidor actual basándonos en cuánta memoria total tienes disponible?** Solo dime cuánta RAM tiene tu máquina.

---

# Comandos mas usados 
```bash
### 🔹 Gestión de imágenes

   docker pull <imagen> 		→ Descarga una imagen desde Docker Hub.
   docker build -t <nombre>:<tag>  		→ Construye una imagen desde un Dockerfile.
   docker images 		→ Lista todas las imágenes locales.
   docker rmi <imagen> 		→ Elimina una imagen.
	


### 🔹 Gestión de contenedores

   docker run -d --name <nombre> <imagen> 		→ Crea y ejecuta un contenedor en segundo plano.
   docker ps 		→ Lista contenedores en ejecución.
   docker ps -a 		→ Lista todos los contenedores (incluyendo detenidos).
   docker stop <contenedor> 		→ Detiene un contenedor.
   docker start <contenedor> 		→ Inicia un contenedor detenido.
   docker restart <contenedor> 		→ Reinicia un contenedor.
   docker rm <contenedor> 		→ Elimina un contenedor.



### 🔹 Acceso y ejecución dentro del contenedor

   docker exec -it <contenedor> bash 		→ Accede a la terminal del contenedor.
   docker exec <contenedor> <comando> 		→ Ejecuta un comando dentro del contenedor.
   docker attach <contenedor> 		→ Se conecta a la sesión principal del contenedor.



### 🔹 Logs y monitoreo

   docker logs <contenedor> 		→ Muestra los logs del contenedor.
   docker stats 		→ Muestra estadísticas de uso (CPU, memoria, etc.).
   docker inspect <contenedor> 		→ Información detallada del contenedor.



### 🔹 Volúmenes y redes

   docker volume ls 		→ Lista volúmenes.
   docker network ls 		→ Lista redes.
   docker network create <nombre> 		→ Crea una red personalizada.


### 🔹 Otros útiles

   docker cp <origen> <contenedor>:<ruta> 		→ Copia archivos al contenedor.
   docker commit <contenedor> <imagen> 		→ Crea una imagen desde un contenedor modificado.
   docker system prune 		→ Limpia recursos no usados (contenedores, imágenes, redes).

 

```


# Links 
```sql

------------ Docker -------------
https://github.com/pglayers/pglayers

-------------------- POSTGRESQL BACKUP --------------------
pgBackRest PITR in Docker -> https://dataegret.com/2025/12/pgbackrest-pitr-in-docker-a-simple-demo/

-------------------- POSTGRESQL HA DOCKER --------------------
Running PostgreSQL in Docker Container with Volume -> https://medium.com/@basit26374/how-to-run-postgresql-in-docker-container-with-volume-bound-c141f94e4c5a
Initializing a PostgreSQL Database with a Dataset using Docker Compose: A Step-by-step Guide -> https://medium.com/@asuarezaceves/initializing-a-postgresql-database-with-a-dataset-using-docker-compose-a-step-by-step-guide-3feebd5b1545
Building a PostgreSQL Replication Cluster with Docker Compose -> https://sadeesha.medium.com/building-a-postgresql-replication-cluster-with-docker-compose-45406078de72

-------------------- REPMGR DOCKER --------------------
PostgreSQL High Availability and automatic failover using repmgr -> https://medium.com/@joao_o/postgresql-high-availability-and-automatic-failover-using-repmgr-5f505dc6913a

-------------------- PATRONI DOCKER --------------------
https://medium.com/@exclusivetech.ch/setting-up-an-etcd-patroni-postgresql-and-haproxy-cluster-0ed2d55160ec
https://medium.com/@nicola.vitaly/setting-up-high-availability-postgresql-cluster-using-patroni-pgbouncer-docker-consul-and-95c70445b1b1

-------------------- PGBOUNCER DOCKER --------------------
Setup Docker Compose for Postgres and PgBouncer -> https://muhammadtriwibowo.medium.com/install-docker-compose-postgres-and-pgbouncer-8fa2c337a0e3
Connection Pooling for Postgres using PG Bouncer -> https://medium.com/@pablo.lopez.santori/connection-pooling-for-postgres-using-pg-bouncer-175bc1607db2
PgBouncer in 15 Minutes: Kill Idle Connections, Boost Throughput -> https://medium.com/@rohansodha10/pgbouncer-in-15-minutes-kill-idle-connections-boost-throughput-a6220218648f

-------------------- PGPOOL 2 DOCKER --------------------
https://medium.com/@tirthraj2004/introduction-to-database-clustering-using-postgresql-docker-and-pgpool-ii-ac2a7bf96a5f


-------------------- EXAMPLES DOCKER --------------------
https://medium.com/@okpo65/mastering-postgresql-with-docker-a-step-by-step-tutorial-caef03ab6ae9
https://medium.com/@jp_79222/postgresql-y-docker-en-un-ambiente-de-desarrollo-local-d04ff1ab7271
https://medium.com/@tantrum5535/c%C3%B3mo-crear-un-backup-en-postgresql-dentro-de-un-contenedor-docker-13031f1767dd
https://medium.com/@danieldspx/how-to-speed-up-postgresql-development-docker-and-meson-step-by-step-guide-5756ad718aaa
https://medium.com/norsys-octogone/a-local-environment-for-postgresql-with-docker-compose-7ae68c998068
https://medium.com/@maheshshelke/setting-up-postgresql-server-in-docker-container-on-ubuntu-a-step-by-step-guide-f21f8973d6d7
https://medium.com/@marvinjungre/get-postgresql-and-pgadmin-4-up-and-running-with-docker-4a8d81048aea
https://medium.com/@gerbasi.magali/introduccion-a-docker-y-docker-compose-1ff0219269e8
https://pankajconnect.medium.com/introduction-to-postgresql-and-docker-a-comprehensive-guide-4c4c0082f9c8
https://medium.com/@jesusgilberdugo/docker-postgresql-dbeaver-cb77e1f3167c
https://medium.com/@agusmahari/docker-how-to-install-postgresql-using-docker-compose-d646c793f216
https://medium.com/@analyticscodeexplained/why-run-postgresql-in-docker-containers-4dd0c2186d08
https://medium.com/@mateus2050/setting-up-postgresql-and-pgadmin-using-docker-on-macos-66cd7d275328
https://medium.com/@yahyaali.se/setting-up-postgres-with-docker-desktop-9e4c2e77cd7c
https://dextrop.medium.com/setting-up-postgresql-on-docker-43905c8a4d13
https://medium.com/@maxhoustonramirezmartel/c%C3%B3mo-usar-postgres-con-docker-3dae8042ee45
https://brokenrice.medium.com/how-to-run-postgres-in-docker-a9ec0192a44c


-- Instalar Docker 
https://medium.com/@piyushkashyap045/comprehensive-guide-installing-docker-and-docker-compose-on-windows-linux-and-macos-a022cf82ac0b
https://medium.com/@manuel.vega.ulloa/c%C3%B3mo-instalar-y-usar-docker-en-ubuntu-22-04-5-lts-60b773efbd10
https://medium.com/devops-technical-notes-and-manuals/how-to-install-docker-on-ubuntu-22-04-b771fe57f3d2

--- Instalar PSQL en Docket
https://medium.com/@jwang.ml/deploy-postgresql-with-docker-and-perform-crud-operations-using-python-57995e7a71e8
https://bennobuilder.medium.com/connect-to-postgresql-database-inside-docker-container-7dab32435b49


-- Seguridad
https://pankajconnect.medium.com/container-security-tips-for-securing-postgresql-instances-in-docker-9de5d2a932fb
https://blog.devops.dev/postgresql-with-docker-from-setup-to-data-ingestion-and-pgadmin-integration-929c966cc650
https://medium.com/@danieldspx/how-to-speed-up-postgresql-development-docker-and-meson-step-by-step-guide-5756ad718aaa


```
