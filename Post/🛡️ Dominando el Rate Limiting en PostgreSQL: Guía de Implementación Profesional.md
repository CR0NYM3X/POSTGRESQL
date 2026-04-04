 
# 🛡️ Dominando el Rate Limiting en PostgreSQL: Guía de Implementación Profesional

El **Rate Limiting** (limitación de tasa) es la primera línea de defensa contra ataques de fuerza bruta, scraping abusivo y denegación de servicio (DoS). Aunque solemos delegarlo a capas externas (como Nginx o Redis), implementarlo **dentro de PostgreSQL** ofrece una integridad de datos superior y una protección "nativa" que ningún bypass de aplicación puede saltar.
 
---

### 🚀 Puntos Clave
* **Centralización:** Una única fuente de verdad para todos tus microservicios.
* **Atomicidad:** Uso de Bloqueos Consultivos (`Advisory Locks`) para evitar condiciones de carrera.
* **Eficiencia:** Implementación en memoria mediante hashes para minimizar el impacto en el disco.
* **Escalabilidad:** Estrategia de limpieza automática de registros obsoletos.

---

### 🧪 Laboratorio Práctico: Implementación Paso a Paso

#### 1. La Infraestructura de Datos
Primero, creamos una tabla optimizada para almacenar los contadores. Usaremos un `TEXT` como llave para permitir flexibilidad (IDs de usuario, IPs o tokens de API).

```sql
CREATE TABLE auth_rate_limits (
    key           TEXT PRIMARY KEY,
    peticiones    INTEGER NOT NULL DEFAULT 0,
    inicio_ventana TIMESTAMPTZ NOT NULL
);

-- Índice para acelerar la limpieza de datos antiguos
CREATE INDEX idx_rate_limit_expiry ON auth_rate_limits (inicio_ventana);
```

#### 2. La Lógica "Upsert" Inteligente
El corazón del sistema es una consulta que decide si incrementa el contador existente o reinicia la ventana de tiempo si esta ya expiró.

```sql
-- Lógica Conceptual:
-- SI (ahora - inicio_ventana) > intervalo ENTONCES reiniciar a 1
-- SINO incrementar contador
```

#### 3. El Guardián: Función `check_rate_limit` profesional
Esta función utiliza un **Advisory Lock transaccional**. Esto bloquea el "ID" del usuario en la memoria de Postgres, permitiendo que miles de usuarios operen en paralelo, pero asegurando que un mismo usuario no pueda enviar 100 peticiones en el mismo milisegundo para burlar el contador.

```sql
CREATE OR REPLACE FUNCTION sp_seguridad_rate_limit(
    p_key TEXT, 
    p_limite INTEGER, 
    p_segundos INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_ahora TIMESTAMPTZ := clock_timestamp();
    v_intervalo INTERVAL := (p_segundos || ' seconds')::INTERVAL;
    v_conteo_actual INTEGER;
BEGIN
    -- [CRÍTICO] Bloqueo consultivo basado en el hash del ID
    -- Evita que dos procesos modifiquen al mismo usuario a la vez
    PERFORM pg_advisory_xact_lock(hashtext(p_key));

    INSERT INTO auth_rate_limits (key, peticiones, inicio_ventana)
    VALUES (p_key, 1, v_ahora)
    ON CONFLICT (key) DO UPDATE SET
        peticiones = CASE 
            WHEN auth_rate_limits.inicio_ventana + v_intervalo <= v_ahora THEN 1 
            ELSE auth_rate_limits.peticiones + 1 
        END,
        inicio_ventana = CASE 
            WHEN auth_rate_limits.inicio_ventana + v_intervalo <= v_ahora THEN v_ahora 
            ELSE auth_rate_limits.inicio_ventana 
        END
    RETURNING peticiones INTO v_conteo_actual;

    -- Si excede el límite, lanzamos una excepción o devolvemos false
    IF v_conteo_actual > p_limite THEN
        RETURN FALSE; 
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

---

### 💼 Casos de Uso del Mundo Real

1.  **Protección de Login (Fuerza Bruta):**
    `SELECT sp_seguridad_rate_limit('login_user_45', 5, 300);`
    *(Permite 5 intentos cada 5 minutos)*.
2.  **API Freemium:**
    `SELECT sp_seguridad_rate_limit('api_key_abc', 1000, 3600);`
    *(Limita a 1000 llamadas por hora)*.
3.  **Prevención de Spam en Comentarios:**
    `SELECT sp_seguridad_rate_limit('ip_192.168.1.1', 1, 10);`
    *(Solo 1 comentario cada 10 segundos por IP)*.

---

### ⚠️ Notas y Consideraciones de Seguridad

* **Condiciones de Carrera:** Sin `pg_advisory_xact_lock`, un atacante con una botnet podría enviar peticiones simultáneas que lean el mismo valor del contador antes de que se actualice, logrando "saltarse" el límite.
* **Limpieza (Maintenance):** Esta tabla crecerá con cada nuevo usuario. Es vital ejecutar un `DELETE` de registros antiguos cada 24 horas para mantener el rendimiento.
* **Reloj del Servidor:** La función usa `clock_timestamp()` en lugar de `now()`, ya que `now()` devuelve la hora de inicio de la transacción y no cambia durante la ejecución, lo que podría dar errores de precisión en milisegundos.

---

### 💡 Tips Pro de Configuración

1.  **¿Excepción o Booleano?:** En el ejemplo devolvemos `BOOLEAN`. Si quieres que la base de datos detenga la ejecución inmediatamente, usa `RAISE EXCEPTION 'Too many requests'`.
2.  **Particionamiento:** Si tienes millones de usuarios, particiona la tabla `auth_rate_limits` por rango de tiempo para que borrar datos viejos sea instantáneo.
3.  **Usa Hashes:** Para IDs de usuario muy largos, usa `MD5(key)` para mantener la tabla ligera.

 
###  Bibliografía y Referencias
```
https://neon.com/guides/rate-limiting
```
