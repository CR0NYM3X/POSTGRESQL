## ¿Qué es un "deadlock"?
Deadlock ("deadlock" o interbloqueo) :  es una situación en la que dos o más transacciones se bloquean mutuamente esperando recursos que el otro tiene, y ninguna puede continuar.. Realizaremos la analogía  del libro y  imagina que tienes dos amigos, Ana y Juan. Ana tiene el libro 1 y quiere leer el libro 2, pero Juan tiene el libro 2 y quiere leer el libro 1. Ninguno de los dos puede continuar porque ambos están esperando el libro que el otro tiene, creando un ciclo sin fin de espera. Eso es un "deadlock".


### lock wait 
Cuando una transacción A intenta modificar un objeto que está bloqueado por una transacción B, y la transacción A queda esperando

# Ejemplo
```
CREATE TABLE inventario (
    id SERIAL PRIMARY KEY,
    producto VARCHAR(255),
    cantidad INT
);


INSERT INTO inventario (producto, cantidad) VALUES
('Producto A', 100),
('Producto B', 200),
('Producto C', 300);


# Crear transacciones que causen locks

******* Transacción 1
BEGIN;
UPDATE inventario SET cantidad = cantidad - 10 WHERE producto = 'Producto A';


******* Transacción 2
BEGIN;
UPDATE inventario SET cantidad = cantidad - 20 WHERE producto = 'Producto B';




# Crear un deadlock

******* Transacción 1
UPDATE inventario SET cantidad = cantidad - 10 WHERE producto = 'Producto B';



******* Transacción 2
UPDATE inventario SET cantidad = cantidad - 20 WHERE producto = 'Producto A';




```

## LOG 
```
2025-07-29 14:17:48.237 MST [3854430] ERROR:  deadlock detected
2025-07-29 14:17:48.237 MST [3854430] DETAIL:  Process 3854430 waits for ShareLock on transaction 829; blocked by process 3888414.
        Process 3888414 waits for ShareLock on transaction 828; blocked by process 3854430.
        Process 3854430: UPDATE inventario SET cantidad = cantidad - 10 WHERE producto = 'Producto B';
        Process 3888414: UPDATE inventario SET cantidad = cantidad - 20 WHERE producto = 'Producto A';

```

## Parámetros 
```
SET log_lock_waits = on; -- permite a postgresql registrar los lock  en el log

SET deadlock_timeout = '2s';
Comportamiento: Si Ana y Juan quedan bloqueados por un deadlock, PostgreSQL esperará 2 segundos antes de comprobar si hay un deadlock. Si se detecta un deadlock, PostgreSQL abortará una de las transacciones, permitiendo que la otra continúe.


SET lock_timeout = '5s';
Comportamiento: Si Ana está esperando obtener un lock en la tabla libros y esa tabla ya está bloqueada por Juan, Ana esperará hasta 5 segundos. Si en ese tiempo no consigue el lock, su transacción se abortará con un error.
```
