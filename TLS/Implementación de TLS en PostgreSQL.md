PostgreSQL tiene soporte nativo para usar conexiones SSL para cifrar las comunicaciones entre cliente y servidor
para mayor seguridad. Esto requiere que OpenSSL esté instalado tanto en los sistemas cliente como servidor y
que el soporte en PostgreSQL esté habilitado en el momento de la compilación.


 

# Fase #1 Pre-Implementación 

### Requisitos

#### #1 En el servidor Tener Instalado igual o mayo OpenSSL 1.1.1
```BASH
    openssl version  # --> OpenSSL igual o mayo a 1.1.1 
    openssl version -d  # --> OPENSSLDIR: "/etc/pki/tls"  Establece valores predeterminados para varios campos en los certificados.
```
 
#### Versiones compatibles de SSL/TLS con OpenSSL
| **Versión de OpenSSL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** |
|------------------------|-----------|-----------|-------------|-------------|-------------|-------------|
| **OpenSSL 1.0.x**      | disable   | disable   | true        | true        | true        | false       |
| **OpenSSL 1.1.x**      | false     | false     | true        | true        | true        | false       |
| **OpenSSL 1.1.1**      | false     | false     | true        | true        | true        | true        |
| **OpenSSL 3.0.x**      | false     | false     | true        | true        | true        | true        |


 
#### #2 En el Servidor tener instalado [PostgreSQL con soporte](https://www.postgresql.org/support/versioning/) y compatible con tls 1.2. y 1.3
```SQL
postgres@postgres# select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.6 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)

Time: 0.557 ms
```


#### Versiones compatibles de SSL/TLS con PostgreSQL 

| **Versión de PostgreSQL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** | **ssl_min_protocol_version** | **ssl_max_protocol_version** |
|---------------------------|-----------|-----------|-------------|-------------|-------------|-------------|-----------------------------|-----------------------------|
| **9.4**                   | false     | false     | true        | true        | true        | false       | N/A                         | N/A                         |
| **12**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **13**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **14**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **15**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **16**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **17**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |



# Fase #2 Implementación 


1. **Crear archivos para TLS.** 
   ```sql
   ```

2. **Tipos de conexión de modessl del cliente** 
   ```sql
   ```


3. **Primera capa de seguridad ( Habilitar TLS y forzar el uso de TLS )** 
   ```sql
   
   ```


4. **Segunda capa de seguridad ( Validación de CA )** 
   ```sql
   ```


5. **Tercera capa de seguridad ( Validación FULL )** 
   ```sql
   ```
   
 
6. **Cuarta capa de seguridad (Revocación de certificados comprometidos o vencidos)** 
   ```sql
   ```
   

7. **Quinta capa de seguridad (Autenticacion del cliente con certiciado)** 
   ```sql
   ```
   


8. **Concideraciones y Posibles errores en entornos de productivos.** 
   ```sql
   ```


# **Post-Implementación.** 
1. **Monitoreo y validacion de conexiónes.** 
   ```sql
   ```
1. **Validar que se este usando TLS** 
   ```sql
   ```

1. **Entrega de documentación y metricas de resultados..** 
   ```sql
   ```
   










