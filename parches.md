
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

LIFE CYCLES POSTGRESQL 		https://www.postgresql.org/support/versioning/													
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
