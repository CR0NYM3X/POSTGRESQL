
# credcheck 
```sql
select name,setting,short_desc from pg_settings where name ilike '%credcheck.%' order by name;


ejemplos: https://github.com/MigOpsRepos/credcheck/tree/master/test/expected

https://stackoverflow.com/questions/68400120/how-to-generate-scram-sha-256-to-create-postgres-13-user


 

1. **credcheck.auth_delay_ms**: Establece un retraso en milisegundos antes de informar un fallo de autenticación. Esto dificulta los ataques de fuerza bruta.
2. **credcheck.auth_failure_cache_size**: Define el tamaño de la caché para los fallos de autenticación. Por defecto, está configurado en 1024 registros.
3. **credcheck.encrypted_password_allowed**: Permite el uso de contraseñas cifradas en las declaraciones `CREATE` o `ALTER ROLE`.
4. **credcheck.history_max_size**: Establece el tamaño máximo del historial de contraseñas. Por defecto, está configurado en 65535 registros.
5. **credcheck.max_auth_failure**: Limita el número de intentos de autenticación fallidos permitidos antes de bloquear una cuenta.
6. **credcheck.no_password_logging**: Evita que PostgreSQL registre contraseñas en los logs en caso de error en `CREATE` o `ALTER ROLE`.
7. **credcheck.password_contain**: Define los caracteres que deben estar presentes en la contraseña.
8. **credcheck.password_contain_username**: Evita que la contraseña contenga el nombre de usuario.
9. **credcheck.password_ignore_case**: Ignora las mayúsculas y minúsculas al verificar la contraseña.
10. **credcheck.password_min_digit**: Establece el número mínimo de dígitos que debe contener la contraseña.
11. **credcheck.password_min_length**: Define la longitud mínima de la contraseña.
12. **credcheck.password_min_lower**: Establece el número mínimo de letras minúsculas que debe contener la contraseña.
13. **credcheck.password_min_repeat**: Evita caracteres repetidos adyacentes en la contraseña.
14. **credcheck.password_min_special**: Establece el número mínimo de caracteres especiales que debe contener la contraseña.
15. **credcheck.password_min_upper**: Establece el número mínimo de letras mayúsculas que debe contener la contraseña.
16. **credcheck.password_not_contain**: Define los caracteres que no deben estar presentes en la contraseña.
17. **credcheck.password_reuse_history**: Establece el número de contraseñas distintas que deben usarse antes de poder reutilizar una contraseña anterior.
18. **credcheck.password_reuse_interval**: Define el intervalo de tiempo antes de que una contraseña pueda ser reutilizada.
19. **credcheck.password_valid_max**: Establece la duración máxima de validez de una contraseña.
20. **credcheck.password_valid_until**: Define la fecha de expiración de la contraseña.
21. **credcheck.reset_superuser**: Permite restablecer la contraseña del superusuario.
22. **credcheck.username_contain**: Define los caracteres que deben estar presentes en el nombre de usuario.
23. **credcheck.username_contain_password**: Evita que el nombre de usuario contenga la contraseña.
24. **credcheck.username_ignore_case**: Ignora las mayúsculas y minúsculas al verificar el nombre de usuario.
25. **credcheck.username_min_digit**: Establece el número mínimo de dígitos que debe contener el nombre de usuario.
26. **credcheck.username_min_length**: Define la longitud mínima del nombre de usuario.
27. **credcheck.username_min_lower**: Establece el número mínimo de letras minúsculas que debe contener el nombre de usuario.
28. **credcheck.username_min_repeat**: Evita caracteres repetidos adyacentes en el nombre de usuario.
29. **credcheck.username_min_special**: Establece el número mínimo de caracteres especiales que debe contener el nombre de usuario.
30. **credcheck.username_min_upper**: Establece el número mínimo de letras mayúsculas que debe contener el nombre de usuario.
31. **credcheck.username_not_contain**: Define los caracteres que no deben estar presentes en el nombre de usuario.
32. **credcheck.whitelist**: Permite especificar una lista de usuarios que están exentos de ciertas verificaciones de credenciales.
 

```
