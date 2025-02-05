

LDAP (Lightweight Directory Access Protocol):  Se utiliza para acceder y buscar información almacenada en un directorio, que generalmente contiene información sobre usuarios, grupos, recursos de red  
En resumen, LDAP es un protocolo altamente escalable y flexible que se utiliza ampliamente en entornos corporativos para centralizar la gestión de usuarios, grupos y recursos de red. Proporciona una forma estándar de acceder y buscar información en directorios distribuidos, lo que lo convierte en una herramienta fundamental en la administración de identidades y la gestión de acceso en sistemas de información empresarial.


########## TIPOS DE AUTENTICACION ##########

LDAP, RADIUS —
Kerberos/GSSAPI —
SSPI
LDAP
md5 – SCRAM-SHA-256
Cert
peer
PAM Authentication 
BSD Authentication 
 
################# DESCUBRIR CN DESDE CMD  #################
NECESITAS ESTAR EN DOMINIO

 gpresult /r /scope user | find "CN="

---  Obtener la ruta del usuario actual
Get-ADUser $env:USERNAME -Properties DistinguishedName | Select-Object DistinguishedName

---  Buscar por nombre de usuario
$username = Read-Host "Ingrese su nombre de usuario (samAccountName)"
Get-ADUser $username -Properties DistinguishedName | Select-Object DistinguishedName
dsquery user -name "juan.perez"


--- cmd
whoami /fqdn
nltest /dsgetdc:empresa.com /user:juan.perez


 
################# VALIDAR PAQUETES NECESARIOS  #################

[postgres@SERVER_TEST ~]$  rpm -qa  | grep -i ldap
openldap-2.4.46-19.el8_10.x86_64
openldap-clients-2.4.46-19.el8_10.x86_64
openldap-servers-2.4.46-19.el8_10.x86_64

[postgres@SERVER_TEST ~]$ rpm -qa  | grep -i openssl
openssl-devel-1.1.1k-12.el8_9.x86_64
openssl-1.1.1k-12.el8_9.x86_64
openssl-pkcs11-0.4.10-3.el8.x86_64
xmlsec1-openssl-1.2.25-8.el8_10.x86_64
openssl-libs-1.1.1k-12.el8_9.x86_64

[postgres@SERVER_TEST ~]$  ls -lhtr /usr/bin | grep ldap
lrwxrwxrwx. 1 root root       10 May 21  2024 ldapadd -> ldapmodify
-rwxr-xr-x. 1 root root      66K May 21  2024 ldapwhoami
-rwxr-xr-x. 1 root root      25K May 21  2024 ldapurl
-rwxr-xr-x. 1 root root      90K May 21  2024 ldapsearch
-rwxr-xr-x. 1 root root      66K May 21  2024 ldappasswd
-rwxr-xr-x. 1 root root      66K May 21  2024 ldapmodrdn
-rwxr-xr-x. 1 root root      78K May 21  2024 ldapmodify
-rwxr-xr-x. 1 root root      66K May 21  2024 ldapexop
-rwxr-xr-x. 1 root root      66K May 21  2024 ldapdelete
-rwxr-xr-x. 1 root root      66K May 21  2024 ldapcompare


################# VALIDAR CONEXION CON SERV LDAP  #################

TELNET 192.168.100.10 389 # LDAP no seguro  	
TELNET 192.168.100.10 636 # LDAP  seguro SSL/TLS.  

################# FILTROS PARA LDAP  #################

--- Filtro para buscar , se coloca siempre al final de la consulta ldapsearch
(sAMAccountName=roberto.maiz)  
(cn=roberto.maiz) ou
(uid=francisco.maiz)
(sn=apellido)
(displayName=nombre_completo)
(primaryGroupID=grupo_id)
(atributo=valor)
(memberOf=cn=grupo,ou=Grupos,dc=liverpool,dc=com)
(employeeNumber=12345)
(mail=roberto.maiz@liverpool.com)
 "objectclass=*" 


################# BUSCAR CN CON LDAP  #################

--- BUSCANDO GRUPOS 
 ldapsearch -x -LLL -h  192.168.100.10 -D usuario_corp@dominio_test.com -w 'MI_CONTRAASEÑA123'  -b "dc=dominio_test,dc=com"   "objectclass=*"  | grep memberOf | grep -i dba
 ldapsearch -x -LLL -h  192.168.100.10 -D usuario_corp@dominio_test.com -w 'MI_CONTRAASEÑA123'  -b "CN=DBA,OU=Seguridad,OU=Grupos,DC=dominio_test,DC=com"  | grep -i -A 1  "tortolero"


--- BUSCANDO MIEMBROS  
  ldapsearch -x -LLL -h  192.168.100.10 -D usuario_corp@dominio_test.com -w 'MI_CONTRAASEÑA123'  -b "CN=DBA,OU=Seguridad,OU=Grupos,DC=dominio_test,DC=com" | grep member
  

################# VERIFICAR LA AUTENTICACION DEL USUARIO   #################

 ldapwhoami -vvv -h  10.30.120.23 -D "CN=Jose Antonio Perez Garcia,OU=usuarios,DC=dominio_test,DC=com" -x -W
	ldap_initialize( ldap://10.30.120.23 )
	Enter LDAP Password:
	u:LIVERPOOL\jose.garciag
	Result: Success (0)
 

################# CONFIGURACION PG_HBA  #################
  
 
	-- Expone la contraseña, puedes acceder con el employeeID, employeeNumber , sAMAccountName
  host all  98857688  0.0.0.0/0 ldap ldapserver=192.168.100.10  ldapport=389 ldapbasedn="OU=usuarios,DC=dominio_test,DC=com"  ldapsearchattribute="employeeID" ldapbinddn="usuario_corp@dominio_test.com" ldapbindpasswd="MI_CONTRAASEÑA123"
 
  
	-- Esta opcion no requiere de contraseña, pero solicita el CN completo y tienes que colocar ",OU" 
   host postgres  "Jose Antonio Perez Garcia"  0.0.0.0/0  ldap ldapserver=192.168.100.10  ldapport=389 ldapprefix="cn=" ldapsuffix=",OU=usuarios,DC=dominio_test,DC=com"
  

	--	
	/usr/pgsql-15/bin/pg_ctl reload  -D /sysx/data
 
 
 ################# CREAR EL USAURIO  #################
 
 CREATE USER 98857688;
 CREATE USER "Jose Antonio Perez Garcia";
 
 
 ################# CONCEPTOS #################
 
 
ldapserver=34.221.44.138: Especifica la dirección IP o el nombre de host del servidor LDAP al que PostgreSQL debe conectarse para autenticar a los usuarios.

ldapbasedn="cn=Users,dc=tech,dc=local": Especifica el DN (Distinguished Name) base del directorio LDAP que se utilizará para buscar usuarios. En este caso, se está utilizando el contenedor "Users" en el dominio "tech.local".

ldapbinddn="CN=bind,CN=Users,dc=tech,dc=local": Especifica el DN del usuario que se utilizará para realizar la conexión inicial al servidor LDAP. En este caso, se está utilizando un usuario con el nombre "bind" dentro del contenedor "Users" en el dominio "tech.local".

ldapbindpasswd=123qwe..: Especifica la contraseña del usuario LDAP utilizado para la conexión inicial al servidor LDAP.

ldapsearchattribute="sAMAccountName": Especifica el atributo LDAP que se utilizará para buscar usuarios durante el proceso de autenticación. En este caso, se está utilizando el atributo "sAMAccountName", que generalmente se utiliza en entornos de Active Directory para representar el nombre de usuario.


ldaptls=1: Indica si se utilizará TLS (Transport Layer Security) para cifrar la comunicación entre PostgreSQL y el servidor LDAP. El valor "1" significa que se habilitará TLS.
ldapport=636: Especifica el puerto LDAP sobre el cual se realizará la conexión. El puerto 636 es el puerto predeterminado para LDAP sobre TLS (LDAPs).


ldapprefix="cn=": Especifica el prefijo utilizado para construir el nombre distinguido (DN) completo del usuario durante la búsqueda en el servidor LDAP. En este caso, se está utilizando "cn=" como prefijo.
ldapsuffix=", dc=pg_user, dc=nodomain": Especifica el sufijo utilizado para construir el nombre distinguido (DN) completo del usuario durante la búsqueda en el servidor LDAP. E


CN (Common Name): Es un atributo utilizado para identificar objetos en LDAP. En el contexto de usuarios, el CN generalmente se refiere al nombre completo del usuario. Por ejemplo, "CN=John Doe".

OU (Organizational Unit): Representa una unidad organizativa en la estructura de un directorio LDAP. Se utiliza para organizar los objetos en una jerarquía lógica. Por ejemplo, "OU=Users" podría contener todos los usuarios de un dominio.

DC (Domain Component): Se utiliza para representar componentes de nombres de dominio en LDAP. En un contexto LDAP, los nombres de dominio se representan como una secuencia de componentes DC separados por comas. Por ejemplo, "DC=example,DC=com" representa el dominio "example.com".

DN (Distinguished Name): Es una cadena única que identifica de manera única un objeto dentro de un árbol LDAP. Un DN se compone de una secuencia de RDNs (Relative Distinguished Names) que comienzan desde el objeto raíz hasta el objeto en cuestión.

RDN (Relative Distinguished Name): Es el nombre único relativo de un objeto dentro de un contenedor. Por ejemplo, en el DN "CN=John Doe,OU=Users,DC=example,DC=com", "CN=John Doe" es el RDN del objeto.



 ################# VERIFICAR CONEXION TLS #################


--- verificar conexion tls 
openssl s_client -connect liverpool.com:636 
openssl s_client -connect liverpool.com:3268
openssl s_client -connect liverpool.com:3269 
 
 
 
--- obtener  Root CA
openssl s_client -connect 192.168.2.100:636  -showcerts
openssl s_client -connect ldap.example.com:389 -starttls ldap
openssl s_client -showcerts -verify 5 -connect liverpool.com:636  < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/)    {a++}; out="cert"a".pem"; print >out}'



 ################# CONFIGURACION DE LDAP SSL/TLS #################

vim /etc/openldap/ldap.conf
 
URI liverpool.com
BASE dc=liverpool,dc=com
TLS_CACERTDIR /sysx/data
TLS_CACERT /sysx/data/tls_cretificado.crt


 ################# REFERENCIAS  #################
ldap-tls conf
 https://ltb-project.org/documentation/openldap_ssl_tls_mutual_authentication.html
https://www.openldap.org/doc/admin25/tls.html



--- instalar  y conf ldap - serv
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/ch-ldap#s1-ldap-adv
https://docs.oracle.com/en/operating-systems/oracle-linux/6/admin/configuring-ldap-server.html
https://ubuntu.com/server/docs/service-ldap
https://www.ibm.com/docs/en/rpa/23.0?topic=ldap-installing-configuring-openldap


https://ltb-project.org/documentation/openldap_ssl_tls_mutual_authentication.html#client-configuration



--------- fecha 15/03/2024 ----------



LDAP TLS 
https://docs.vmware.com/en/VMware-Greenplum/7/greenplum-database/admin_guide-ldap.html
https://dba.stackexchange.com/questions/305720/setup-secure-ldap-over-ssl-tls-ldaps-for-postgresql
https://stackoverflow.com/questions/73807696/postgres-secure-ldap-authentication-issues
https://wiki.postgresql.org/wiki/LDAP_Authentication_against_AD

Kerberos vs Ldap
https://severalnines.com/blog/integrating-postgresql-authentication-systems/



------ fecha 13/03/2024 ----

Se revisaron los reportes y se siguieron haciendo pruebas hasta que permitio


filtros ldap :
https://devconnected.com/how-to-search-ldap-using-ldapsearch-examples/
https://access.redhat.com/documentation/es-es/red_hat_directory_server/11/html/administration_guide/examples-of-common-ldapsearches


------ fecha 12/03/2024 ----

https://www.postgresql.fastware.com/blog/connecting-fep-to-ad-for-authentication-using-ldap
https://www.strongdm.com/blog/connecting-postgres-to-active-directory-for-authentication
https://elephas.io/connecting-postgres-to-active-directory-for-authentication/


https://www.initmax.com/wiki/postgresql-access-control-using-an-external-authentication-provider/


@ Instalacion de OpenLDAP -client
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/s1-ldap-daemonsutils






------ fecha 11/03/2024 ----
https://repo.postgrespro.ru/doc//pgsql/11.22/en/postgres-A4.pdf

https://www.postgresql.org/docs/current/auth-ldap.html
https://www.percona.com/blog/configuring-postgresql-and-ldap-using-starttls/
https://postgresconf.org/system/events/document/000/000/183/pgconf_us_v4.pdf 

https://www.initmax.cz/wp-content/uploads/2024/06/enterprise-solution-in-postgresql_efficient-and-flexible-access-management.pdf
https://h50146.www5.hpe.com/products/software/oe/linux/mainstream/support/lcc/pdf/PostgreSQL16Beta1_New_Features_en_20230528_1.pdf

https://techexpert.tips/es/postgresql-es/autenticacion-ldap-de-postgresql-en-active-directory/  -- tambien tiene para implementar pgppgadmin
https://www.redbooks.ibm.com/redbooks/pdfs/sg244986.pdf
https://www.profesordeinformatica.com/descargas/capitulo6-ldap.pdf


https://blog.redforce.io/windows-authentication-attacks-part-2-kerberos/

--- PostgreSQL GSSAPI Authentication with Kerberos part-1: how to setup Kerberos on Ubuntu
https://www.highgo.ca/2020/03/18/postgresql-gssapi-authentication-with-kerberos-part-1-how-to-setup-kerberos-on-ubuntu/
https://www.highgo.ca/2020/03/26/postgresql-gssapi-authentication-with-kerberos-part-2-postgresql-configuration/
https://www.highgo.ca/2020/03/30/postgresql-gssapi-authentication-with-kerberos-part-3-the-status-of-authentication-encryption-and-user-principal/

--- empresa de seguridad
https://info.enterprisedb.com/rs/069-ALB-339/images/Security-best-practices-2020.pdf?_ga=2.241796162.1507359552.1601965382-378383403.1546583698




-- https://docs.citrix.com/es-es/xenmobile/server/authentication/client-certificate.html


