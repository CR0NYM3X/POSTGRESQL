
## 🛠️ ¿Qué es pgloader?

**pgloader** es una herramienta **open source** diseñada para migrar datos desde múltiples fuentes hacia PostgreSQL. Soporta motores como:

- **MySQL**
- **SQLite**
- **Microsoft SQL Server**
- **CSV, DBF, IXF, archivos ZIP/TAR/GZ**
- **Otros PostgreSQL**

Utiliza el protocolo `COPY` de PostgreSQL para una carga rápida y eficiente [1](https://pgloader.readthedocs.io/en/latest/index.html).

---

## ✅ ¿Qué puede migrar pgloader?

- **Esquemas**: tablas, columnas, tipos de datos, índices, claves primarias y foráneas.
- **Datos**: registros completos, con transformaciones en tiempo real.
- **Tipos de datos**: realiza conversiones automáticas entre tipos incompatibles.
- **Secuencias e índices**: puede recrearlos en el destino.
- **Transformaciones**: permite modificar datos al vuelo (casting, limpieza, proyecciones).
- **Carga paralela**: mejora el rendimiento en migraciones grandes.

---

## ⚠️ Limitaciones y consideraciones antes de migrar

### 1. **Compatibilidad de tipos de datos**
- Algunas conversiones pueden fallar si los tipos no son compatibles.
- Es posible definir reglas de casting personalizadas en el archivo de configuración.

### 2. **Longitud de nombres**
- PostgreSQL tiene un límite de 63 caracteres para nombres de objetos (tablas, columnas, etc.).
- pgloader puede truncar nombres largos automáticamente, lo que puede causar conflictos [2](https://www.percona.com/blog/migrating-from-mysql-to-postgresql-using-pgloader/).

### 3. **Dependencias y relaciones**
- Las relaciones complejas entre tablas deben estar bien definidas.
- pgloader puede tener problemas si hay claves foráneas circulares o mal estructuradas.

### 4. **Migración de funciones, procedimientos y triggers**
- **No migra funciones ni procedimientos almacenados** automáticamente.
- Estos deben migrarse manualmente y adaptarse a PL/pgSQL si vienen de otro motor.

### 5. **Vistas y materializadas**
- Las vistas pueden migrarse como estructuras, pero no siempre se migran con lógica completa.
- Las vistas materializadas deben refrescarse manualmente en PostgreSQL.

### 6. **Extensiones y objetos especiales**
- No migra extensiones específicas del origen (como funciones de Oracle o SQL Server).
- Debes revisar si hay objetos no compatibles con PostgreSQL.

### 7. **Errores y registros**
- pgloader genera archivos `reject.dat` y `reject.log` para registrar errores de carga.
- Es importante revisarlos después de la migración para validar integridad.

---

## 🧪 Recomendaciones antes de usar pgloader

1. **Audita tu base de datos origen**: identifica tipos de datos, relaciones, funciones y vistas.
2. **Define reglas de casting** si hay tipos personalizados.
3. **Haz pruebas con bases pequeñas** antes de migrar entornos grandes.
4. **Revisa nombres largos** y objetos especiales.
5. **Valida la integridad post-migración** con scripts de comparación.
6. **Documenta todo el proceso** para futuras migraciones o auditorías.
