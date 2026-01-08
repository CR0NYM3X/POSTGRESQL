
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

 
