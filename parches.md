
# parches y ciclos de vida

```SQL													
CATÁLOGO DE PARCHES POSTGRESQL		https://www.postgresql.org/													
CATÁLOGO DE PARCHES MSSQL	 	https://www.catalog.update.microsoft.com/search.aspx?q=sql+server													
CATÁLOGO DE PARCHES MONGODB	 	https://www.mongodb.com/docs/upcoming/release-notes/6.0/													
CATÁLOGO DE PARCHES DB2	 	https://www.ibm.com/support/pages/download-db2-fix-packs-version-db2-linux-unix-and-windows													
CATÁLOGO DE PARCHES MARIADB		https://mariadb.com/kb/en/release-notes/													
CATÁLOGO DE PARCHES VOLTDB	 	https://docs.voltdb.com/													
CATÁLOGO DE PARCHES ORACLE	 	https://support.oracle.com/knowledge/Oracle%20Database%20Products/742060_1.html													
CATÁLOGO DE PARCHES MYSQL		https://dev.mysql.com/doc/relnotes/													

LIFE CYCLES POSTGRESQL 		https://www.postgresql.org/support/versioning/						  |  Cuando se lanzaran los nuevos parches  ->  https://www.postgresql.org/developer/roadmap/							
LIFE CYCLES MSSQL		https://learn.microsoft.com/en-us/sql/sql-server/end-of-support/sql-server-end-of-support-overview?view=sql-server-ver16													
LIFE CYCLES MONGODB		https://www.mongodb.com/support-policy/lifecycles													
LIFE CYCLES DB2		https://www.ibm.com/support/pages/db2-distributed-end-support-eos-dates													
LIFE CYCLES MARIADB		https://mariadb.org/about/													
LIFE CYCLES VOLTDB		https://www.voltactivedata.com/company/customers/support/													
LIFE CYCLES ORACLE		https://www.oracle.com/us/assets/lifetime-support-technology-069183.pdf													
LIFE CYCLES MYSQL		https://endoflife.software/applications/databases/mysql

```


# Notas de cada version 
El link te muestra los cambios realizados de cada version y si ocupa alguna restauración 
```
15.1
[version mayor].[Version menor]

/*
Antes de actualizar es importante validar la nota de la version, ya que te dice los cambios realizados y te puede dar advertencias como por ejemplo que antes de actualizar necesitas restaurar

---> Este te dice que no necesitas hacer un dump y restauracion, ya que solo contiene correcciones 
This release contains a variety of fixes from 15.0. 
A dump/restore is not required for those running 14.X.

--> En cambio este te advierte que necesitas hacer un dump y restaurar ya que esta version tiene cambios que pueden afectar 
A dump/restore using pg_dumpall or use of pg_upgrade
Version 14 contains a number of changes that may affect compatibility with previous releases. 

*/

-- Todas las versiones 
https://www.postgresql.org/docs/release/

-- Ver funcionalidades que tiene cada version
https://www.postgresql.org/about/featurematrix/
```

# Descargar postgresql y sus packetes 
```
 --------->  DESCARGAR POSTGRESQL REDHAT <--------------
https://www.postgresql.org/download/linux/redhat/

..... REPOSITORIO PARA DESCARGAR PARCHES .......
https://apt.postgresql.org/pub/repos/
https://download.postgresql.org/pub/repos/
https://ftp.postgresql.org/pub/repos/

## Codigo fuente 
https://ftp.postgresql.org/pub/source/

https://www.postgresql.org/ftp/source/

..................... Paquetes necesarios para que funcione .................

 
1. **postgresql16-16.6-1PGDG.rhel8.x86_64**: Este paquete contiene los binarios y bibliotecas del cliente de PostgreSQL - PostgreSQL] . Es necesario para conectarse y ejecutar consultas en una base de datos PostgreSQL - PostgreSQL] 

2. **postgresql16-server-16.6-1PGDG.rhel8.x86_64**: Este paquete incluye el servidor de base de datos principal de PostgreSQL - PostgreSQL]( . Es el paquete principal que instala y configura el servidor de PostgreSQL en tu sistema - PostgreSQL] 

3. **postgresql16-contrib-16.6-1PGDG.rhel8.x86_64**: Este paquete contiene extensiones y módulos adicionales que no están incluidos en el paquete principal. Estas contribuciones pueden añadir funcionalidades adicionales a tu base de datos PostgreSQL.

4. **postgresql16-devel-16.6-1PGDG.rhel8.x86_64**: Este paquete incluye las bibliotecas y encabezados necesarios para el desarrollo de aplicaciones en C que utilizan PostgreSQL - PostgreSQL]. Es útil para los desarrolladores que quieren crear aplicaciones que interactúen con PostgreSQL.

5. **postgresql16-libs-16.6-1PGDG.rhel8.x86_64**: Este paquete contiene las bibliotecas compartidas necesarias para ejecutar aplicaciones que utilizan PostgreSQL - PostgreSQL]. Estas bibliotecas son requeridas por las aplicaciones que dependen de PostgreSQL.
 
6. **postgresql16-llvmjit-15.6-1PGDG.rhel8.x86_64.rpm:** Este paquete contiene el soporte para JIT (Just-In-Time) compilación en PostgreSQL utilizando LLVM. La compilación JIT puede mejorar significativamente el rendimiento de ciertas consultas intensivas, como aquellas que implican muchas operaciones de cálculo o de procesamiento de datos.
   - **Beneficio:** La compilación JIT permite que partes del código de ejecución de consultas SQL sean compiladas en tiempo real, optimizando y acelerando la ejecución.

7. **postgresql16-odbc-16.00.0000-1PGDG.rhel8.x86_64:** Este paquete proporciona el controlador ODBC (Open Database Connectivity) para PostgreSQL. ODBC es una API estándar para acceder a bases de datos que permite a las aplicaciones conectarse a PostgreSQL de manera interoperable.
   - **Beneficio:** El controlador ODBC permite que diversas aplicaciones y herramientas que utilizan ODBC se conecten y trabajen con bases de datos PostgreSQL, facilitando la integración con software de terceros.
 
```

# ODBC
```
https://odbc.postgresql.org/
```

### archivo RPM para agregar el repositorio de PostgreSQL a tu sistema Red Hat o CentOS.
 Este repositorio contiene paquetes de PostgreSQL y sus componentes, permitiéndote instalar y actualizar PostgreSQL fácilmente usando `yum` o `dnf`.

Al instalar este archivo RPM, se configura tu sistema para acceder al repositorio de PostgreSQL, lo que facilita la instalación de diferentes versiones de PostgreSQL y sus herramientas asociadas. Aquí tienes cómo puedes usarlo:

1. **Descargar e instalar el archivo RPM del repositorio**:
   ```bash
   sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
   ```

2. **Deshabilitar el módulo PostgreSQL predeterminado (si es necesario)**:
   ```bash
   sudo dnf -qy module disable postgresql
   ```
 


#   Vulnerabilidades de seguridad 
```
-- Saber porque ocupas parchar 
https://why-upgrade.depesz.com/show?from=18&to=18.1&keywords=cve

https://endoflife.date/postgresql
https://www.percona.com/blog/postgresql-13-is-reaching-end-of-life-the-time-to-upgrade-is-now/



########## Common Vulnerabilities and Exposures (CVE) ###########

https://www.postgresql.org/support/security/


https://access.redhat.com/security/security-updates/cve?q=postgres&p=1&sort=cve_publicDate+desc,allTitle+desc&rows=10&documentKind=Cve

https://www.cvedetails.com/vendor/336/
https://www.cvedetails.com/vulnerability-list/vendor_id-336/product_id-575/Postgresql-Postgresql.html

https://www.cve.org/CVERecord/SearchResults?query=postgresql
https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=postgresql


https://nvd.nist.gov/vuln/search/results?form_type=Basic&results_type=overview&query=postgres&search_type=all&isCpeNameSearch=false

https://www.rapid7.com/db/?q=postgres&type=
https://vuldb.com/?search

https://www.enterprisedb.com/docs/security/assessments/

https://www.exploit-db.com/
https://0day.today/

```

#  eXTRA 
```
https://git.postgresql.org/gitweb/
https://git.postgresql.org/cgit
https://www.postgresql.org/docs/devel/installation.html
```


---

Ver los paquetes

```

-- version de S.O
cat /etc/os-release
cat /etc/redhat-release
hostnamectl
uname -r

-- Revisa tu versión exacta de RPM
rpm -q openssl

-- Interroga el registro de cambios (Changelog)
rpm -q --changelog openssl | grep -i "CVE-AÑO-NUMERO"

-- Si tu servidor o tu repositorio interno, ya sincronizó los paquetes de Red Hat pero tú aún no los instalas,
-- puedes preguntarle a tu sistema cuál es el último paquete disponible esperando ser instalado usando:
dnf info openssl --available


-- ver todas las versiones que tu repositorio conoce (tanto la instalada como las disponibles para actualizar)
dnf --showduplicates list openssl


-- Aquí puedes buscar el CVE exacto y ver cómo afecta 
access.redhat.com/security/security-updates/cve

-- Aquí publican las versiones exactas de los RPM que corrigen los fallosclear
access.redhat.com/errata

```





---



 
# 📐 Guía Universal de Versionado Semántico (SemVer)

Es vital entender este estándar para que todo nuestro código, documentación y etiquetas de Git en **DBA SQUAD: VANGUARD BLACK-OPS** se mantengan impecables ante cualquier auditoría internacional.

El sistema que utilizamos se llama **Versionado Semántico (Semantic Versioning o SemVer)**. Se estructura oficialmente bajo la nomenclatura:

$$\text{\textbf{MAJOR . MINOR . PATCH}}$$

---

### 1. ESTRUCTURA Y REGLAS DEL VERSIONADO

```
                      MAJOR . MINOR . PATCH
                        │       │       │
                        │       │       └── 3. Correcciones de bugs y parches (Sin romper nada).
                        │       └────────── 2. Nuevas características (Compatibles hacia atrás).
                        └────────────────── 1. Cambios rompedores (Incompatibles hacia atrás).

```

---

#### 🟢 **PATCH (El tercer número — Ej: 1.0.0 ➔ 1.0.1)**

* **Nombre:** *Patch / Corrección / Parche de Mantenimiento.*
* **Cuándo se aumenta:** Cuando realizas correcciones de errores (*bug fixes*), parches de seguridad menores, optimizaciones internas de rendimiento o refactorizaciones internas que **NO alteran la forma en que el usuario o la aplicación interactúan con el sistema**.
* **Regla de Oro:** Es 100% compatible hacia atrás. Las aplicaciones cliente o scripts automáticos no necesitan modificar una sola línea de código para seguir funcionando.
* **Frecuencia:** Alta (días o semanas).
* **Ejemplos Generales:**
* Corregir una condición de búsqueda (`WHERE`) en una consulta interna que devolvía un conteo incorrecto.
* Cambiar los mensajes de error o logs internos de un idioma a otro (ej. mensajes en consola o archivos de registro).
* Optimizar el rendimiento de un algoritmo interno sin modificar sus parámetros de entrada ni los tipos de datos que devuelve.
* Renombrar una variable local interna dentro de una función o código procedural.



---

#### 🟡 **MINOR (El segundo número — Ej: 1.0.0 ➔ 1.1.0)**

* **Nombre:** *Minor / Versión Menor / Nueva Funcionalidad.*
* **Cuándo se aumenta:** Cuando agregas **nuevas funcionalidades, nuevos parámetros opcionales** o nuevas capacidades a un sistema, **PERO mantienes la compatibilidad total con lo que ya existía**.
* **Regla de Oro:** Todo el código o scripts antiguos siguen funcionando sin errores (retrocompatibilidad intacta), pero el sistema ahora ofrece nuevas capacidades si el usuario decide utilizarlas. Al incrementar MINOR, el número de PATCH se reinicia a cero.
* **Frecuencia:** Media (semanas o meses).
* **Ejemplos Generales:**
* Agregar un nuevo parámetro de entrada opcional a una función o API asignándole un valor por defecto (`DEFAULT`).
* Incorporar un nuevo módulo o tabla opcional dentro del sistema sin modificar las estructuras existentes.
* Cambiar un algoritmo de ordenamiento interno para hacerlo más inteligente o eficiente, manteniendo intacta la firma de la función.
* Agregar una nueva tabla de catálogo o un nuevo perfil de configuración predeterminado que no interfiere con los flujos actuales.



---

#### 🔴 **MAJOR (El primer número — Ej: 1.5.2 ➔ 2.0.0)**

* **Nombre:** *Major / Versión Mayor / Cambio Rompedor (Breaking Change).*
* **Cuándo se aumenta:** Cuando realizas modificaciones profundas que **ROMPE la compatibilidad hacia atrás**. El código antiguo, consultas o aplicaciones clientes fallarán si no se actualizan para adaptarse a la nueva versión.
* **Regla de Oro:** Exige que los usuarios o sistemas dependientes actualicen su código, modifiquen nombres de variables/parámetros obligatorios o apliquen migraciones de base de datos destructivas. Al incrementar MAJOR, tanto MINOR como PATCH se reinician a cero.
* **Frecuencia:** Baja (meses o años).
* **Ejemplos Generales:**
* Eliminar un parámetro obligatorio de una función o modificar su nombre/tipo de dato sin dejar un alias de compatibilidad.
* Eliminar o renombrar una tabla o columna existente en la base de datos de la cual dependen aplicaciones externas.
* Reestructurar por completo la respuesta de una API o la firma de ejecución de un procedimiento almacenado.
* Elevar los requisitos mínimos del entorno (ej. requerir una nueva versión mayor del motor de base de datos o del sistema operativo que invalida versiones anteriores).



---

### 📊 CUADRO RESUMEN DE DECISIONES

| Tipo de Cambio Realizado | ¿Rompe los sistemas existentes? | ¿Qué número se incrementa? | Ejemplo de Transición |
| --- | --- | --- | --- |
| Corregir un bug interno, traducir un log o refactorizar variables locales. | **NO** | **PATCH** | `1.0.0` ➔ **`1.0.1`** |
| Agregar un parámetro opcional con valor por defecto o una nueva vista de lectura. | **NO** | **MINOR** | `1.0.1` ➔ **`1.1.0`** *(PATCH vuelve a 0)* |
| Eliminar un parámetro, renombrar una columna de producción o borrar un procedimiento. | **SÍ** | **MAJOR** | `1.1.0` ➔ **`2.0.0`** *(MINOR y PATCH vuelven a 0)* |

---

### 💡 LÓGICA DE EVOLUCIÓN DE VERSIONES

* Si un sistema se encuentra en la versión **`1.0.0`** y aplicamos una mejora estructural estandarizada en la interfaz (como la adición de nuevos parámetros opcionales o refactorizaciones con nuevos contratos de datos), la versión evoluciona a **`1.1.0` (MINOR)**.
* Si posteriormente solo aplicamos correcciones de errores de tipeo, ajustes de logs o parches de mantenimiento interno que no alteran la firma ni la estructura, la versión evoluciona a **`1.1.1` (PATCH)**.
* Si en el futuro se toma la decisión de reestructurar los nombres de las funciones o eliminar parámetros obligatorios rompiendo la compatibilidad anterior, la versión evoluciona a **`2.0.0` (MAJOR)**.
