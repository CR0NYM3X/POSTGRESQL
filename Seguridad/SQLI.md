# SQLi

 La inyección de SQL (SQLi) sigue siendo una de las vulnerabilidades más críticas porque ataca directamente el activo más valioso de una organización: la **información**.

No existe una "bala de plata", sino una estrategia de **defensa en profundidad**. Para detectar y mitigar estos ataques de manera efectiva, debemos mirar el flujo de datos desde que entran por la web hasta que llegan al motor de la base de datos.

Aquí tienes las soluciones más robustas categorizadas por capas:


## 1. Capa de Perímetro: Web Application Firewall (WAF)

El WAF es la primera línea de defensa. Actúa como un proxy que inspecciona el tráfico HTTP/S antes de que llegue a tu servidor de aplicaciones.

* **Cómo detecta SQLi:** Utiliza firmas basadas en patrones conocidos (ej. `OR 1=1`, `--`, `; DROP TABLE`) y análisis de anomalías.
* **Soluciones recomendadas:**
* **Cloudflare WAF / AWS WAF:** Ideales para entornos de nube, con reglas preconfiguradas que se actualizan globalmente ante nuevas amenazas.
* **ModSecurity (Open Source):** Excelente para implementaciones "on-premise" usando el Core Rule Set (CRS) de OWASP.


 

## 2. Capa de Aplicación: RASP (Runtime Application Self-Protection)

A diferencia del WAF, el RASP reside **dentro** de la aplicación. Es una tecnología más moderna y precisa para 2026.

* **Cómo detecta SQLi:** Monitoriza las llamadas internas de la aplicación. Si el código intenta ejecutar una consulta SQL cuya estructura cambió drásticamente debido a un input de usuario, el RASP la bloquea en tiempo de ejecución.
* **Ventaja:** Tiene un índice de falsos positivos mucho menor que el WAF porque entiende el contexto de la aplicación.
* **Soluciones recomendadas:** **Contrast Security**, **Imperva RASP** o **OpenRASP**.
 
## 3. Capa de Base de Datos: Database Activity Monitoring (DAM)

Como arquitecto de bases de datos, esta es la herramienta que te da visibilidad total sobre qué está pasando en el motor (SQL Server, PostgreSQL, Oracle, etc.).

* **Cómo detecta SQLi:** Analiza el tráfico de red hacia la base de datos o examina los logs de auditoría en tiempo real.
* **Detección por comportamiento:** Si un usuario que normalmente consulta 10 registros de repente intenta extraer 1,000,000 mediante una inyección, el DAM dispara una alerta.
* **Soluciones recomendadas:** **IBM Security Guardium** o **Imperva Data Security**.

 
## 4. Análisis de Logs y SIEM (Detección Post-Evento)

Si buscas una solución que centralice la detección, necesitas un SIEM (Security Information and Event Management) potenciado con IA.

* **Estrategia:** Centralizar los logs del servidor web (404s extraños, errores de sintaxis SQL) y los logs de la base de datos.
* **Análisis de Anomalías:** Para 2026, herramientas como **Splunk** o **Microsoft Sentinel** utilizan modelos de Machine Learning para detectar variaciones en la estructura de las queries habituales.

 

### Comparativa de Soluciones

| Solución | Ubicación | Precisión | Dificultad de Implementación |
| --- | --- | --- | --- |
| **WAF** | Perímetro (Red) | Media | Baja |
| **RASP** | Runtime (Código) | Muy Alta | Media |
| **DAM** | Base de Datos | Alta | Alta |
| **SIEM** | Centralizado | Alta (Contextual) | Alta |

 

### Mi recomendación técnica como arquitecto

Para una solución integral y moderna, te sugiero implementar un enfoque híbrido:

1. **Prevención (Hardening):** Asegúrate de que tus desarrolladores usen **Consultas Parametrizadas (Prepared Statements)**. Esto elimina el 99% del riesgo de raíz.
2. **Detección Activa:** Implementa un **WAF** en la nube para ataques volumétricos y escaneos automatizados.
3. **Visibilidad Crítica:** Implementa un **DAM** o habilita auditoría detallada en tus bases de datos, enviando los logs a un SIEM para detectar intentos de exfiltración que el WAF pudo haber omitido.

> **Nota de experto:** Los ataques de SQLi modernos suelen ser "ciegos" (Blind SQLi) o basados en tiempo. No siempre verás un error en pantalla, por lo que monitorizar el **tiempo de respuesta de las queries** en el DAM es fundamental.


---

---

# Enfoque 100% **Open Source

Para un enfoque 100% **Open Source** en 2026, la clave no es solo "bloquear", sino tener visibilidad en cada etapa del ataque. Como arquitecto, te recomiendo una pila tecnológica que cubra desde el borde hasta el motor de la base de datos, aprovechando que las herramientas de código abierto han evolucionado mucho en su capacidad de análisis gramatical.

Aquí tienes las soluciones líderes y cómo integrarlas:



## 1. La Nueva Frontera del WAF: **Coraza WAF**

Olvida el viejo ModSecurity; en 2026, el estándar de oro para WAFs open-source es **Coraza**. Es un motor escrito en Go, mucho más rápido y moderno.

* **Por qué es mejor:** Soporta el **OWASP Core Rule Set (CRS) v4**, que tiene reglas específicas y refinadas para detectar inyecciones SQL complejas (incluyendo *blind SQLi* y *time-based*).
* **Integración:** Puedes usarlo como un plugin para NGINX, HAProxy o incluso embebido en aplicaciones Go.
* **Detección:** Utiliza la librería `libinjection`, que en lugar de usar simples expresiones regulares (regex), analiza la **gramática del SQL** para identificar tokens maliciosos.



## 2. Protección en el Corazón: **OpenRASP**

Si quieres una detección con casi cero falsos positivos, necesitas un **RASP (Runtime Application Self-Protection)**.

* **Herramienta:** **OpenRASP** (un proyecto de código abierto muy robusto).
* **Cómo funciona:** Se instala como un agente en el servidor de aplicaciones (Java, PHP, Python, Node.js). En lugar de mirar el tráfico de red, intercepta la llamada final que la aplicación hace a la base de datos.
* **La ventaja del arquitecto:** Si la aplicación recibe un input y este altera la estructura lógica de la query original, OpenRASP lo detecta en el último milisegundo y bloquea la ejecución. Es "inmune" a la ofuscación de red que engaña a los WAFs.



## 3. Capa de Base de Datos: **ProxySQL & Audit Plugins**

Desde la perspectiva de arquitectura de datos, no podemos confiar solo en lo que viene de afuera. Necesitamos control en el punto de entrada al motor.

* **ProxySQL (para MySQL/MariaDB):** Es un proxy de alto rendimiento que permite definir reglas de filtrado de queries. Puedes crear una "lista blanca" de patrones de queries permitidos y bloquear cualquier cosa que no encaje.
* **pgAudit (para PostgreSQL):** Si usas Postgres, este plugin es esencial. Proporciona una auditoría detallada de las sesiones y/o objetos. Al integrarlo con un analizador de logs, puedes detectar inyecciones que intentan acceder a tablas de sistema (`information_schema`, `pg_catalog`).



## 4. Centralización e Inteligencia: **Wazuh + ELK Stack**

Para detectar ataques que ocurren de forma lenta y distribuida, necesitas correlación de eventos.

* **Wazuh:** Es una plataforma de seguridad (XDR/SIEM) open source. Sus agentes pueden monitorizar los logs de tu servidor web y de tu base de datos simultáneamente.
* **Detección de anomalías:** Wazuh puede alertarte si detecta múltiples errores `403` o errores de sintaxis SQL en los logs del servidor en un corto periodo de tiempo, lo cual es señal clara de un atacante usando herramientas automatizadas como **sqlmap**.



### Comparativa de Herramientas Open Source

| Capa | Herramienta | Función Principal | Dificultad |
|  |  |  |  |
| **Borde / Red** | **Coraza WAF** | Bloqueo perimetral basado en gramática. | Media |
| **Aplicación** | **OpenRASP** | Detección interna en tiempo de ejecución. | Alta |
| **Proxy DB** | **ProxySQL** | Firewall de base de datos y balanceo. | Media |
| **Análisis** | **Wazuh** | Correlación de logs y detección de ataques. | Alta |



### Mi Recomendación de Arquitectura "Proactiva"

Como experto, mi consejo es que no solo detectes, sino que pruebes tu propia defensa. Utiliza **SQLMap** (la herramienta open source de prueba de penetración por excelencia) contra un entorno de *staging* donde tengas implementado Coraza y OpenRASP.

> **Tip de Oro:** La mayoría de los ataques SQLi exitosos en 2026 ya no usan `' OR 1=1`. Utilizan técnicas de **JSON Injection** dentro de campos SQL o **Inyecciones de Segundo Orden**. Asegúrate de que tu WAF esté configurado para inspeccionar cuerpos JSON.

 
