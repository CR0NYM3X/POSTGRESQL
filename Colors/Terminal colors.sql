-- Función que demuestra capacidades de formato y color
CREATE OR REPLACE FUNCTION demo_terminal_controls() 
RETURNS void AS $$
DECLARE
    -- Códigos de control de terminal
    CLEAR_SCREEN text := E'\033[2J\033[H'; -- Limpia pantalla y mueve cursor al inicio
    CARRIAGE_RETURN text := E'\r'; -- Retorno de carro (vuelve al inicio de línea)
    
    -- Códigos de color (foreground)
    RED text := E'\033[31m';
    GREEN text := E'\033[32m';
    YELLOW text := E'\033[33m';
    BLUE text := E'\033[34m';
    MAGENTA text := E'\033[35m';
    CYAN text := E'\033[36m';
    RESET text := E'\033[0m'; -- Resetea todo el formato
    
    -- Códigos de estilo
    BOLD text := E'\033[1m';
    UNDERLINE text := E'\033[4m';
    BLINK text := E'\033[5m';
    
    -- Variables para la demostración
    progress text := '';
BEGIN
    -- Limpia la pantalla
    RAISE NOTICE '%', CLEAR_SCREEN;
    
    -- Demostración de colores
    RAISE NOTICE '% COLOR DEMO%', BOLD, RESET;
    RAISE NOTICE '%Este texto es rojo%', RED, RESET;
    RAISE NOTICE '%Este texto es verde%', GREEN, RESET;
    RAISE NOTICE '%Este texto es amarillo%', YELLOW, RESET;
    RAISE NOTICE '%Este texto es azul%', BLUE, RESET;
    RAISE NOTICE '%Este texto es magenta%', MAGENTA, RESET;
    RAISE NOTICE '%Este texto es cyan%', CYAN, RESET;
    
    -- Demostración de estilos
    RAISE NOTICE E'\n% STYLE DEMO%', BOLD, RESET;
    RAISE NOTICE '%Texto en negrita%', BOLD, RESET;
    RAISE NOTICE '%Texto subrayado%', UNDERLINE, RESET;
    RAISE NOTICE '%Texto parpadeante%', BLINK, RESET;
    
	RAISE NOTICE E'\n\n\r EN 3 Seg INICIARA LA BARRA DE PROGRASO';
	
	PERFORM pg_sleep(3);
	
    -- Demostración de barra de progreso con color
    RAISE NOTICE E'\n% PROGRESS BAR DEMO%', BOLD, RESET;
    FOR i IN 1..20 LOOP
		RAISE NOTICE '%', CLEAR_SCREEN;
        progress := progress || '█';
        RAISE NOTICE '% % %[%] %', 
            CARRIAGE_RETURN,
            CYAN,
            progress,
            GREEN,
            i * 5 || '%' || RESET;
        PERFORM pg_sleep(0.2);
    END LOOP;
END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice';

-- Ejecutar la demostración:
SELECT demo_terminal_controls();