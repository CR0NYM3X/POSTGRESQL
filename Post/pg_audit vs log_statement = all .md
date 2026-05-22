# `pg_audit` vs `log_statement = all`

Configurar `log_statement = 'all'` parece la solución definitiva: "Si guardo absolutamente todo lo que pasa, estoy cubierto, ¿no?". La respuesta corta es **no**. Desde una perspectiva de seguridad estricta y cumplimiento normativo, `log_statement = 'all'` es un riesgo y una pesadilla de auditoría, mientras que `pgaudit` es una herramienta quirúrgica diseñada específicamente para este propósito.

Aquí tienes el análisis técnico, normativo y práctico de **cuándo sí y cuándo no** usar cada uno, con sus respectivos fundamentos.

---

## El gran problema de `log_statement = 'all'`

Para entender por qué necesitas `pgaudit`, primero debemos ver las carencias críticas de la bitácora estándar de PostgreSQL cuando se satura al máximo.

### 1. El peligro de los Datos Sensibles (Exposición de PII/PCI)

Cuando usas `log_statement = 'all'`, PostgreSQL escribe en texto plano **todo** lo que recibe. Si un usuario ejecuta:

```sql
INSERT INTO usuarios (usuario, password, tarjeta_credito) 
VALUES ('juan_perez', 'ClaveUltraSecreta123', '4111222233334444');

```

Esa línea exacta, con la contraseña y la tarjeta, quedará grabada en los archivos de log del servidor.

* **Fundamento Técnico:** El log estándar no tiene capacidad de sanitización ni de disociación de datos. Cualquier administrador del sistema operativo con acceso a los logs puede ver datos críticos.
* **Fundamento Normativo/Legal:** Esto viola flagrantemente normativas como **PCI-DSS** (requisito 3.4 y 10), **GDPR / LFPDPPP** (protección de datos personales), ya que estás almacenando datos sensibles sin cifrar y sin control de acceso estricto en archivos de texto.

### 2. Falta de Contexto y Estructura en la Auditoría

Si una consulta se ejecuta dentro de una función almacenada (PL/pgSQL), `log_statement` solo registrará la llamada a la función (ej. `SELECT procesar_nomina();`), pero **no qué hizo la función por dentro**. No sabrás si modificó la tabla de salarios o si borró un registro.

---

## Por qué `pgaudit` SÍ es la solución (Fundamentos Técnicos)

`pgaudit` (PostgreSQL Audit Extension) no es solo un recolector de texto; es un framework de auditoría oficial que interactúa con el backend de PostgreSQL a nivel de ejecución.

* **Auditoría de Objetos (Object Audit):** Puedes decirle a `pgaudit` que audite *únicamente* los accesos a una tabla específica (ej. la tabla `clientes_vip` o `nominas`), sin importar quién la consulte. `log_statement` es de "todo o nada".
* **Auditoría de Funciones Internas:** `pgaudit` desglosa la ejecución dentro de funciones y procedimientos. Si `procesar_nomina()` toca la tabla de salarios, `pgaudit` lo registrará con precisión.
* **Separación de Funciones (Separation of Duties - SoD):** Permite estructurar los logs en un formato específico (`AUDIT: SESSION`, `AUDIT: OBJECT`) que los sistemas SIEM (como Splunk o Elastic) pueden parsear fácilmente. Además, el auditor puede definir qué se audita sin que el desarrollador pueda saltarse esa regla cambiando los parámetros de su sesión.

---

## Cuándo SÍ instalar `pgaudit`

Debes instalar y configurar `pgaudit` si te encuentras en cualquiera de estos escenarios:

1. **Cumplimiento Regulatorio Obligatorio:** Si tu base de datos procesa datos financieros (SOX, PCI-DSS), datos de salud (HIPAA) o datos personales (GDPR, LFPDPPP en México). Estas normas exigen un rastro de auditoría **inalterable, específico y que no exponga credenciales**.
2. **Principio de Privacidad por Diseño:** Cuando necesitas auditar que los administradores (superusuarios/`postgres`) no estén curioseando tablas con datos sensibles (salarios, secretos comerciales), restringiendo el log a solo esas acciones.
3. **Optimización de Recursos y SIEM:** Cuando enviar *todo* el tráfico de la base de datos a un SIEM es inviable económicamente o por rendimiento de red. `pgaudit` te permite enviar solo los eventos de seguridad relevantes (ej. `DDL`, `ROLE`, `WRITE`).

---

## Cuándo NO instalar `pgaudit` (O cuándo no es prioridad)

A pesar de sus bondades, no siempre es necesario:

1. **Ambientes de Desarrollo o Testing Local:** No aporta valor y consume recursos de CPU y almacenamiento innecesarios. Para depurar código de desarrollo, `log_statement = 'all'` o `log_min_duration_statement` son mucho más útiles.
2. **Bases de Datos de Solo Lectura o Almacenes de Datos (Data Warehouses) Públicos:** Si los datos son públicos o estadísticos y no contienen información regulada ni crítica, el costo de mantener la extensión no se justifica.
3. **Sistemas con Restricciones Extremas de CPU/I/O:** `pgaudit` añade un pequeño *overhead* (sobrecarga) porque analiza cada objeto antes de escribir. Si tu servidor ya está al 99% de capacidad de disco o CPU, añadir auditoría detallada podría colapsarlo. Primero se debe corregir la infraestructura.

---

## Resumen Comparativo

| Característica | `log_statement = 'all'` | `pgaudit` |
| --- | --- | --- |
| **Propósito Principal** | Depuración (Debugging) y Troubleshooting técnico. | Cumplimiento legal, seguridad y auditoría forense. |
| **Granularidad** | Global o por sesión (Todo o nada). | Fina (Por tabla, por tipo de comando, por rol). |
| **Seguridad de Datos** | **Mala.** Expone contraseñas y PII en texto plano. | **Buena.** Permite evitar auditorías de statements con data sensible si se parametriza correctamente. |
| **Interior de Funciones** | No ve lo que pasa dentro de un PL/pgSQL. | Sí registra las consultas internas de las funciones. |
| **Formato de Log** | Texto plano genérico de Postgres. | Formato estructurado CSV/Syslog ideal para SIEM. |

> ⚠️ **Nota de Seguridad Crítica:** Ninguna de las dos opciones sirve si el archivo de log se guarda en el mismo disco de la base de datos y el usuario `postgres` puede borrarlo. Para que cualquiera de las dos opciones tenga validez legal ante un peritaje, los logs deben ser redirigidos inmediatamente (vía `rsyslog` o agentes) a un servidor de logs centralizado y de **solo lectura**.

**En conclusión:** Mantener `log_statement = 'all'` en producción es un riesgo de seguridad disfrazado de medida de seguridad. Si tienes auditorías normativas encima, **`pgaudit` es el camino correcto.**
