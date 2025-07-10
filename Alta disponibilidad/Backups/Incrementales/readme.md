.
**PostgreSQL 17**, ya existe **soporte nativo para respaldos incrementales**


## 🆕 ¿Qué cambia en PostgreSQL 17?

### ✅ **Respaldo incremental nativo**
Antes, para hacer respaldos incrementales o diferenciales, necesitabas herramientas externas como **pgBackRest** o **Barman**.  
Ahora, **PostgreSQL 17** permite hacer **respaldos incrementales directamente con `pg_basebackup`**, gracias a nuevas funcionalidades integradas .

---

## 🔧 ¿Cómo funciona?

1. **Primero haces un respaldo completo** con `pg_basebackup`.
2. Luego, puedes hacer respaldos incrementales que solo copian los **cambios desde el último respaldo** (ya sea completo o incremental).
3. Se usa un nuevo parámetro:  
   ```bash
   pg_basebackup --incremental=PATH_TO_MANIFEST
   ```
4. También se puede usar la herramienta nueva `pg_combinebackup` para **reconstruir el respaldo completo** a partir del respaldo base + incrementales.

---

## 📌 Requisitos

- PostgreSQL 17.
- Activar el parámetro `summarize_wal = on` en `postgresql.conf`.
- No se puede usar si `wal_level = minimal`.

---

## 🧠 ¿Qué beneficios trae?

- **Menor uso de espacio**: solo se respaldan los archivos modificados.
- **Más rápido**: ideal para respaldos frecuentes.
- **Integración nativa**: sin necesidad de herramientas externas.
