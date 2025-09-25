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
   sudo apt install docker-ce docker-ce-cli containerd.io -y
   ```

6. **Verificar instalación:**
   ```bash
   sudo docker --version
   ```

 
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
```

#### 🔍 Explicación de parámetros:
- `--name postgres-db`: nombre del contenedor.
- `-e POSTGRES_USER`: usuario administrador.
- `-e POSTGRES_PASSWORD`: contraseña.
- `-e POSTGRES_DB`: nombre de la base de datos inicial.
- `-p 5432:5432`: expone el puerto para conectarte desde fuera del contenedor.
- `-v pgdata:/var/lib/postgresql/data`: volumen persistente para los datos.
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

# Links 
```sql

-- Instalar Docker 
https://medium.com/@piyushkashyap045/comprehensive-guide-installing-docker-and-docker-compose-on-windows-linux-and-macos-a022cf82ac0b
https://medium.com/@manuel.vega.ulloa/c%C3%B3mo-instalar-y-usar-docker-en-ubuntu-22-04-5-lts-60b773efbd10
https://medium.com/devops-technical-notes-and-manuals/how-to-install-docker-on-ubuntu-22-04-b771fe57f3d2

--- Instalar PSQL en Docket
https://medium.com/@okpo65/mastering-postgresql-with-docker-a-step-by-step-tutorial-caef03ab6ae9
https://medium.com/@jwang.ml/deploy-postgresql-with-docker-and-perform-crud-operations-using-python-57995e7a71e8
https://medium.com/norsys-octogone/a-local-environment-for-postgresql-with-docker-compose-7ae68c998068
https://medium.com/@maheshshelke/setting-up-postgresql-server-in-docker-container-on-ubuntu-a-step-by-step-guide-f21f8973d6d7
https://pankajconnect.medium.com/introduction-to-postgresql-and-docker-a-comprehensive-guide-4c4c0082f9c8
https://bennobuilder.medium.com/connect-to-postgresql-database-inside-docker-container-7dab32435b49


-- Seguridad
https://pankajconnect.medium.com/container-security-tips-for-securing-postgresql-instances-in-docker-9de5d2a932fb
https://blog.devops.dev/postgresql-with-docker-from-setup-to-data-ingestion-and-pgadmin-integration-929c966cc650
https://medium.com/@danieldspx/how-to-speed-up-postgresql-development-docker-and-meson-step-by-step-guide-5756ad718aaa


```
