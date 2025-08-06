## 🕵️‍♂️ 2. Anonimización

### ¿Qué es?
Proceso de **reemplazar , eliminar o transformar** los datos  de forma **irreversible**, para que no se pueda identificar al individuo.

### ¿Para qué sirve?
- Para cumplir con leyes de privacidad.
- Para análisis estadísticos sin comprometer la identidad.

### Casos de uso reales:
- Instituciones de salud eliminan nombres y CURP para estudios clínicos.
- Plataformas de datos anonimizan logs de usuarios.
- Gobiernos publican datos abiertos sin identificadores personales.

### Cumplimientos:
- ✅ **GDPR**: Recomendado.
- ✅ **HIPAA**: Recomendado.
- ✅ **LGPD**: Recomendado.
- ✅ **PCI DSS**: Aceptado si se elimina el vínculo con el titular.

### Ventajas:
- Elimina el riesgo legal.
- Ideal para compartir datos con terceros.
- Cumple con normativas de privacidad.

### Desventajas:
- No reversible.
- Puede afectar la utilidad del dato.
- No sirve en producción si se necesita el dato original.

### Ejemplos:
- **Número de tarjeta**: `4111111111111111` → `XXXXXXXXXXXX1111`  
- **Correo electrónico**: `ana.martinez@email.com` → `usuario001@anon.com`  
- **CURP**: `MARA800101HDFRNN09` → `NULL` o `anon_001`

🔸 *Observación*: El dato se transforma o elimina de forma irreversible. No se puede recuperar el original.
