

https://www.postgresql.org/docs/current/encryption-options.html

### 📊 **1. Comparación por criterios clave**

| Criterio                  | Tokenización         | Cifrado FPE           | Enmascaramiento Dinámico | Enmascaramiento Estático | Anonimización           | Cifrado tradicional (pgcrypter) |
|---------------------------|----------------------|------------------------|---------------------------|---------------------------|--------------------------|-------------------------------|
| Reversibilidad            | ✅ (con sistema)     | ✅ (con clave)         | ✅ (según rol)            | ❌                        | ❌                       | ✅ (con clave)               |
| Preserva formato          | ✅                   | ✅                     | ✅/❌ (depende)            | ✅/❌                     | ✅/❌                    | ❌                           |
| Modifica datos almacenados| ✅/❌ (depende)       | ✅                     | ❌                        | ✅                        | ✅                       | ✅                           |
| Uso en producción         | ✅                   | ✅                     | ✅                        | ❌                        | ❌                       | ✅                           |
| Uso en pruebas/desarrollo| ❌                   | ❌                     | ❌                        | ✅                        | ✅                       | ✅                           |
| Soporte para búsquedas    | ❌                   | ✅ (si determinista)   | ✅ (limitado)             | ✅ (limitado)             | ❌                       | ❌                           |
| Complejidad de implementación | Media           | Alta                   | Baja                      | Media                     | Media                    | Baja                          |

 
---

### 📊 **Impacto en Rendimiento y Escalabilidad**

| **Técnica**                 | **Impacto en Rendimiento**                                 | **Escalabilidad**                                               |
|----------------------------|-------------------------------------------------------------|------------------------------------------------------------------|
| **Tokenización**           | Medio-Alto (depende del sistema de tokenización y API)     | Media (requiere bóveda o API escalable y segura)                |
| **Cifrado FPE**            | Alto (procesamiento criptográfico complejo)                | Media-Baja (clave y algoritmo deben escalar con el sistema)     |
| **Enmascaramiento Dinámico** | Bajo (se aplica en tiempo de consulta, sin modificar datos) | Alta (basado en roles, no requiere replicación ni cifrado)      |
| **Enmascaramiento Estático** | Medio (requiere modificación y replicación de datos)        | Media (útil en entornos de desarrollo, no ideal para producción)|
| **Anonimización**          | Bajo (datos irreversibles, no se consultan frecuentemente) | Alta (no requiere protección adicional ni gestión de claves)    |
| **Cifrado tradicional (pgcrypter)** | Medio (cifrado/desencriptado en tiempo real)             | Media (depende de la gestión de claves y rendimiento del motor) |


---

### 📌 **2. ¿Cuál usar y cuándo?**

| Caso de uso                          | Técnica recomendada                     | Justificación                                                                 |
|-------------------------------------|-----------------------------------------|-------------------------------------------------------------------------------|
| Protección en tiempo real           | Enmascaramiento dinámico                | No modifica datos, se adapta al rol del usuario                              |
| Cumplimiento PCI-DSS                | Tokenización o FPE                      | Ambas cumplen con requisitos de protección de datos sensibles                |
| Desarrollo sin datos reales         | Enmascaramiento estático o anonimización| Evita exposición de datos reales                                             |
| Análisis estadístico sin riesgo     | Anonimización                           | Elimina posibilidad de identificación                                        |
| Integración con sistemas heredados  | FPE                                     | Mantiene formato original, facilita compatibilidad                           |
| Cifrado simple en PostgreSQL        | pgcrypter                               | Fácil de implementar, útil para cifrado general                              |

---

### ✅ **3. Cumplimiento normativo**

| Norma / Requisito        | Tokenización | FPE | Enmascaramiento | Anonimización | Cifrado tradicional |
|--------------------------|--------------|-----|------------------|----------------|----------------------|
| **PCI-DSS**              | ✅           | ✅  | ✅ (dinámico)     | ❌              | ✅                   |
| **GDPR / LFPDPPP**       | ✅           | ✅  | ✅               | ✅              | ✅                   |
| **HIPAA**                | ✅           | ✅  | ✅               | ✅              | ✅                   |
| **ISO 27001 / 27701**    | ✅           | ✅  | ✅               | ✅              | ✅                   |

---

### 🔍 **4. Diferencias clave entre técnicas**

| Técnica           | Diferencia clave                                                                 |
|-------------------|----------------------------------------------------------------------------------|
| Tokenización      | Requiere sistema de mapeo, no reversible sin él                                 |
| FPE               | Cifra manteniendo el formato, útil para compatibilidad                          |
| Enmascaramiento   | Oculta datos sin cifrar, útil para control de acceso visual                     |
| Anonimización     | Irreversible, elimina posibilidad de identificación                             |
| Cifrado tradicional| Cifra completamente, no conserva formato, reversible con clave                 |

---

### Proveedores que ofrecen cifrado de columnas con visualización segura
```
[OpenText] - PoC Voltage Encryption

	Links -> 	
				https://ot-latam.com/
				https://www.opentext.com/
				https://mx.linkedin.com/company/ot-latam
				
			 
	Personal ->  
					Carolina Elortegui celortegui@ot-latam.com, 
					Juan Carlos Ortiz Leyva,  Gonzalo Sanchez - OT Latam 
					Hermilo Mendez de Open Text 

	

[Thales] - PoC Thales CypherTrust Data Security

	Links -> 
				https://cpl.thalesgroup.com/es/encryption/database-security
				https://cpl.thalesgroup.com/es/encryption/database-security/postgresql-database-encryption
	
	Personal ->
					sinue.botello@thalesgroup.com
					maydeli.solorio@thalesgroup.com
					antonio.perez@optimiti.com.mx
					celortegui@ot-latam.com

	- Niveles: 
		* Application: CipherTrust Application Encryption , cipherTrust Tokenization
		* Database: CipherTrust Database Protection, CipherTrust Key Management
		* Operationg System: CipherTrust Transparent Encryptin
					
					
[IBM] - PoC Guardium Encryption - [Secrurity Transparent Encryption]

	Link -> 
					

	Personal ->
					david.vicenteno.sanchez@ibm.com
					mvertiz@mx1.ibm.com
					luis.moy@ibm.com

```


```sql
https://medium.com/myntra-engineering/data-security-and-privacy-data-at-rest-encryption-approaches-eb4977b5d723

https://www.primefactors.com/data-protection/encryptright/?utm_term=data%20at%20rest%20encryption&utm_campaign=Encryption&utm_source=adwords&utm_medium=ppc&hsa_acc=2387905330&hsa_cam=10151999730&hsa_grp=102556252035&hsa_ad=438979470922&hsa_src=g&hsa_tgt=kwd-326727796234&hsa_kw=data%20at%20rest%20encryption&hsa_mt=e&hsa_net=adwords&hsa_ver=3&gad_source=1&gad_campaignid=10151999730&gbraid=0AAAAAD_ndveZpBFEgTT51Rie3qESsjhkZ&gclid=CjwKCAjw7fzDBhA7EiwAOqJkh2ebxKMUi6BPWfrhK1aO8mxtw4rFW_hLhMIqiQAlnQw-my3trEoUpRoCg9kQAvD_BwE

https://www.imperva.com/learn/data-security/data-at-rest/

https://www.opentext.com/what-is/encryption?__hstc=188543543.4b44870ec4a577029c49e44b73bd3bee.1692576000803.1692576000804.1692576000805.1&__hssc=188543543.1.1692576000806&__hsfp=954974628
```
