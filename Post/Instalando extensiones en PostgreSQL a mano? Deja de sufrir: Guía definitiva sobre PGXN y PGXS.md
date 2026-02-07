

## 1. ¿Qué es PGXS? (PostgreSQL Extension Network Infrastructure)

**PGXS** no es un programa que descargas, sino un **marco de trabajo (framework)** que ya viene incluido en tu instalación de PostgreSQL.

### ¿Para qué sirve?

Sirve para que los desarrolladores de extensiones no tengan que preocuparse por dónde están instaladas las librerías de Postgres o qué banderas de compilación usar. Si quieres crear una extensión en C o C++, PGXS hace el trabajo sucio de compilación.

### ¿Cómo se usa?

Se invoca a través de un `Makefile`. Si ves un archivo que dice `USE_PGXS = 1`, significa que esa extensión utiliza esta infraestructura.

**El flujo típico es:**

1. Descargas el código fuente de una extensión.
2. Entras a la carpeta.
3. Ejecutas: `make` y luego `sudo make install`.
4. PGXS detecta automáticamente tus rutas de Postgres y coloca los archivos en su lugar.



## 2. ¿Qué es PGXN? (PostgreSQL Extension Network)

Si PGXS es la herramienta para construir, **PGXN** es el repositorio centralizado. Es el equivalente a **npm** para Node.js o **pip** para Python, pero para PostgreSQL.

### ¿Para qué sirve?

Para buscar, descargar e instalar extensiones que la comunidad ha creado (como `semver`, `pair`, o herramientas de auditoría) sin tener que buscarlas manualmente en GitHub.

### ¿Cómo se usa?

Para usarlo de forma sencilla, necesitas el **PGXN Client** (una herramienta de línea de comandos escrita en Python).

**Pasos para usarlo:**

1. **Instalas el cliente:** `pip install pgxnclient`
2. **Buscas una extensión:** `pgxn search temporal`
3. **Instalas la extensión:** `pgxn install extension_name`



## Diferencias clave: Cuadro Comparativo

| Concepto | **PGXS** | **PGXN** |
| --- | --- | --- |
| **Definición** | Infraestructura de compilación. | Red/Repositorio de extensiones. |
| **Función** | Ayuda a "compilar e instalar" el código. | Ayuda a "encontrar y descargar". |
| **¿Quién lo usa?** | Desarrolladores y administradores (vía `make`). | Usuarios que buscan funcionalidades extra. |
| **Ubicación** | Ya está en tu servidor (si tienes los *headers* de desarrollo). | Es un sitio web ([pgxn.org](https://pgxn.org)) y un cliente externo. |

 
## Entonces, ¿cómo los uso juntos?

Imagina que quieres la extensión `citext2`. El proceso moderno y profesional sería este:

1. Usas el cliente de **PGXN** para bajarla:
`pgxn download citext2`
2. El cliente de PGXN, tras bambalinas, utilizará **PGXS** para compilarla según tu versión específica de PostgreSQL.
3. Finalmente, entras a tu base de datos y activas la magia:
```sql
CREATE EXTENSION citext2;

```


> **Nota importante:** Para que todo esto funcione en Linux, necesitas tener instalado el paquete de desarrollo de Postgres (usualmente `postgresql-server-dev-all` o `postgresql-devel`).
 
 
En conclusión, para que no te vuelvas a liar con las siglas, piénsalo de esta manera:

* **PGXS es el "Manual de Instrucciones y Herramientas":** Es lo que permite que una extensión se compile correctamente en **tu** sistema operativo y con **tu** versión de Postgres. Sin él, tendrías que configurar rutas y librerías a mano cada vez que instales algo.
* **PGXN es la "Biblioteca o App Store":** Es el lugar donde reside el conocimiento colectivo de la comunidad. Es donde vas a buscar soluciones que otros ya escribieron para no tener que reinventar la rueda.

### El resumen operativo

Si eres un administrador de bases de datos (DBA) o desarrollador:

1. **Buscas** en **PGXN** (la red).
2. **Instalas** con el cliente de PGXN (que usa **PGXS** por debajo).
3. **Habilitas** en la base de datos con el comando SQL `CREATE EXTENSION`.

---

Para que lo veas cristalino, vamos a simular que necesitas instalar **`pair`**, una extensión muy popular en PostgreSQL que permite manejar tipos de datos en parejas (como llave-valor).

Aquí tienes el proceso real, paso a paso, donde ambos componentes entran en acción:

---

### Paso 1: Encontrar la extensión (El rol de PGXN)

No quieres programar la lógica de "pares" desde cero. Entras a [pgxn.org](https://pgxn.org) o usas la terminal para buscarla.

```bash
# Usando el cliente de PGXN para buscar
pgxn search pair

```

**Conclusión de este paso:** PGXN te dice: "Sí, la extensión existe y aquí está el código".

### Paso 2: Descargar y Compilar (El rol de PGXS)

Cuando ejecutas el comando de instalación, sucede la magia técnica. El cliente baja el código fuente y, como cada servidor es un mundo distinto (uno usa Ubuntu, otro RedHat, uno tiene Postgres 15, otro el 17), **PGXS** toma el control.

```bash
# Este comando descarga el código y activa PGXS para compilar
sudo pgxn install pair

```

**¿Qué está pasando "bajo el capó"?**

1. El instalador busca un archivo llamado `Makefile` en el código de la extensión.
2. Dentro de ese archivo, lee la línea `USE_PGXS = 1`.
3. Esto le dice al compilador: *"Oye, pregunta a `pg_config` dónde están las librerías de Postgres y compila este código específicamente para esta versión"*.

### Paso 3: Activación en la Base de Datos

Una vez que PGXS terminó de copiar los archivos compilados (`.so` o `.dll`) a las carpetas internas de PostgreSQL, la extensión ya está "disponible", pero no "activa".

Entras a tu consola de Postgres (`psql`) y ejecutas:

```sql
CREATE EXTENSION pair;

-- Ejemplo de uso real de la extensión instalada:
SELECT 'llave' ~> 'valor' AS mi_pareja;

```


### En resumen, si esto fuera un coche:

* **El código de la extensión** son las piezas del motor sueltas.
* **PGXN** es el concesionario donde pides las piezas.
* **PGXS** es el mecánico especializado que sabe exactamente en qué parte de **tu** coche va cada pieza y cómo apretar los tornillos para que encajen perfectamente.


---


la mejor forma de entender su valor: **el escenario "a pie" es una pesadilla de compatibilidad.**

Si decides ignorar PGXS y PGXN, te conviertes en un artesano que tiene que forjar sus propias herramientas antes de usarlas. Aquí tienes el ejemplo real de cómo sería instalar la extensión `fuzzystrmatch` (o cualquier otra externa) de forma manual.

 

### Escenario: Instalación "A Mano" (Sin PGXN ni PGXS)

Imagina que quieres una extensión que no viene preinstalada. Sin estas herramientas, tu tarde se vería así:

1. **Cacería del Código:** Tendrías que ir a GitHub o Bitbucket, buscar el repositorio, rezar para que sea la versión correcta para tu Postgres (ej. la v15 no siempre funciona igual que la v17) y descargar el `.zip` o clonar el repo.
2. **Configuración Manual del Compilador:** En lugar de que PGXS lo haga por ti, tendrías que escribir tú mismo el comando de compilación (GCC). Sería algo horrible como esto:
```bash
gcc -Wall -O2 -fPIC -I/usr/include/postgresql/15/server -c mi_extension.c
gcc -shared -o mi_extension.so mi_extension.o -L/usr/lib/postgresql/15/lib

```


*Si te equivocas en una sola ruta de las carpetas `-I` (Include) o `-L` (Library), la compilación falla.*
3. **Localización de Carpetas "A Ojo":** Tendrías que buscar manualmente dónde guarda tu sistema los archivos `.control` y `.sql`.
* ¿Están en `/usr/share/postgresql/...`?
* ¿O en `/var/lib/...`?
* Si los pones en la carpeta equivocada, Postgres jamás verá la extensión.


4. **Permisos y Dependencias:** Tendrías que verificar a mano si te faltan librerías del sistema (como `libxml2` o `openssl`) que la extensión necesita.


### ¿Por qué NO querrías hacerlo así? (Los riesgos)

* **El "Infierno de las Versiones":** Si actualizas PostgreSQL de la versión 15 a la 16, tu extensión compilada a mano probablemente deje de funcionar o corrompa datos porque las rutas internas cambiaron.
* **Inconsistencia:** Si tienes un cluster de 3 nodos, tendrías que repetir este proceso artesanal en cada uno, arriesgándote a que uno quede ligeramente diferente al otro.
* **Fuga de memoria:** PGXS incluye banderas de seguridad y optimización que los desarrolladores de Postgres han perfeccionado por décadas. Si compilas "a lo bruto", podrías crear una extensión que tire abajo todo el servidor por un mal manejo de memoria.


### La analogía para tu post:

> **Hacerlo con PGXN/PGXS:** Es como pedir un mueble de IKEA. Viene con las piezas exactas, los tornillos que encajan y un manual que dice dónde va cada cosa. Solo tienes que ensamblar.
> **Hacerlo SIN ellos:** Es como ir al bosque, talar un árbol, secar la madera, adivinar las medidas de los tornillos y esperar que cuando te sientes, la silla no se rompa.


### ¿Cuándo alguien NO usa PGXS?

Solo en casos extremadamente raros:

1. **Sistemas Embebidos:** Donde el espacio es tan crítico que no puedes tener ni una librería de más.
2. **Desarrollo de Core:** Si estás modificando el código fuente interno de PostgreSQL mismo.
3. **Entornos ultra-restringidos:** Donde no tienes permiso de instalar Python (para el cliente PGXN) ni herramientas de compilación, aunque en ese caso, ¡ni siquiera podrías instalar la extensión de ninguna forma!


---



# Ejemplos instalando 



**pgBackRest** es el "estándar de oro" para backups en Postgres, pero tiene una particularidad: **no es una extensión común**, es un binario independiente que interactúa con el núcleo de Postgres.

proceso **artesanal y rudo** de instalarlo desde el código fuente, sin usar `apt` o `yum`. Esto es "Postgres para hombres y mujeres de hierro".


### 1. El escenario: ¿Por qué hacerlo así?

Imagina que estás en un entorno corporativo ultra seguro donde no hay internet y no puedes usar repositorios oficiales. Solo tienes el código fuente en un USB. Aquí es donde mueren los novatos y nacen los expertos.

### 2. Las dependencias (El trabajo sucio previo)

Antes de tocar `pgBackRest`, necesitas las librerías de desarrollo. Sin ellas, el compilador no sabrá cómo hablar con XML, compresión o cifrado.

```bash
# Instalando las "piezas" del motor manualmente
sudo apt-get install make gcc libssl-dev libxml2-dev libz-dev liblz4-dev libzstd-dev libbz2-dev postgresql-server-dev-all

```

### 3. La Compilación Artesanal (El "Make")

Entras a la carpeta del código fuente de pgBackRest. Aquí no hay `CREATE EXTENSION`, aquí hay **C puro**.

```bash
cd /descargas/pgbackrest-release-2.50/src

# El comando sagrado
./configure
make

```

**¿Qué pasó ahí?**

* **`./configure`**: Es un script que escanea tu sistema. Revisa si tienes el compilador `gcc`, si las librerías de Postgres están donde deben y si tu procesador es compatible.
* **`make`**: Toma miles de líneas de código en C y las convierte en un **binario ejecutable**. Aquí es donde el ventilador de tu laptop empieza a sonar.

### 4. La Instalación Manual (Sin instaladores mágicos)

Ahora tienes el archivo ejecutable, pero está en una carpeta de descargas. Tienes que moverlo al sistema y darle permisos de "ejecución".

```bash
# Mover el binario al camino de ejecución del sistema
sudo cp pgbackrest /usr/bin/pgbackrest

# Darle permisos para que solo el admin lo use
sudo chmod 755 /usr/bin/pgbackrest

```

### 5. La conexión con Postgres (Donde entra PGXS mentalmente)

Aunque pgBackRest es un programa aparte, necesita saber dónde están las librerías de Postgres para leer los archivos WAL (Write Ahead Log).

Si estuvieras haciendo una extensión que viviera *dentro* de Postgres, aquí usarías `PGXS` para que el código se "pegara" al motor. En el caso de pgBackRest, lo que haces es configurar el `postgresql.conf` para que use este binario que acabas de fabricar:

```ini
# En el corazón de tu Postgres
archive_command = 'pgbackrest --stanza=demo archive-push %p'
archive_mode = on

```

 
### ¿Por qué este ejemplo es perfecto para tu post?

Porque demuestra la diferencia de niveles:

1. **Nivel Junior:** `apt-get install pgbackrest` (Fácil, pero no entiendes qué pasa).
2. **Nivel Pro (PGXN):** Buscas la herramienta, la bajas y dejas que el ecosistema gestione la compatibilidad.
3. **Nivel Experto (Artesanal):** Entiendes que `make` usa los recursos del sistema y los headers de Postgres (`postgresql-server-dev`) para crear una herramienta que encaje perfectamente con tu base de datos.

### Título Sugerido para el Post:

> **"¿Compilar pgBackRest desde cero? Un viaje al corazón de C y los binarios de PostgreSQL."**
 

### La conclusión "técnica" para tu audiencia:

Instalar artesanalmente no es solo "copiar archivos", es **asegurar que el software sea nativo a tu hardware**. PGXS y PGXN existen para que no tengas que ser un experto en compiladores cada vez que quieras un backup decente.
