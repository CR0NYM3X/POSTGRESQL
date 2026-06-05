
# Restringir el acceso SSH

Para restringir el acceso SSH de un usuario específico a una sola dirección IP en Linux, existen dos métodos principales y recomendados. El primero es mediante el archivo de configuración del servidor SSH y el segundo a través de las llaves públicas. 

## Opción 1: Usar `sshd_config` (Método Recomendado)

Este método es el más robusto porque se gestiona a nivel de servidor. Tienes dos formas de hacerlo:

### A. Usando la directiva `AllowUsers`

Si quieres que el usuario `juan` **solo** pueda entrar desde la IP `192.168.1.50`, añade esta línea al final del archivo `/etc/ssh/sshd_config`:

```bash
AllowUsers juan@192.168.1.50

```

> **¡Cuidado!**: Al usar `AllowUsers`, solo los usuarios listados podrán entrar. Si tienes otros usuarios (como `admin`), deberás añadirlos también o perderán el acceso: `AllowUsers juan@192.168.1.50 admin@*`.

### B. Usando un bloque `Match` (Más seguro y flexible)

Esta es la mejor opción si quieres restringir a un usuario **sin afectar a los demás**. Añade esto al final de `/etc/ssh/sshd_config`:

```ssh
Match User juan
    AllowUsers juan@192.168.1.50

```

O de forma más estricta para denegar si no es esa IP:

```ssh
Match User juan Address *,!192.168.1.50
    DenyUsers juan

```

---

## Opción 2: Restricción por Llave Pública (`authorized_keys`)

Si el usuario utiliza llaves SSH para conectarse, puedes restringir su IP directamente en su archivo de llaves autorizadas. Esto es muy útil porque no requiere reiniciar el servicio SSH global.

1. Edita el archivo del usuario: `nano /home/juan/.ssh/authorized_keys`.
2. Al principio de la línea que contiene la llave, añade `from="IP"`:

```text
from="192.168.1.50" ssh-rsa AAAAB3Nza... (resto de la llave)

```

De esta manera, aunque alguien robe la llave privada, no podrá usarla desde una ubicación distinta a la IP permitida.

---

## Pasos para aplicar los cambios (Si usaste la Opción 1)

Si editaste el archivo `/etc/ssh/sshd_config`, sigue estos pasos para evitar quedar bloqueado:

1. **Valida la sintaxis** del archivo para asegurarte de que no hay errores:
```bash
sudo sshd -t

```


*Si no sale ningún mensaje, todo está bien.*
2. **Reinicia el servicio SSH**:
```bash
sudo systemctl restart ssh

```


3. **Prueba la conexión**: No cierres tu sesión actual de SSH hasta que hayas comprobado en una ventana nueva que puedes entrar (y que el usuario restringido solo entra desde su IP).

 


---


# Manual Técnico: Configuración de Acceso SSH Automatizado y Buenas Prácticas de Hardening

Este documento técnico describe el procedimiento estándar para configurar un acceso seguro y automatizado mediante SSH desde un **Servidor A (Origen)** hacia un **Servidor B (Destino)** sin el uso de contraseñas interactivas, mitigando los riesgos asociados mediante directivas de endurecimiento (*hardening*).

---

## 1. Fundamentos Tecnológicos (¿Qué hace cada cosa?)

La autenticación se basa en criptografía de llave pública (asimétrica), eliminando la necesidad de transmitir contraseñas por la red.

```
+-------------------+                    +-------------------+
|    SERVIDOR A     |                    |    SERVIDOR B     |
|     (Origen)      |                    |     (Destino)     |
|                   |                    |                   |
|  [Llave Privada]  |-- (Desafío SSH) -->|  [Llave Pública]  |
|   (id_ed25519)    |                    | (authorized_keys) |
+-------------------+                    +-------------------+

```

* **Llave Privada (`id_ed25519`):** Reside exclusivamente en el Servidor A. Funciona como la firma digital o llave maestra. **Nunca debe ser compartida ni movida de este servidor.**
* **Llave Pública (`id_ed25519.pub`):** Es el "candado" que se instala en el Servidor B. No es secreta.
* **Archivo `authorized_keys`:** Archivo en el Servidor B que almacena las llaves públicas autorizadas para tomar el control del usuario correspondiente.
* **Algoritmo Ed25519:** Esquema de firma digital de curva elíptica. Ofrece mayor seguridad y rendimiento que el tradicional RSA con firmas más compactas.

---

## 2. Análisis de Riesgos y Beneficios

Antes de la implementación, el equipo de seguridad debe considerar el siguiente balance de riesgos:

### Ventajas

* **Inmunidad a Fuerza Bruta:** Elimina la posibilidad de ataques de diccionario dirigidos a adivinar contraseñas.
* **Automatización de Tareas:** Permite la ejecución autónoma de tareas programadas (CRON, CI/CD, respaldos).
* **Auditoría unívoca:** Permite identificar exactamente qué llave (y por ende qué servidor/usuario) originó la conexión en los logs de auditoría (`/var/log/auth.log` o `secure`).

### Riesgos y Desventajas

* **Movimiento Lateral (Efecto Dominó):** Si un atacante compromete el Servidor A y obtiene la llave privada, comprometerá inmediatamente el Servidor B.
* **Gestión de Ciclo de Vida:** La falta de rotación o depuración de llaves puede dejar accesos activos a sistemas o personal obsoleto.

---

## 3. Guía de Implementación Paso a Paso

### Paso 1: Generación de Llaves en el Servidor A

Acceda a la terminal del **Servidor A** con el usuario que ejecutará la automatización y genere el par de llaves:

```bash
ssh-keygen -t ed25519 -C "automatizacion_servidor_A"

```

> ⚠️ **Control de Seguridad:** Cuando el comando solicite una frase de contraseña (*passphrase*), **presione ENTER para dejarla en blanco**. Si introduce una contraseña, los scripts automáticos no podrán conectar sin intervención humana.

### Paso 2: Transferencia de la Llave Pública al Servidor B

Transfiera la llave pública hacia el **Servidor B**. Reemplace `usuario` por el usuario destino y la IP correspondiente:

```bash
ssh-copy-id usuario@IP_SERVIDOR_B

```

*(Deberá ingresar la contraseña del Servidor B por última vez para autorizar la copia).*

### Paso 3: Verificación de Permisos Críticos (Servidor B)

SSH rechazará llaves si los permisos de las carpetas son muy permisivos. Conéctese al **Servidor B** y aplique los permisos correctos:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

```

### Paso 4: Prueba de Conectividad Inicial

Desde el **Servidor A**, valide que el acceso se realice de manera directa y sin solicitud de credenciales:

```bash
ssh usuario@IP_SERVIDOR_B

```

---

## 4. Endurecimiento de Seguridad (Hardening)

Para mitigar el riesgo de movimiento lateral, aplique las siguientes directivas de control en el **Servidor B**.

### Mitigación 1: Restricción de Origen (IP Binding) e Inyección de Comandos

Edite el archivo `~/.ssh/authorized_keys` en el **Servidor B** y localice la línea de la llave añadida. Anteponga las directivas de restricción al inicio de la línea:

```text
from="IP_DEL_SERVIDOR_A",no-port-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...

```

* `from="IP_DEL_SERVIDOR_A"`: El Servidor B rechazará la llave si el atacante intenta usarla desde cualquier otra IP.
* `no-pty`: Deshabilita la asignación de una terminal interactiva. Si alguien roba la llave, no podrá "escribir" comandos de forma libre en la consola.
* `no-port-forwarding`: Evita que usen el túnel SSH para saltarse firewalls internos.

### Mitigación 2: Principio de Menor Privilegio

* **No use la cuenta `root`:** Cree siempre un usuario específico (ej: `usr-backup`) en el Servidor B con acceso restringido únicamente al directorio necesario para la tarea.

### Mitigación 3: Desactivar Autenticación por Contraseña

Una vez comprobado el funcionamiento de las llaves, se recomienda desactivar el acceso tradicional por contraseña en el archivo de configuración global de SSH del **Servidor B** (`/etc/ssh/sshd_config`):

```text
#Desactiva por completo la validación mediante contraseñas tradicionales de usuario.
PasswordAuthentication no

#Activa y autoriza explícitamente el uso de llaves criptográficas (públicas y privadas) para iniciar sesión.
PubkeyAuthentication yes


KbdInteractiveAuthentication no

```

*Aplique los cambios reiniciando el servicio:* `sudo systemctl restart sshd`

---

## 5. Matriz de Mantenimiento y Ciclo de Vida

Para mantener el entorno seguro a lo largo del tiempo, la administración de sistemas debe auditar periódicamente lo siguiente:

1. **Rotación de Llaves:** Se recomienda destruir y regenerar el par de llaves cada 12 meses.
2. **Auditoría de Archivos:** Revisar mensualmente el archivo `authorized_keys` de los servidores críticos para verificar que no existan llaves residuales de antiguos administradores o servicios inactivos.









## 2. ¿Es recomendado mantener las llaves públicas y privadas en cada servidor? ¿Cómo funciona la arquitectura correcta?

**Respuesta corta:** **No.** Nunca debes duplicar ni pasear la **llave privada** por todos lados. La llave privada es personal e intransferible de cada servidor o usuario.

Para entender cómo se distribuyen, imagina que las llaves son un candado (Llave Pública) y su llave física (Llave Privada).

### El esquema correcto de distribución:

* **En el Servidor A (Origen):** Aquí reside tu **Llave Privada** (`id_ed25519`). Solo el Servidor A debe conocerla. El Servidor A **no necesita** tener una llave privada del Servidor B para conectarse a él.
* **En el Servidor B (Destino):** Aquí reside la **Llave Pública** del Servidor A (dentro del archivo `authorized_keys`). El Servidor B no necesita generar un par de llaves propio para recibir conexiones, solo necesita el "candado" del Servidor A para poder verificarlo.

### ¿Por qué es un peligro clonar la misma llave en ambos?

Si tú generas un par de llaves en el Servidor A, y luego copias **tanto la pública como la privada** al Servidor B para que "ambos tengan lo mismo", estás rompiendo la seguridad:

1. Si hackean el Servidor B, obtendrán la llave privada del Servidor A, logrando acceso de regreso al Servidor A (un viaje de ida y vuelta para el atacante).
2. Pierdes el control de identidad: ya no sabes si una conexión fue legítima del Servidor A o si alguien usó la copia del Servidor B.

### Regla de oro en arquitectura de seguridad:

> Las llaves **públicas** se distribuyen a los cuatro vientos (a cualquier servidor al que te quieras conectar). Las llaves **privadas** nacen, viven y mueren únicamente en el servidor/dispositivo donde fueron generadas.

Si en un futuro quieres que el Servidor B se conecte al Servidor A de forma inversa, el procedimiento se repite al revés: generas un par de llaves *nuevo* en el Servidor B, y exportas *solo* su llave pública hacia el Servidor A.







--------




Como experto en seguridad, te respondo con un rotundo **SÍ, es altamente recomendado en entornos profesionales y empresariales**.

A medida que una infraestructura crece, dejar las llaves privadas esparcidas en el disco duro de cada servidor (dentro de la carpeta `~/.ssh/`) se convierte en un riesgo crítico. Si un atacante logra comprometer el sistema operativo a nivel de raíz (`root`), podrá leer los archivos del disco y robar las llaves.

Para evitar esto, se utilizan tecnologías de gestión de llaves y secretos. Aquí te explico cuáles son las recomendadas para SSH, cómo funcionan y cuándo aplicar cada una:

---

### 1. Gestores de Secretos y Bóvedas (Vaults)

La herramienta estándar de la industria para esto es **HashiCorp Vault** (o alternativas como *CyberArk* o *Infisical*).

* **¿Cómo mitiga el riesgo?** En lugar de tener una llave estática que dura meses o años guardada en el Servidor A, integras el Servidor A con Vault. Cuando el Servidor A necesita conectarse al Servidor B, le pide a Vault una **llave temporal (SSH Certificate)**.
* **¿Cómo funciona?** Vault actúa como una Entidad Certificadora (CA). Genera una llave que **solo es válida por unos minutos o unas horas**. El Servidor A la usa para entrar al Servidor B y, tras expirar el tiempo, esa llave ya no sirve para nada. Si un atacante hackea el Servidor A mañana, no encontrará ninguna llave útil que robar.

### 2. HSM (Hardware Security Module) / KMS (Key Management Service)

Un HSM es un componente físico (un chip o servidor dedicado) diseñado exclusivamente para resguardar llaves criptográficas y realizar operaciones matemáticas dentro de él. Su equivalente en la nube son los servicios KMS (como AWS KMS, Azure Key Vault o Google Cloud KMS).

* **¿Cómo mitiga el riesgo?** **La llave privada NUNCA sale del hardware.** Está blindada. Ni siquiera el administrador del sistema puede ver el código de la llave privada.
* **¿Cómo funciona?** Cuando el Servidor A quiere autenticarse, le envía el "acertijo matemático" del SSH al HSM/KMS. El HSM firma el acertijo por dentro usando la llave privada y devuelve el resultado firmado. El Servidor A se conecta al Servidor B demostrando la firma, pero la llave privada jamás tocó el disco duro ni la memoria RAM del Servidor A.

### 3. Soluciones Integradas modernas (YubiKeys / TPM)

Si estás protegiendo la conexión desde tu laptop hacia los servidores, o entre servidores físicos específicos:

* **YubiKey (Llave de seguridad de hardware):** Puedes generar las llaves SSH directamente dentro de una YubiKey (usando protocolos FIDO2 o PIV). Para que el SSH funcione, la llave física debe estar conectada y, en muchos casos, debes tocar el sensor con el dedo.
* **TPM (Trusted Platform Module):** Es el chip de seguridad que ya viene soldado en la tarjeta madre de casi cualquier servidor o laptop moderna. Puedes configurar Linux para que genere y guarde la llave privada SSH dentro del chip TPM, impidiendo que el software del servidor pueda extraerla.

---

## 📋 Resumen de Recomendaciones: ¿Qué deberías usar?

Dependiendo del tamaño de tu proyecto, esta es la ruta de mejores prácticas:

1. **Proyectos Pequeños / Startups:** Si solo tienes 2 o 3 servidores, usar un **KMS en la nube** o proteger las llaves con permisos estrictos de Linux (`chmod 600`) y restricción de IPs (`from="IP"`) suele ser suficiente, ya que mantener un Vault propio puede ser complejo.
2. **Entornos Medios / Equipos de Desarrollo:** Se recomienda usar un gestor de secretos (como **HashiCorp Vault**) para automatizar la entrega de accesos SSH dinámicos y temporales a los administradores y herramientas de CI/CD.
3. **Entornos Corporativos / Gobierno / Finanzas (Alta Seguridad):** Es obligatorio por normativas de cumplimiento (como PCI-DSS o ISO 27001) que todas las llaves maestras de infraestructura residan en un **HSM** (físico o en la nube) para garantizar que nadie pueda clonarlas o exportarlas de forma maliciosa.








