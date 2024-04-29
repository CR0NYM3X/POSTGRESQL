
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

/*
Antes de actualizar es importante validar la nota de la version, ya que te dice los cambios realizados y te puede dar advertencias como por ejemplo que antes de actualizar necesitas restaurar

---> Este te dice que no necesitas hacer un dump y restauracion, ya que solo contiene correcciones 
This release contains a variety of fixes from 15.0. 
A dump/restore is not required for those running 14.X.

--> En cambio este te advierte que necesitas hacer un dump y restaurar ya que esta version tiene cambios que pueden afectar 
A dump/restore using pg_dumpall or use of pg_upgrade
Version 14 contains a number of changes that may affect compatibility with previous releases. 

*/

https://www.postgresql.org/docs/release/
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
```

# ODBC
```
https://odbc.postgresql.org/
```

# Vulnerabilidades de seguridad 
```
https://www.postgresql.org/support/security/
https://www.cvedetails.com/vulnerability-list/vendor_id-336/product_id-575/Postgresql-Postgresql.html
```
