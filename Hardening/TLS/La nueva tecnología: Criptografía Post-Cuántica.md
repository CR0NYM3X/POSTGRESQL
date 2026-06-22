

### 1. La nueva tecnología: Criptografía Post-Cuántica (PQC)

Para protegernos de las computadoras cuánticas, el gobierno de los Estados Unidos (a través del NIST) lideró un concurso mundial durante años para encontrar nuevos algoritmos matemáticos que ni siquiera una computadora cuántica pueda resolver. Estos nuevos estándares se oficializaron recientemente (a mediados de 2024).

En el mundo de TLS y certificados, esto se divide en dos partes:

* **Para el intercambio de claves (Proteger la conexión actual):** Se estandarizó un algoritmo llamado **ML-KEM** (antes conocido como Kyber).
* **Para los certificados y firmas (Proteger la identidad):** Se estandarizó un algoritmo llamado **ML-DSA** (antes conocido como Dilithium).

**El problema del "Almacena ahora, descifra después":** Actualmente, los hackers están robando tráfico cifrado y guardándolo. No pueden leerlo hoy, pero esperan que cuando tengan una computadora cuántica en 5 o 10 años, puedan descifrarlo. Por eso, **la prioridad número uno de la industria hoy es proteger la conexión (el intercambio de claves)** antes que cambiar el formato físico de los certificados.

Para lograr esto de forma segura sin romper el internet, se inventó el **Intercambio de Claves Híbrido**.

Básicamente, tu navegador y el servidor usan el cifrado tradicional (para asegurar la compatibilidad) **y** le suman una capa de cifrado Post-Cuántico (Kyber/ML-KEM) al mismo tiempo. Si un algoritmo falla, el otro mantiene todo seguro.

---

### 2. Cómo revisar si una página web ya está protegida

Empresas gigantes como Google, Cloudflare y Microsoft ya activaron esta protección híbrida post-cuántica por defecto en sus servidores y en navegadores como Chrome o Edge.

Para comprobar si la página web en la que estás navegando ya cuenta con protección contra computadoras cuánticas, sigue estos pasos desde **Google Chrome** o **Microsoft Edge** en tu computadora:

1. Entra a una página web moderna (por ejemplo, `google.com` o `cloudflare.com`).
2. Abre las **Herramientas de Desarrollador** de tu navegador presionando la tecla **F12** (o haz clic derecho en la página y elige "Inspeccionar").
3. En el panel que se abre, busca la pestaña que dice **Security** (Seguridad). Si no la ves a simple vista, haz clic en el ícono de las flechitas `>>` en la barra superior del panel para ver más opciones.
4. En el panel de Seguridad, busca la sección **Connection** (Conexión) y lee los detalles.
5. Fíjate en la línea que dice **"Key exchange group"** (Grupo de intercambio de claves).

**¿Qué debes buscar?**

* **Si NO está protegida contra cuánticas:** Dirá algo estándar como `X25519` o `secp256r1`. Esto significa que usa criptografía clásica.
* **Si SÍ está protegida (Criptografía Híbrida):** Dirá algo como **`X25519Kyber768Draft00`**, **`X25519MLKEM768`** o simplemente incluirá la palabra **`Kyber`** o **`MLKEM`**.

Si ves esa palabra clave, significa que la conexión entre tu computadora y ese servidor web está utilizando algoritmos post-cuánticos y ni siquiera una súper computadora del futuro podrá descifrar lo que estás haciendo hoy en esa página.

