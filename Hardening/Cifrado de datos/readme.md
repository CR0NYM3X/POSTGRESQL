

https://www.postgresql.org/docs/current/encryption-options.html

---

### Proveedores que ofrecen cifrado de columnas con visualización segura

| Proveedor         | Solución específica                          | Características clave                                 |
|------------------|-----------------------------------------------|--------------------------------------------------------|
| **Thales CipherTrust [1](https://cpl.thalesgroup.com/es/encryption)** | Application Data Protection               | Cifrado por API, tokenización, visualización controlada |
| **Protegrity [1](https://www.protegrity.com/)**    | Data Protection Platform                     | Cifrado de columnas, políticas de acceso, integración con apps |
| **Vormetric (Thales)** | Transparent Encryption + Tokenization    | Cifrado sin modificar apps, soporte para PostgreSQL y SQL Server |
| **DataSunrise**   | Database Security Suite                      | Cifrado dinámico de columnas, control de acceso, auditoría |
| **IBM Guardium**  | Data Encryption & Activity Monitoring        | Cifrado granular, visualización controlada, cumplimiento normativo |




###   ¿Cómo funciona este enfoque?

- Los datos se cifran **al insertarse o actualizarse** en la base de datos.
- Los clientes acceden a los datos **descifrados automáticamente** si tienen permisos adecuados.
- El cifrado se realiza mediante **API o proxy**, no dentro del motor de base de datos.
- Puedes definir qué columnas se cifran (por ejemplo: `email`, `SSN`, `tarjeta_credito`) y qué roles pueden ver los datos en claro.
 

###   Ventajas

- **No necesitas modificar tu base de datos ni usar extensiones nativas.**
- **Compatible con múltiples motores** (PostgreSQL, SQL Server, Oracle, etc.).
- **Cumple con normativas** como GDPR, HIPAA, PCI-DSS.
- **Visualización controlada**: solo usuarios autorizados ven los datos en claro.
 
 
----

 
###  Flujo de trabajo típico con proveedores externos

#### 1. **Definición de columnas sensibles**
- Identificas qué columnas deben cifrarse: por ejemplo, `email`, `SSN`, `tarjeta_credito`, etc.
- Estas columnas se configuran en la herramienta externa como “protegidas”.

#### 2. **Interceptación o integración**
- La herramienta se integra como **proxy**, **middleware**, o **SDK/API** entre tu aplicación y la base de datos.
- Cuando tu app hace un `INSERT`, `UPDATE` o `SELECT`, la herramienta intercepta la consulta.

#### 3. **Cifrado en escritura**
- Al insertar o actualizar datos, la herramienta cifra automáticamente los valores sensibles **antes de que lleguen a la base de datos**.
- El dato cifrado se almacena en la tabla como `ciphertext`, generalmente en formato `VARBINARY`, `BYTEA` o `TEXT`.

#### 4. **Descifrado en lectura**
- Cuando un cliente autorizado hace una consulta, la herramienta descifra los datos **en tiempo real** y los entrega en claro a la aplicación.
- Si el usuario no tiene permisos, el campo puede aparecer como `NULL`, `MASKED`, o simplemente cifrado.

#### 5. **Gestión de claves**
- Las claves de cifrado se almacenan en un **HSM** o en el sistema de gestión de claves del proveedor.
- Puedes rotarlas, revocarlas o auditar su uso sin tocar la base de datos.


### Ejemplo práctico

Tu app hace esto:

```sql
SELECT nombre, tarjeta_credito FROM clientes WHERE id = 123;
```

La herramienta intercepta y:
- Verifica si el usuario tiene permisos.
- Descifra `tarjeta_credito` si está autorizado.
- Devuelve: `Juan Pérez | 4111-XXXX-XXXX-1234`

---
 

### 🔐 Software de cifrado de datos en reposo (sin hardware)

| Software            | Bases de datos compatibles       | Características clave                                 |
|---------------------|----------------------------------|--------------------------------------------------------|
| **DataSunrise**     | PostgreSQL, SQL Server, Oracle   | Cifrado dinámico de columnas, control de acceso, auditoría |
| **Protegrity**      | PostgreSQL, SQL Server, BigQuery | Cifrado por políticas, tokenización, SDKs para apps     |
| **Thales CipherTrust App Protection** | PostgreSQL, SQL Server | Cifrado por API, sin modificar la base de datos, gestión de claves |
| **HashiCorp Vault** | PostgreSQL, SQL Server (via API) | Cifrado de datos por aplicación, gestión de claves, integración con apps |
| **Virtru Data Protection** | PostgreSQL (via proxy/API) | Cifrado granular, control de acceso, visibilidad de uso |
| **SymmetricDS + Custom Crypto** | PostgreSQL, SQL Server | Replicación + cifrado personalizado en tránsito y reposo |

 
###   ¿Cómo funcionan?

- Se integran como **middleware, proxy o SDK** entre tu aplicación y la base de datos.
- Cifran los datos **antes de que lleguen a la base de datos**.
- Descifran los datos **al leerlos**, si el usuario tiene permisos.
- No requieren modificar el motor de base de datos ni instalar extensiones como `pgcrypto`.

 


```sql
https://medium.com/myntra-engineering/data-security-and-privacy-data-at-rest-encryption-approaches-eb4977b5d723

https://www.primefactors.com/data-protection/encryptright/?utm_term=data%20at%20rest%20encryption&utm_campaign=Encryption&utm_source=adwords&utm_medium=ppc&hsa_acc=2387905330&hsa_cam=10151999730&hsa_grp=102556252035&hsa_ad=438979470922&hsa_src=g&hsa_tgt=kwd-326727796234&hsa_kw=data%20at%20rest%20encryption&hsa_mt=e&hsa_net=adwords&hsa_ver=3&gad_source=1&gad_campaignid=10151999730&gbraid=0AAAAAD_ndveZpBFEgTT51Rie3qESsjhkZ&gclid=CjwKCAjw7fzDBhA7EiwAOqJkh2ebxKMUi6BPWfrhK1aO8mxtw4rFW_hLhMIqiQAlnQw-my3trEoUpRoCg9kQAvD_BwE

https://www.imperva.com/learn/data-security/data-at-rest/

https://www.opentext.com/what-is/encryption?__hstc=188543543.4b44870ec4a577029c49e44b73bd3bee.1692576000803.1692576000804.1692576000805.1&__hssc=188543543.1.1692576000806&__hsfp=954974628
```
