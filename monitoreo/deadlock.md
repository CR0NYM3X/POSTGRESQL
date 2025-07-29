#  lock , deadlock , lock waits
```
¿Qué es un "lock"?
Lock: Un "lock" o bloqueo es un mecanismo utilizado por una base de datos para controlar el acceso a los datos. Imagina que los datos son como un libro que varios amigos quieren leer al mismo tiempo. Un "lock" es como reservar ese libro para que solo una persona pueda leerlo a la vez, evitando que otras personas modifiquen la información mientras está en uso.

lock wait : Cuando una transacción A intenta modificar un objeto que está bloqueado por una transacción B, y la transacción A queda esperando

¿Qué es un "deadlock"?
Deadlock: Un "deadlock" o interbloqueo ocurre cuando dos o más "locks" se bloquean mutuamente. Siguiendo con la analogía del libro, imagina que tienes dos amigos, Ana y Juan. Ana tiene el libro 1 y quiere leer el libro 2, pero Juan tiene el libro 2 y quiere leer el libro 1. Ninguno de los dos puede continuar porque ambos están esperando el libro que el otro tiene, creando un ciclo sin fin de espera. Eso es un "deadlock".


SET deadlock_timeout = '2s';
Comportamiento: Si Ana y Juan quedan bloqueados por un deadlock, PostgreSQL esperará 2 segundos antes de comprobar si hay un deadlock. Si se detecta un deadlock, PostgreSQL abortará una de las transacciones, permitiendo que la otra continúe.


SET lock_timeout = '5s';
Comportamiento: Si Ana está esperando obtener un lock en la tabla libros y esa tabla ya está bloqueada por Juan, Ana esperará hasta 5 segundos. Si en ese tiempo no consigue el lock, su transacción se abortará con un error.


------------------------------------------------------------------------------------------


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


SET deadlock_timeout = '2s';
SET lock_timeout = '5s';
SET log_lock_waits = on;

```
