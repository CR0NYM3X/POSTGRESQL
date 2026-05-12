
#  Herramientas de Administración por Proveedor de DBMS

## 1. PostgreSQL

* **pgAdmin 4 (Web/Escritorio):** La herramienta de la comunidad. Puede ejecutarse como ventana o en el navegador.
* [Descargar aquí](https://www.pgadmin.org/download/)


* **psql (Terminal):** La herramienta interactiva de consola que viene instalada con el motor.
* **PostgreSQL extension para VS Code:** Muy popular para desarrollo rápido.
* [Ver en Marketplace](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres)

 

## 2. MySQL

Es el motor con más opciones oficiales debido a su integración con Oracle.

* **MySQL Workbench (Escritorio):** La herramienta visual estándar.
* [Descargar aquí](https://dev.mysql.com/downloads/workbench/)


* **phpMyAdmin (Web):** El clásico para servidores web (LAMP/WAMP). Es un software de terceros pero adoptado como estándar de facto.
* [Descargar aquí](https://www.phpmyadmin.net/downloads/)


* **MySQL Shell (Terminal Avanzada):** Para entusiastas de la línea de comandos con soporte para JS, Python y SQL.
* [Descargar aquí](https://dev.mysql.com/downloads/shell/)





## 3. MariaDB

Aunque nació de MySQL, ha ido separando sus herramientas oficiales.

* **HeidiSQL (Escritorio):** Como te mencioné, es su compañero oficial en Windows.
* [Descargar aquí](https://www.heidisql.com/download.php)


* **MariaDB SkySQL (Cloud/Web):** Su interfaz para gestión en la nube.
* [Acceder aquí](https://mariadb.com/products/skysql/)


* **Adminer (Web):** Una alternativa a phpMyAdmin mucho más ligera (un solo archivo PHP).
* [Descargar aquí](https://www.adminer.org/)






## 4. Microsoft SQL Server

Microsoft tiene herramientas para cada perfil de usuario.

* **SQL Server Management Studio - SSMS (Escritorio - Pro):** Para administración total.
* [Descargar aquí](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)


* **Azure Data Studio (Ligero/Moderno):** Multiplataforma (Win, Mac, Linux) y basado en VS Code.
* [Descargar aquí](https://www.google.com/search?q=https://learn.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio)


* **mssql extension para VS Code:** Si ya usas Visual Studio Code, esta es la forma más rápida de consultar.
* [Ver en Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql)


## 5. Oracle Database

Herramientas muy robustas orientadas a grandes corporativos.

* **Oracle SQL Developer (Escritorio):** El IDE completo para PL/SQL.
* [Descargar aquí](https://www.oracle.com/database/sqldeveloper/technologies/download/)


* **SQL Developer Web (Database Actions):** Interfaz web que ya viene incluida en las bases de datos autónomas de Oracle.
* **Oracle SQLcl (Terminal):** Una interfaz de línea de comandos moderna con autocompletado.
* [Descargar aquí](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/)


## 6. MongoDB

Al ser NoSQL, sus herramientas están enfocadas en visualizar documentos JSON.

* **MongoDB Compass (Escritorio):** La interfaz visual oficial.
* [Descargar aquí](https://www.mongodb.com/try/download/compass)


* **Mongosh (MongoDB Shell):** La nueva terminal moderna para consultas rápidas.
* [Descargar aquí](https://www.mongodb.com/try/download/shell)


* **Atlas Data Explorer (Web):** Si usas su servicio en la nube (Atlas), esta es la interfaz web por defecto.



### Resumen Rápido

| Base de Datos | Herramienta Oficial / Propia | Dificultad |
| --- | --- | --- |
| **MySQL** | MySQL Workbench | Media |
| **MariaDB** | HeidiSQL | Fácil |
| **Oracle** | SQL Developer | Alta (Experto) |
| **SQL Server** | SSMS / Azure Data Studio | Media |
| **PostgreSQL** | pgAdmin 4 | Media |
| **MongoDB** | MongoDB Compass | Muy Fácil |


### Tabla de uso según tu entorno

| Si estás en... | Usa esta herramienta | Razón |
| --- | --- | --- |
| **Windows (Intranet)** | **HeidiSQL / SSMS** | Son nativos y traen casi todo listo. |
| **Navegador Web** | **phpMyAdmin / Adminer** | No instalas nada en tu PC. |
| **Visual Studio Code** | **Extensiones oficiales** | No sales de tu editor de código. |
| **Servidor Linux** | **psql / mysql shell** | Máxima velocidad por terminal. |

**Un detalle importante:** En tu intranet, si descargas **SQL Developer (Oracle)** o **DBeaver**, recuerda que ambos son "Java-based" y podrías necesitar instalar el **JRE** (Java Runtime Environment) si tu PC no lo tiene. Los demás (.exe) suelen ser autónomos.




---

#  Herramientas de Administración Multi-Plataforma DBMS 
 

### 1. DBeaver (Universal / Open Source)

Es la herramienta más completa. Al ser "Community Edition", permite conectar casi cualquier base de datos mediante archivos JDBC (.jar).

* **Descarga de DBeaver:**
* [Versión Portable (ZIP)](https://dbeaver.io/files/dbeaver-ce-latest-windows-x86_64.zip) (Ideal para la intranet porque no requiere instalación).
* [Página General de Descargas](https://dbeaver.io/download/)


* **Drivers JDBC (Necesarios para tu Intranet):**
* **PostgreSQL:** [postgresql-42.7.2.jar](https://jdbc.postgresql.org/download/)
* **SQL Server:** [mssql-jdbc-12.4.2.jre11.jar](https://github.com/microsoft/mssql-jdbc/releases)
* **Oracle:** [ojdbc11.jar](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html)
* **MySQL:** [mysql-connector-j-8.3.0.jar](https://dev.mysql.com/downloads/connector/j/) (Seleccionar *Platform Independent*).
* **MariaDB:** [mariadb-java-client-3.3.3.jar](https://mariadb.com/downloads/connectors/) (Seleccionar *Java 8+ Connect* / *Platform Independent*).


 
### 2. DataGrip (Profesional / Paga)

Desarrollado por JetBrains. Es probablemente el analizador más inteligente del mercado en cuanto a autocompletado y refactorización de código SQL.

* **Soporta:** Prácticamente todos los motores relacionales y NoSQL.
* **Descarga:** [JetBrains DataGrip](https://www.jetbrains.com/datagrip/download/)

### 3. TablePlus (Ligero / Nativo)

Es extremadamente rápido y consume muy pocos recursos. Su interfaz es la más limpia y moderna.

* **Soporta:** MySQL, PostgreSQL, SQLite, Microsoft SQL Server, Redis, Cassandra, entre otros.
* **Descarga:** [TablePlus Download](https://tableplus.com/download)

### 4. SQuirreL SQL (Clásico / Java)

Un veterano del mundo Open Source. Al igual que DBeaver, está basado en Java y usa drivers JDBC. Es muy común verlo en entornos de servidores antiguos.

* **Soporta:** Cualquier base de datos con driver JDBC.
* **Descarga:** [SQuirreL SQL Client](https://www.google.com/search?q=http://squirrel-sql.sourceforge.net/%23installation)

### 5. Beekeeper Studio (Moderno / Open Source)

Un analizador de consultas muy intuitivo y con un diseño "dark mode" muy cuidado. Se enfoca en la facilidad de uso.

* **Soporta:** MySQL, Postgres, SQLite, SQL Server, CockroachDB.
* **Descarga:** [Beekeeper Studio](https://www.beekeeperstudio.io/get)

### 6. DbGate (Versátil)

Es un cliente de base de datos multiplataforma que funciona tanto como aplicación de escritorio como en el navegador (vía Docker).

* **Soporta:** SQL y NoSQL (MongoDB, Redis).
* **Descarga:** [DbGate Download](https://dbgate.org/download/)



