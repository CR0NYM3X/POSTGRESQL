📌 PostgreSQL con GSSAPI / Kerberos

Cuando configuras autenticación GSSAPI (Kerberos) en PostgreSQL:

Lo que logras es que el cliente y el servidor se autentiquen de forma segura, sin enviar contraseñas en texto plano.

Incluso puedes activar GSSAPI Encryption (opcional), que permite cifrar el tráfico usando el canal de Kerberos.



👉 Esto significa que sí puedes tener cifrado sin TLS, siempre que uses gssencmode=require en el cliente y el servidor soporte GSSAPI encryption.


---

🔒 ¿Entonces TLS ya no es necesario?

Depende del escenario:

Si usas solo GSSAPI (sin GSSAPI encryption habilitado)

✅ La autenticación es segura.

❌ El resto del tráfico (consultas, resultados, etc.) puede ir sin cifrar.

En este caso, sí deberías usar TLS si te importa cifrar todo.


Si usas GSSAPI + GSSAPI Encryption

✅ Toda la comunicación puede ir cifrada vía Kerberos.

No es estrictamente necesario TLS, aunque muchas organizaciones lo exigen por políticas o compatibilidad.


Si usas TLS

✅ Tienes cifrado de extremo a extremo.

TLS es más estándar y suele integrarse mejor con balanceadores, proxys y firewalls.




---

✅ Recomendación práctica

Si estás en un entorno cerrado, solo Kerberos, todo dentro de AD, puedes usar solo GSSAPI encryption.

Si necesitas cumplir con estándares de seguridad, auditorías o compatibilidad con clientes que no soportan GSSAPI encryption, lo más común es usar TLS con certificados de confianza (aunque ya tengas Kerberos para autenticación).



---

👉 En resumen:

GSSAPI = autenticación (opcionalmente cifrado si activas gssencmode).

TLS = cifrado universal del transporte (más estándar y obligatorio en muchos entornos).
