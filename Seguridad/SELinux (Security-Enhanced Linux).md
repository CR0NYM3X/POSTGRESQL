# **SELinux (Security-Enhanced Linux)**

Estamos acostumbrados a pensar que `root` es Dios, pero SELinux introduce una "constitución" a la que incluso Dios debe someterse.

Aquí tienes el desglose semántico de cómo funciona esta bestia.

 

## 1. DAC vs. MAC: El cambio de paradigma

Para entender por qué el `root` muerde el polvo con SELinux, hay que diferenciar dos conceptos:

* **DAC (Discretionary Access Control):** Es el estándar tradicional de Linux. Si eres el dueño de un archivo o eres `root`, decides quién entra. El control es "discrecional".
* **MAC (Mandatory Access Control):** Es lo que implementa SELinux. Aquí, la política de seguridad la define el administrador del sistema (o el desarrollador de la política) y se aplica a **todos**. No importa quién seas; si la política dice "no", es "no".


## 2. La Semántica: Sujetos, Objetos y Contextos

SELinux no mira nombres de usuario ni permisos `rwx` clásicos. Mira **etiquetas** (labels). Todo en el sistema tiene un contexto de seguridad (visto con `ls -Z` o `ps -Z`):

`usuario:rol:tipo:nivel`

1. **Sujetos:** Normalmente un proceso (ej. `httpd`).
2. **Objetos:** Un archivo, un puerto, un socket, un directorio (ej. `/var/www/html/index.html`).
3. **Acción:** Lo que el sujeto quiere hacer con el objeto (leer, escribir, ejecutar, bind).

La semántica básica es: **"El sujeto S puede realizar la acción A sobre el objeto O si existe una regla que lo permita explícitamente".** Si no hay regla, por defecto está prohibido.


## 3. ¿Cómo es posible que restrinja al usuario Root?

Aquí está el truco de magia. En un Linux tradicional, el kernel verifica el **UID (User ID)**. Si el UID es `0`, el kernel dice: "Pase usted, don Root".

Con SELinux activo, el flujo de una petición al kernel cambia radicalmente:

1. El proceso (siendo `root`) solicita abrir un archivo.
2. El kernel hace la comprobación **DAC** tradicional. Como es `root`, la pasa.
3. **El Gancho (Hook) de LSM:** Antes de conceder el acceso, el kernel consulta al subsistema **LSM (Linux Security Modules)**, donde vive SELinux.
4. SELinux consulta su **Policy Enforcement Server** y su caché (AVC - Access Vector Cache).
5. Si la política dice que el contexto del proceso `httpd_t` no puede leer archivos etiquetados como `user_home_t`, SELinux devuelve **"Permission Denied"**, aunque el proceso sea `root`.

> **Nota clave:** SELinux opera a un nivel más profundo que la lógica de usuarios. Se inserta en las llamadas al sistema (syscalls) del kernel. Para SELinux, `root` es solo otro contexto de seguridad que debe obedecer las reglas de tipos (Type Enforcement).


## 4. El pilar: Type Enforcement (TE)

Esta es la parte más importante. SELinux se basa mayormente en el **Etiquetado de Tipos**.

* Un servidor web corre bajo el tipo `httpd_t`.
* Los archivos web están etiquetados como `httpd_sys_content_t`.
* Si un hacker toma control del proceso `httpd` (siendo `root`), e intenta leer los hashes de contraseñas en `/etc/shadow` (etiquetado como `shadow_t`), el kernel lo detendrá porque no existe una regla que diga:
`allow httpd_t shadow_t:file read;`


## Resumen de la jerarquía

1. **Hardware**
2. **Kernel (LSM / SELinux)** <-- Aquí se decide la verdad absoluta.
3. **DAC (Root, permisos rwx)** <-- Aquí es donde `root` cree que manda.
4. **Espacio de Usuario (Procesos)**
 
