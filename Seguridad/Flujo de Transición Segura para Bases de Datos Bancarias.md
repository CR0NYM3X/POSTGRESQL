# Consultoría en Seguridad de la Información


Cuando se habla de bases de datos financieras o de core bancario tienen un nivel de criticidad, riesgo y regulación infinitamente superior al de los servicios convencionales como ( ISO 27001, PCI-DSS y marcos de ciberseguridad).  y que requieren un trato especial ,
el cual **bajo ninguna circunstancia se deben "solamente soltar los accesos" a los DBA.** de lo contrario la empresa estaría incurriendo en violaciones graves de cumplimiento (*compliance*), rompiendo la Segregación de Funciones 
(SoD) y abriendo una brecha de seguridad masiva.



## Flujo de Transición Segura para Bases de Datos Bancarias

### 1. Fase de Análisis de Brechas (*Gap Analysis*) y Capacitación
Antes de tocar un solo servidor, la empresa debe evaluar si sus DBA actuales están listos para la responsabilidad de un entorno financiero.

* **Evaluación de Competencias:** Las DB bancarias requieren arquitecturas de Alta Disponibilidad extremas (RPO = 0, RTO en segundos), encriptación en reposo y en tránsito (TDE), y manejo de bóvedas de claves (*Key Vaults*). ¿Los DBA conocen estas tecnologías?
* **Capacitación en Seguridad:** Los DBA deben ser capacitados en manejo de datos sensibles (PII [ Información de Identificación Personal ], PAN [Primary Account Number ] de tarjetas de crédito) y concientizados sobre los riesgos de fraude interno.
* **Revisión de Contratos y NDAs:** Los DBA internos deben firmar nuevos Acuerdos de Confidencialidad y políticas de uso aceptable específicas para el entorno bancario.

### 2. Rediseño del Control de Acceso y Segregación de Funciones (SoD)
Según la norma ISO 27001 (Control de Accesos), un usuario con privilegios no puede ser el mismo que audita.

* **Principio de Menor Privilegio:** Los DBA no deben tener acceso a los datos de la aplicación (como ver saldos, números de cuenta o nombres). Deben tener acceso a la estructura y rendimiento, pero los datos deben estar enmascarados (*Data Masking*).
* **Implementación de PAM (*Privileged Access Management*):** Los DBA no deben conocer las contraseñas reales de `sa`, `root` o `sysdba`. Deben usar una herramienta PAM (ej. CyberArk, BeyondTrust) que les inyecte la sesión o les rote la contraseña después de cada uso.
* **Autenticación Multifactor (MFA):** Acceder a la red donde viven las DB de banco debe requerir MFA estricto, sin excepciones.

### 3. Auditoría y Monitoreo Estricto (DAM)
Los DBA tienen "las llaves del reino". Si un DBA altera un saldo o borra un registro, ¿cómo se da cuenta la empresa?

* **Database Activity Monitoring (DAM):** Implementar herramientas (como Imperva o IBM Guardium) que monitoreen en tiempo real todo lo que ejecutan los DBA.
* **Separación de Logs:** Los logs de auditoría de la base de datos deben enviarse a un SIEM (*Security Information and Event Management*) centralizado. Los DBA no deben tener permisos para borrar o modificar estos logs. Solo el equipo de Seguridad o Auditoría debe acceder a ellos.

### 4. Proceso de Traspaso (*Handover*) del Proveedor a la Empresa
El cambio de mando debe ser quirúrgico. No se heredan accesos; se destruyen y se crean nuevos.

* **Auditoría de Línea Base:** Antes de aceptar las bases de datos, el proveedor debe entregar un reporte de salud (*Health Check*) y de seguridad. La empresa debe saber exactamente qué recibe.
* **Revocación de Accesos del Proveedor:** Cerrar VPNs, tokens y cuentas del proveedor.
* **Rotación Masiva de Credenciales:** Cambiar todas las contraseñas de cuentas de servicio, de administración y llaves de encriptación que el proveedor conocía.
* **Revisión de Backups:** Probar que los respaldos entregados por el proveedor realmente funcionan y pueden ser restaurados por el equipo interno.

### 5. Marco Normativo y de Cumplimiento (*Compliance*)
La empresa debe alinear la operación de los DBA con la regulación vigente (por ejemplo, CNBV en México, PCI-DSS si procesan tarjetas, o ISO 27001 general).

* **Gestión de Cambios:** A partir de ahora, ningún DBA puede ejecutar un script o hacer un pase a producción en las DB bancarias sin un ticket aprobado por un comité de cambios (CAB).
* **Plan de Respuesta a Incidentes:** Actualizar los manuales para saber qué hacer (y a qué autoridades reportar) en caso de que los DBA detecten una intrusión, un ataque de *Ransomware* o una filtración en la DB del banco.


### En conclusión:

El reto principal en este movimiento no radica en la capacidad técnica para mover datos, sino en el control del proceso. Entregar los accesos de las bases de datos del banco al personal interno, sin antes estructurar un gobierno de seguridad robusto, expone a la organización a brechas de seguridad críticas y a sanciones regulatorias severas de forma inmediata.


---



Como experto en tecnologías y ciberseguridad, entiendo perfectamente por qué esta parte puede sonar muy técnica o abstracta. Vamos a desglosarla punto por punto, de forma sencilla y con ejemplos prácticos, para que entiendas exactamente qué significa y por qué es vital en un entorno bancario.

Esta frase se compone de tres conceptos clave:

---

### 1. Manejo de PII (Información de Identificación Personal)

**¿Qué significa?** PII (*Personally Identifiable Information*) es cualquier dato que permita identificar a una persona de forma única.

* **En un banco, esto incluye:** Nombres completos, números de identificación oficial (como el INE en México o el DNI/SSN), direcciones físicas, números de teléfono, correos electrónicos y huellas dactilares o datos biométricos.
* **¿Por qué requiere capacitación?** Un Administrador de Bases de Datos (DBA) tradicional suele preocuparse solo por que la base de datos sea rápida y no se caiga. Sin embargo, un DBA bancario debe entender que **la PII es un imán para los cibercriminales**. Se les debe capacitar para que entiendan las leyes de privacidad (como la Ley Federal de Protección de Datos Personales en México o el GDPR a nivel internacional) y apliquen técnicas como el **enmascaramiento** (que el DBA solo vea `XXXX-XXXX-Juan` en lugar del nombre completo) para que nadie pueda robarse esa información.

### 2. Manejo de PAN de tarjetas de crédito

**¿Qué significa?**
PAN (*Primary Account Number*) es, simplemente, **el número de 16 dígitos que viene al frente de una tarjeta de crédito o débito**.

* **¿Por qué requiere capacitación?** El mundo financiero está regulado por una norma internacional muy estricta llamada **PCI-DSS** (Estándar de Seguridad de Datos para la Industria de Tarjeta de Pago). Esta norma dice que **está prohibido almacenar el número de la tarjeta completo sin encriptar**, y bajo ninguna circunstancia se puede almacenar el código de seguridad (CVV) del reverso.
* **El riesgo:** Si un DBA hace una copia de seguridad (backup) de la base de datos y la guarda en una carpeta sin protección, y esa copia lleva los números de tarjeta a la vista, el banco perdería su certificación para operar con tarjetas y recibiría multas millonarias. Los DBA deben ser capacitados para saber cómo auditar, encriptar y proteger el ciclo de vida de este dato específico.

### 3. Concientizados sobre los riesgos de fraude interno

**¿Qué significa?**
El "fraude interno" ocurre cuando **un empleado de la propia empresa utiliza sus accesos legítimos para robar o alterar información** en beneficio propio o de terceros.

* **¿Por qué requiere capacitación/concientización?** Los DBA son los "súper usuarios" del sistema; técnicamente tienen el poder de alterar las tablas de la base de datos directamente.
* **Un ejemplo de fraude interno:** Imagina un DBA malintencionado (o uno que está siendo extorsionado o sobornado por criminales) que entra a la base de datos a medianoche y cambia el saldo de la cuenta de un cómplice de $100 pesos a $1,000,000 de pesos, o borra el registro de una deuda.
* **El objetivo de la concientización:** No se trata solo de asumir que el DBA es "malo", sino de educarlo en que:
1. **Todo lo que haga dejará huella:** Explicarles que habrá sistemas de monitoreo (como el DAM que menciona el documento) que graban cada tecla que presionen, por lo que cualquier intento de fraude será detectado inmediatamente.
2. **Ingeniería Social:** Capacitarlos para que no caigan en trampas donde criminales externos intenten comprarlos, engañarlos o amenazarlos para que extraigan información del banco.



---



--- 




### 1. Manejo de PII (Información de Identificación Personal)

**¿Qué significa?** PII (*Personally Identifiable Information*) es cualquier dato que permita identificar a una persona de forma única.

* **En un banco, esto incluye:** Nombres completos, números de identificación oficial (como el INE en México o el DNI/SSN), direcciones físicas, números de teléfono, correos electrónicos y huellas dactilares o datos biométricos.
* **¿Por qué requiere capacitación?** Un Administrador de Bases de Datos (DBA) tradicional suele preocuparse solo por que la base de datos sea rápida y no se caiga. Sin embargo, un DBA bancario debe entender que **la PII es un imán para los cibercriminales**. Se les debe capacitar para que entiendan las leyes de privacidad (como la Ley Federal de Protección de Datos Personales en México o el GDPR a nivel internacional) y apliquen técnicas como el **enmascaramiento** (que el DBA solo vea `XXXX-XXXX-Juan` en lugar del nombre completo) para que nadie pueda robarse esa información.

### 2. Manejo de PAN de tarjetas de crédito

**¿Qué significa?**
PAN (*Primary Account Number*) es, simplemente, **el número de 16 dígitos que viene al frente de una tarjeta de crédito o débito**.

* **¿Por qué requiere capacitación?** El mundo financiero está regulado por una norma internacional muy estricta llamada **PCI-DSS** (Estándar de Seguridad de Datos para la Industria de Tarjeta de Pago). Esta norma dice que **está prohibido almacenar el número de la tarjeta completo sin encriptar**, y bajo ninguna circunstancia se puede almacenar el código de seguridad (CVV) del reverso.
* **El riesgo:** Si un DBA hace una copia de seguridad (backup) de la base de datos y la guarda en una carpeta sin protección, y esa copia lleva los números de tarjeta a la vista, el banco perdería su certificación para operar con tarjetas y recibiría multas millonarias. Los DBA deben ser capacitados para saber cómo auditar, encriptar y proteger el ciclo de vida de este dato específico.

### 3. Concientizados sobre los riesgos de fraude interno

**¿Qué significa?**
El "fraude interno" ocurre cuando **un empleado de la propia empresa utiliza sus accesos legítimos para robar o alterar información** en beneficio propio o de terceros.

* **¿Por qué requiere capacitación/concientización?** Los DBA son los "súper usuarios" del sistema; técnicamente tienen el poder de alterar las tablas de la base de datos directamente.
* **Un ejemplo de fraude interno:** Imagina un DBA malintencionado (o uno que está siendo extorsionado o sobornado por criminales) que entra a la base de datos a medianoche y cambia el saldo de la cuenta de un cómplice de $100 pesos a $1,000,000 de pesos, o borra el registro de una deuda.
* **El objetivo de la concientización:** No se trata solo de asumir que el DBA es "malo", sino de educarlo en que:
1. **Todo lo que haga dejará huella:** Explicarles que habrá sistemas de monitoreo (como el DAM que menciona el documento) que graban cada tecla que presionen, por lo que cualquier intento de fraude será detectado inmediatamente.
2. **Ingeniería Social:** Capacitarlos para que no caigan en trampas donde criminales externos intenten comprarlos, engañarlos o amenazarlos para que extraigan información del banco.

---


**SoD** son las siglas en inglés de **Segregation of Duties**, que en español traducimos como **Segregación de Funciones** (o Separación de Funciones).

En el mundo de la tecnología, la auditoría y las finanzas, es uno de los principios de seguridad más antiguos y vitales que existen. Su regla de oro es muy simple: **ninguna persona debe tener el poder suficiente para cometer un fraude o un error grave y cubrir sus propios rastros.**

Para entenderlo de forma entretenida, piensa en las películas de Hollywood donde, para lanzar un misil nuclear, dos oficiales distintos tienen que introducir dos llaves diferentes al mismo tiempo. Ninguno puede hacerlo solo. Eso es SoD en el mundo real.

---

### ¿Cómo se aplica SoD en las Bases de Datos de un Banco?

Cuando llevamos este concepto a los Administradores de Bases de Datos (DBA), el principio dice que **las funciones técnicas deben estar separadas de las funciones de negocio y de control**.

Aquí tienes los tres ejemplos más claros de cómo se rompe y cómo se debe aplicar la Segregación de Funciones:

| ¿Cómo se rompe el SoD? (El peligro) | ¿Cómo se aplica correctamente el SoD? |
| --- | --- |
| **El DBA que ve saldos:** El administrador técnico entra a la base de datos para arreglar la velocidad del sistema, pero de paso se pone a revisar el saldo de la cuenta de su jefe o de una celebridad. | **Data Masking (Enmascaramiento):** El DBA puede ver que la tabla mide 50 gigabytes y que los índices están bien, pero los nombres y los saldos reales le aparecen como `XXXXX` o alterados con datos falsos. |
| **El DBA "Súper Héroe":** El DBA modifica un dato (por ejemplo, se transfiere dinero a su cuenta) y luego entra al historial de actividad (logs) y borra el registro de lo que hizo para que nadie se entere. | **Separación de Logs:** El DBA tiene control del servidor, pero las bitácoras de lo que hace se envían en tiempo real a un servidor externo (SIEM) controlado por el equipo de **Seguridad de la Información**. El DBA no puede borrar su propio rastro. |
| **El DBA que se autoevalúa:** El mismo DBA que escribe un código o un script para modificar la base de datos es el que se lo aprueba a sí mismo y lo mete a producción a mitad de la noche. | **Comité de Cambios (CAB):** El DBA propone el cambio técnico, pero un equipo ajeno (un comité o un gerente de operaciones) debe revisar el impacto y autorizar la aplicación de ese cambio. |

---

### ¿Por qué es tan crítico en ciberseguridad?

Si una empresa ignora el SoD y le da "todos los accesos" a los DBA (el famoso usuario `root`, `sa` o `sysdba` sin control), está creando un **único punto de falla humano**. Si ese DBA se vuelve malintencionado, si es extorsionado por cibercriminales, o simplemente si comete un error de dedo catastrófico, no habrá ninguna línea de defensa que lo detenga.

Por eso, normas como **ISO 27001** (seguridad), **PCI-DSS** (tarjetas de crédito) y las regulaciones bancarias locales exigen que el SoD esté documentado, automatizado y auditado estrictamente. Es la diferencia entre confiar a ciegas en las personas o confiar en un proceso seguro.
