### Área fundamental **Marco de Gobierno de Seguridad de la Información**

# 🛡️ Fundamentos de Seguridad de la Información (SI)

Este repositorio detalla los pilares básicos que cualquier empresa debe implementar para garantizar la integridad, disponibilidad y confidencialidad de sus activos digitales.


Para que una empresa esté protegida, no basta con tener un antivirus. Se requiere un marco de **Seguridad de la Información (SI)** que combine:

1. **Cultura:** A través de políticas que el personal debe seguir.
2. **Técnica:** Mediante estándares de configuración que cierren las brechas de seguridad en la infraestructura.
3. **Monitoreo:** Asegurando que todo lo anterior se cumpla y se registre.



## 1. Políticas de Seguridad

Las políticas son las reglas de alto nivel que dictan el comportamiento de la organización y sus empleados.

* **Dispositivos Móviles y Movilidad:** Reglas para el uso seguro de smartphones y laptops fuera de la oficina.
* **Seguridad en los Recursos Humanos:** Protocolos antes, durante y después de la relación laboral.
* **Gestión de Activos:** Inventario y control de todos los recursos tecnológicos.
* **Clasificación de la Información:** Definir qué datos son públicos, internos o confidenciales.
* **Control de Accesos:** Garantizar que cada usuario solo acceda a lo que necesita.
* **Seguridad en las Comunicaciones:** Protección de las redes y transferencia de datos.
* **Gestión de Incidentes:** Plan de respuesta ante ataques o fallas de seguridad.
* **Gestión de Vulnerabilidades:** Identificación y parcheo de debilidades en el sistema.
* **Seguridad en las Operaciones:** Controles para el mantenimiento diario de la tecnología.
* **Adquisición, Desarrollo y Mantenimiento de Sistemas:** Seguridad desde la creación de software.
* **Autenticación de Clientes:** Métodos para verificar la identidad de los usuarios externos.
* **Gestión de Riesgos:** Identificación y mitigación de amenazas potenciales.
* **Seguridad Física y Ambiental:** Protección de las instalaciones y servidores.
* **Cifrado de Datos:** Uso de criptografía para proteger información sensible.
* **Seguridad con Terceros:** Exigencias de seguridad para proveedores y aliados.
* **Uso Aceptable de Activos:** Normas sobre cómo deben usarse las herramientas de la empresa.

## 2. Estándares Técnicos

Los estándares son los requisitos técnicos específicos para que la tecnología esté correctamente configurada.

* **Gestión de Contraseñas:** Requerimientos de complejidad y rotación.
* **Servidores Dockers:** Endurecimiento (hardening) de contenedores y microservicios.
* **Recursos Criptográficos:** Estándares para el manejo de llaves y algoritmos.
* **Desarrollo Seguro:** Guías de codificación para evitar ataques como SQLi o XSS.
* **SI en Relación con Terceros:** Normas técnicas para integraciones externas.
* **Clasificación de la Información (Técnico):** Implementación de etiquetas y metadatos.
* **Logs de Sistemas y Apps:** Registro detallado de eventos para auditoría.
* **Seguridad para APIs:** Protección de las interfaces de conexión entre sistemas.
* **Seguridad para Aplicaciones Móviles:** Estándares específicos para el desarrollo de apps.
* **Configuración Segura:** Guías de *Hardening* para sistemas operativos y software.
* **Seguridad para OCI:** Controles específicos para Oracle Cloud Infrastructure.
* **Seguridad para Pipelines y DC:** Protección en el flujo de despliegue continuo y centros de datos.



## 3. Decisiones Estratégicas

Estas son las definiciones de alto nivel que guían la resiliencia y la protección de la organización.

* **Plan de Recuperación ante Desastres (DRP):** Estrategia integral para restaurar sistemas críticos y datos tras una interrupción mayor o catástrofe.
* **Seguridad de la Información (SI):** El marco de gobernanza que asegura la confidencialidad, integridad y disponibilidad de todos los activos de datos.

## 4. Procesos Operativos

Los pasos tácticos que el equipo debe seguir para mantener un entorno seguro y funcional.

* **Proceso de Atención de Incidentes:** Flujo de pasos para identificar, contener, erradicar y recuperarse de una brecha de seguridad o falla técnica.
* **Recepción de Servidores:** Protocolo formal para dar de alta equipo nuevo, asegurando que cumpla con los estándares de configuración segura antes de entrar a producción.
* **Solicitud de Cifrado de Datos:** Procedimiento para aplicar capas de protección criptográfica a información sensible, tanto en reposo como en tránsito.
* **Solicitud de Validación de Respaldos:** Proceso de prueba periódica para confirmar que las copias de seguridad son íntegras y pueden ser restauradas con éxito.
* **Solicitud de Respaldos:** Mecanismo formal para programar y ejecutar la copia de seguridad de datos críticos según la frecuencia necesaria.



## 5. Procesos de Seguridad de la Información (Continuación)

Estos son los flujos operativos adicionales extraídos de los estándares de la organización para garantizar un control total del entorno.

### Gestión de Evaluación y Riesgos

* **Evaluación de Seguridad:** Análisis técnico para determinar el nivel de protección de un activo o sistema.
* **Acompañamiento ISP:** Proceso de guía y soporte especializado en Seguridad de la Información para nuevos proyectos o servicios.
* **Evaluación de Riesgos:** Identificación y valoración de amenazas potenciales que podrían afectar la operación.
* **Revisión de Arquitectura de Seguridad:** Verificación de que el diseño de los sistemas cumpla con los lineamientos de protección desde su concepción.
* **Ejecución de Pentest:** Realización de pruebas de penetración (hackeo ético) para encontrar brechas antes de que un atacante lo haga.
* **Evaluación de Aseguramiento SI:** Auditoría para confirmar que los controles de seguridad están implementados y funcionando correctamente.

### Gestión de Vulnerabilidades y Respuesta

* **Gestión de Vulnerabilidades de SI:** Proceso continuo de identificación y priorización de debilidades tecnológicas.
* **Vulnerability Response:** Flujo de respuesta rápida para corregir o mitigar vulnerabilidades críticas detectadas.
* **Remediaciones de Riesgos de SI:** Ejecución de planes de acción específicos para eliminar o reducir riesgos previamente identificados.
* **Protección de Apps mediante WAF:** Configuración y monitoreo del Firewall de Aplicaciones Web para detener ataques dirigidos a sitios y servicios web.

### Relación con Terceros y Documentación

* **Conexiones Remotas con Terceros:** Protocolo seguro para permitir que proveedores externos accedan a la red interna de forma controlada.
* **Gestión de Seguridad con Terceros:** Supervisión de que los proveedores cumplan con los estándares de seguridad exigidos por la empresa.
* **Término de Servicio de los Terceros:** Proceso de salida que asegura la revocación de accesos y la devolución/borrado de información al finalizar un contrato.
* **Evaluación de Cumplimiento con Terceros:** Auditoría periódica a proveedores para validar que mantienen sus niveles de seguridad.
* **Gestión Documental:** Control y resguardo de todas las políticas, evidencias y registros legales de seguridad.

### Flexibilidad y Control

* **Excepción a la Política:** Trámite formal para documentar casos donde no es posible cumplir una norma, requiriendo aprobación y controles adicionales.
 
 

## 6. Contratos y Compromisos

Acuerdos legales y técnicos que garantizan el cumplimiento de los servicios de seguridad.

* **Contrato de Respaldos:** Documento que establece los niveles de servicio (SLA), la retención de datos y las responsabilidades del proveedor o equipo encargado de las copias de seguridad.
