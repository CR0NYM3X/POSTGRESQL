-- Creación del juego Snake en PostgreSQL
CREATE OR REPLACE FUNCTION play_snake() RETURNS void AS $$
DECLARE
    -- Constantes del juego
    WIDTH integer := 20;
    HEIGHT integer := 10;
    
    -- Códigos ANSI
    CLEAR text := E'\033[2J\033[H';
    GREEN text := E'\033[32m';
    RED text := E'\033[31m';
    RESET text := E'\033[0m';
    
    -- Variables del juego
    snake_x integer[] := ARRAY[5];
    snake_y integer[] := ARRAY[5];
    food_x integer := 10;
    food_y integer := 5;
    direction text := 'right';
    score integer := 0;
    game_over boolean := false;
    
    -- Variables temporales
    display text;
    i integer;
    j integer;
    head_x integer;
    head_y integer;
BEGIN
    -- Inicializar generador aleatorio
    --PERFORM setseed(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP));
	--PERFORM (EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) % 1000) / 1000.0;
    
    WHILE NOT game_over LOOP
        -- Limpiar pantalla
        RAISE NOTICE '%', CLEAR;
        
        -- Mover la serpiente
        head_x := snake_x[1];
        head_y := snake_y[1];
        
        -- Actualizar posición según dirección
        CASE direction
            WHEN 'right' THEN head_x := head_x + 1;
            WHEN 'left' THEN head_x := head_x - 1;
            WHEN 'up' THEN head_y := head_y - 1;
            WHEN 'down' THEN head_y := head_y + 1;
        END CASE;
        
        -- Verificar colisiones con paredes
        IF head_x < 1 OR head_x > WIDTH OR head_y < 1 OR head_y > HEIGHT THEN
            game_over := true;
            CONTINUE;
        END IF;
        
        -- Verificar si come comida
        IF head_x = food_x AND head_y = food_y THEN
            score := score + 1;
            -- Nueva comida en posición aleatoria
            food_x := 1 + floor(random() * WIDTH)::integer;
            food_y := 1 + floor(random() * HEIGHT)::integer;
            -- Hacer crecer la serpiente
            snake_x := array_prepend(head_x, snake_x);
            snake_y := array_prepend(head_y, snake_y);
        ELSE
            -- Mover la serpiente
            snake_x := array_prepend(head_x, snake_x[1:array_length(snake_x, 1)-1]);
            snake_y := array_prepend(head_y, snake_y[1:array_length(snake_y, 1)-1]);
        END IF;
         
        -- Dibujar el juego
        display := 'Score: ' || score || E'\n';  
        FOR j IN 1..HEIGHT LOOP
            FOR i IN 1..WIDTH LOOP
                IF i = food_x AND j = food_y THEN
                    display := display || RED || '●' || RESET;
                ELSIF i = snake_x[1] AND j = snake_y[1] THEN
                    display := display || GREEN || '◉' || RESET;
                ELSIF EXISTS (
                    SELECT 1 
                    FROM generate_subscripts(snake_x, 1) AS s 
                    WHERE snake_x[s] = i AND snake_y[s] = j
                ) THEN
                    display := display || GREEN || '○' || RESET;
                ELSE
                    display := display || '·';
                END IF;
            END LOOP;
            display := display || E'\n';
        END LOOP;
       
        -- Mostrar el juego
        RAISE NOTICE '%', display;
        
        -- Cambiar dirección aleatoriamente (simulando entrada del usuario)
        IF random() < 0.3 THEN
            direction := (ARRAY['up','down','left','right'])[1 + floor(random() * 4)];
        END IF;
        
        -- Pequeña pausa
        PERFORM pg_sleep(0.2);
    END LOOP;
    
    RAISE NOTICE 'Game Over! Score: %', score;
END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice' ;

-- Ejecutar el juego:
SELECT play_snake();