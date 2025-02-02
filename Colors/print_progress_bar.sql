

/*****************************************************************

Función que genera barras de progreso coloridas con las siguientes características:

1. Acepta dos parámetros:
   - percentage: El porcentaje de progreso (0-100)
   - bar_type: El tipo de barra a mostrar (1-3)

2. Tipos de barras disponibles:
   - Tipo 1: Barra clásica [████░░░░]
   - Tipo 2: Barra de bloques |■■■□□□|
   - Tipo 3: Barra de flechas 《►►►···》

3. Colores dinámicos basados en el porcentaje:
   - 0-24%: Rojo
   - 25-49%: Amarillo
   - 50-74%: Azul
   - 75-100%: Verde

4. Ejemplos de uso:
SELECT print_progress_bar(75, 1); -- Barra clásica al 75%
SELECT print_progress_bar(30, 2); -- Barra de bloques al 30%
SELECT print_progress_bar(90, 3); -- Barra de flechas al 90%
 
 
5.- usando en proyecto: 

CREATE OR REPLACE FUNCTION demo_progress_bar(bar_type INTEGER DEFAULT 1) RETURNS VOID AS $$
DECLARE
    i INTEGER;
    sleep_time FLOAT := 0.1; -- Tiempo de espera entre actualizaciones en segundos
BEGIN

    -- Limpiar la pantalla (opcional)
    RAISE NOTICE E'\033[H\033[2J';
    
    -- Mostrar las barras de progreso del 0 al 100
    FOR i IN 0..100 LOOP
	 
        RAISE NOTICE E'\033[1G%', print_progress_bar(i, bar_type); 
        
        -- Simular procesamiento
        PERFORM pg_sleep(sleep_time);
		
		-- Si no es la última iteración, mover el cursor arriba 3 líneas
		IF i < 100 THEN
			RAISE NOTICE E'\033[3A';
		END IF;
		
    END LOOP;

END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice' ;

 
SELECT demo_progress_bar(1); -- Barra clásica
SELECT demo_progress_bar(2); -- Barra de bloques
SELECT demo_progress_bar(3); -- Barra de flechas
 
 
*****************************************************************/


 CREATE OR REPLACE FUNCTION print_progress_bar(
    percentage INTEGER,
    bar_type INTEGER DEFAULT 1
) RETURNS TEXT AS $$
DECLARE
    bar_length INTEGER := 50;
    filled_length INTEGER;
    empty_length INTEGER;
    result TEXT;
    filled_char TEXT;
    empty_char TEXT;
    start_char TEXT;
    end_char TEXT;
    -- Códigos de color ANSI
    color_green TEXT := E'\033[32m';
    color_blue TEXT := E'\033[34m';
    color_yellow TEXT := E'\033[33m';
    color_red TEXT := E'\033[31m';
    color_reset TEXT := E'\033[0m';
    progress_color TEXT;
BEGIN
    -- Validar el porcentaje
    IF percentage < 0 THEN
        percentage := 0;
    ELSIF percentage > 100 THEN
        percentage := 100;
    END IF;

    -- Determinar el color basado en el porcentaje
    IF percentage < 25 THEN
        progress_color := color_red;
    ELSIF percentage < 50 THEN
        progress_color := color_yellow;
    ELSIF percentage < 75 THEN
        progress_color := color_blue;
    ELSE
        progress_color := color_green;
    END IF;

    -- Calcular longitudes
    filled_length := (bar_length * percentage) / 100;
    empty_length := bar_length - filled_length;

    -- Seleccionar el tipo de barra
    CASE bar_type
        WHEN 1 THEN -- Barra clásica
            filled_char := '█';
            empty_char := '░';
            start_char := '[';
            end_char := ']';
        WHEN 2 THEN -- Barra de bloques
            filled_char := '■';
            empty_char := '□';
            start_char := '|';
            end_char := '|';
        WHEN 3 THEN -- Barra de flechas
            filled_char := '►';
            empty_char := '·';
            start_char := '《';
            end_char := '》';
        ELSE -- Tipo por defecto
            filled_char := '█';
            empty_char := '░';
            start_char := '[';
            end_char := ']';
    END CASE;

    -- Construir la barra de progreso
    result := start_char || 
              progress_color ||
              repeat(filled_char, filled_length) ||
              repeat(empty_char, empty_length) ||
              color_reset ||
              end_char || 
              ' ' || 
              progress_color || 
              percentage::TEXT || 
              '%' || 
              color_reset;

    RETURN result;
END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice' ;
