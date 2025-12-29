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

----------------------------------------------------------------------------------------

# Ejecutar un nuevo contenedor de PostgreSQL para tareas de mantenimiento
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
https://medium.com/@basit26374/how-to-run-postgresql-in-docker-container-with-volume-bound-c141f94e4c5a
https://medium.com/@yahyaali.se/setting-up-postgres-with-docker-desktop-9e4c2e77cd7c
https://dextrop.medium.com/setting-up-postgresql-on-docker-43905c8a4d13
https://medium.com/@asuarezaceves/initializing-a-postgresql-database-with-a-dataset-using-docker-compose-a-step-by-step-guide-3feebd5b1545
https://medium.com/@maxhoustonramirezmartel/c%C3%B3mo-usar-postgres-con-docker-3dae8042ee45
https://sadeesha.medium.com/building-a-postgresql-replication-cluster-with-docker-compose-45406078de72
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
