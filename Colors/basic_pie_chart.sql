/* Requiere de la funcion notice_color.sql 

pie chart Basic

*/ 

BEGIN;


-- DROP FUNCTION  print_cube(p_width integer, p_height integer, p_character_cube character varying  , p_color_cube character varying  , p_character_circle character varying  , p_color_circle character varying  , p_percentage integer ,p_character_percentage  VARCHAR(2),p_color_percentage VARCHAR(100) );

CREATE OR REPLACE FUNCTION print_cube( 
											p_width INTEGER 
											,p_height INTEGER
											,p_character_cube VARCHAR(2) DEFAULT '░' 
											,p_color_cube VARCHAR(100) DEFAULT 'YELLOW'
											,p_character_circle VARCHAR(2) DEFAULT '-' 
											,p_color_circle VARCHAR(100) DEFAULT 'RED'
											,p_percentage INTEGER DEFAULT 30 
											,p_character_percentage  VARCHAR(2) DEFAULT '☺'
											,p_color_percentage VARCHAR(100) DEFAULT 'GREEN'
									)
RETURNS VOID AS $$
DECLARE

    v_width         TEXT[];
	v_array_cube    TEXT[][];
	
    v_character     TEXT :=  p_character_cube;
    color_rojo      TEXT := E'\033[31m'; -- Código ANSI para texto rojo
    reset_color     TEXT := E'\033[0m';  -- Código ANSI para resetear el color
	CLEAR_SCREEN    TEXT := E'\033[2J\033[H'; -- Limpia pantalla y mueve cursor al inicio
    CARRIAGE_RETURN TEXT := E'\r'; -- Retorno de carro (vuelve al inicio de línea)
    
	v_center_x      INTEGER := p_width / 2;
	v_center_y      INTEGER := p_height / 2;
	v_radius_x      INTEGER := (p_width +6 ) / 3; -- Radio en el eje X
	v_radius_y      INTEGER := (p_height +6 )    / 3; -- Radio en el eje Y
	v_angle_missing INTEGER := ( 360 * p_percentage  ) / 100   ; -- Ángulo que falta (30% del círculo)
    v_angle_current INTEGER := 0; -- Ángulo actual para dibujar el círculo
		
BEGIN

    -- Inicializar el array bidimensional vacío
    v_array_cube := ARRAY[]::text[][];
 
	-- Limpia la pantalla 
	RAISE NOTICE  E'\033[2J\033[H'; 
	
	-- Agregar el ancho de cubo 
	FOR i IN 1..p_width LOOP	 
		 v_width := array_append(v_width, notice_color(v_character , p_color_cube, 'bold'  , FALSE ) );
	END LOOP;

	-- Agregar lo alto de cubo 
	FOR i IN 1..p_height LOOP		 
		 v_array_cube := array_cat(v_array_cube, array[v_width]);
	END LOOP;
	
	
	-- Dibujar el círculo en el centro con la fórmula del círculo o Ovalo en coordenadas cartesianas 
	
	FOR y IN 1..p_height LOOP
		FOR x IN 1..p_width LOOP
		
			-- con la formula que calcula el ángulo actual en grados para cada punto (x, y) en el círculo. y se suma 90 para que empiece del Y positivo 
			v_angle_current := (atan2(y - v_center_y, x - v_center_x) * 180 / pi())  + 90  ;
		
			IF ((x - v_center_x)^2 / (v_radius_x^2))  + ((y - v_center_y)^2 / (v_radius_y^2)) <= 1 THEN

				IF v_angle_current < 0 THEN
					v_angle_current := v_angle_current + 360;
				END IF;
				
				-- IF v_angle_current >= 90 AND v_angle_current <= 90 + v_angle_missing THEN
				
				IF v_angle_current >= 0 AND v_angle_current <= v_angle_missing THEN				
                    v_array_cube[y][x] := notice_color(p_character_percentage, p_color_percentage, 'bold', FALSE);
                ELSE
                    v_array_cube[y][x] := notice_color(p_character_circle, p_color_circle, 'bold', FALSE);
                END IF;
				
			END IF;
		END LOOP;
	END LOOP;


	-- Imprimir el Cubo con el circulo
	FOR i IN 1..p_height LOOP
		 RAISE NOTICE E'\r   %',array_to_string(v_array_cube[i:i],'');
	END LOOP;
	
	RAISE NOTICE E'\r       ';	
	--RAISE NOTICE  E'\r Ancho_X : %   Alto_Y : % \n Porcentaje % %% \n Restante % \n' , p_width, p_height, p_percentage , 100 - p_percentage ;
	RAISE NOTICE  E'\r  Porcentaje: % %% \n  Restante: % \n' ,   p_percentage , 100 - p_percentage ;

END;
$$ LANGUAGE plpgsql
SET client_min_messages = notice;



   
   select * from print_cube( p_width =>  35 
							,p_height => 20 
							,p_character_cube => ' '  
							,p_color_cube => 'white' 
							,p_character_circle =>  '1' 
							,p_color_circle => 'RED' 
							,p_percentage => 60 
							,p_character_percentage => '0'
							,p_color_percentage => 'GREEN' );

ROLLBACK ; 


/*

select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '@' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '*' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '1' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '0' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  ':' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '=' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '☻' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '☺' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '$' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '%' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '■' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '□' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  'O' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '☺' ,p_color_percentage => 'GREEN' );

select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '▓' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '░' ,p_color_percentage => 'GREEN' );
select * from print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  '>' ,p_color_circle => 'RED' ,p_percentage => 60 ,p_character_percentage => '<' ,p_color_percentage => 'GREEN' );




                   *
             @@@@@@*******
           @@@@@@@@*********
         @@@@@@@@@@*********@@
        @@@@@@@@@@@********@@@@
       @@@@@@@@@@@@******@@@@@@@
       @@@@@@@@@@@@****@@@@@@@@@
       @@@@@@@@@@@@**@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@
         @@@@@@@@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@@@@
             @@@@@@@@@@@@@
                   @

				   0
             1111110000000
           11111111000000000
         111111111100000000011
        11111111111000000001111
       1111111111110000001111111
       1111111111110000111111111
       1111111111110011111111111
      111111111111111111111111111
       1111111111111111111111111
       1111111111111111111111111
       1111111111111111111111111
        11111111111111111111111
         111111111111111111111
           11111111111111111
             1111111111111
                   1


                  =
             ::::::=======
           ::::::::=========
         ::::::::::=========::
        :::::::::::========::::
       ::::::::::::======:::::::
       ::::::::::::====:::::::::
       ::::::::::::==:::::::::::
      :::::::::::::::::::::::::::
       :::::::::::::::::::::::::
       :::::::::::::::::::::::::
       :::::::::::::::::::::::::
        :::::::::::::::::::::::
         :::::::::::::::::::::
           :::::::::::::::::
             :::::::::::::
                   :


                   ☺
             ☻☻☻☻☻☻☺☺☺☺☺☺☺
           ☻☻☻☻☻☻☻☻☺☺☺☺☺☺☺☺☻
         ☻☻☻☻☻☻☻☻☻☻☺☺☺☺☺☺☺☻☻☻☻
        ☻☻☻☻☻☻☻☻☻☻☻☺☺☺☺☺☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☺☺☺☺☻☻☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☺☺☺☻☻☻☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☺☺☻☻☻☻☻☻☻☻☻☻☻
      ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
       ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
        ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
         ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
           ☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻☻
             ☻☻☻☻☻☻☻☻☻☻☻☻☻
                   ☻


                   %
             $$$$$$%%%%%%%
           $$$$$$$$%%%%%%%%%
         $$$$$$$$$$%%%%%%%%%$$
        $$$$$$$$$$$%%%%%%%%$$$$
       $$$$$$$$$$$$%%%%%%$$$$$$$
       $$$$$$$$$$$$%%%%$$$$$$$$$
       $$$$$$$$$$$$%%$$$$$$$$$$$
      $$$$$$$$$$$$$$$$$$$$$$$$$$$
       $$$$$$$$$$$$$$$$$$$$$$$$$
       $$$$$$$$$$$$$$$$$$$$$$$$$
       $$$$$$$$$$$$$$$$$$$$$$$$$
        $$$$$$$$$$$$$$$$$$$$$$$
         $$$$$$$$$$$$$$$$$$$$$
           $$$$$$$$$$$$$$$$$
             $$$$$$$$$$$$$
                   $

                   □
             ■■■■■■□□□□□□□
           ■■■■■■■■□□□□□□□□□
         ■■■■■■■■■■□□□□□□□□□□□
        ■■■■■■■■■■■□□□□□□□□□□□□
       ■■■■■■■■■■■■□□□□□□□□□□□□□
       ■■■■■■■■■■■■□□□□□□□□□□□□□
       ■■■■■■■■■■■■□□□□□□□□□□□□□
      ■■■■■■■■■■■■■□□□□□□□□□□□□□□
       ■■■■■■■■■■■■■■■■■■■■■■■■■
       ■■■■■■■■■■■■■■■■■■■■■■■■■
       ■■■■■■■■■■■■■■■■■■■■■■■■■
        ■■■■■■■■■■■■■■■■■■■■■■■
         ■■■■■■■■■■■■■■■■■■■■■
           ■■■■■■■■■■■■■■■■■
             ■■■■■■■■■■■■■
                   ■
				   
                  ☺
             OOOOOO☺☺☺☺☺OO
           OOOOOOOO☺☺☺☺OOOOO
         OOOOOOOOOO☺☺☺OOOOOOOO
        OOOOOOOOOOO☺☺☺OOOOOOOOO
       OOOOOOOOOOOO☺☺OOOOOOOOOOO
       OOOOOOOOOOOO☺☺OOOOOOOOOOO
       OOOOOOOOOOOO☺OOOOOOOOOOOO
      OOOOOOOOOOOOOOOOOOOOOOOOOOO
       OOOOOOOOOOOOOOOOOOOOOOOOO
       OOOOOOOOOOOOOOOOOOOOOOOOO
       OOOOOOOOOOOOOOOOOOOOOOOOO
        OOOOOOOOOOOOOOOOOOOOOOO
         OOOOOOOOOOOOOOOOOOOOO
           OOOOOOOOOOOOOOOOO
             OOOOOOOOOOOOO
                   O

                   ░
             ▓▓▓▓▓▓░░░░░░░
           ▓▓▓▓▓▓▓▓░░░░░░░░░
         ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░▓▓
        ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓░░░░▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓▓▓▓
      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
             ▓▓▓▓▓▓▓▓▓▓▓▓▓
                   ▓

                   <
             >>>>>><<<<<<<
           >>>>>>>><<<<<<<<<
         >>>>>>>>>><<<<<<<<<>>
        >>>>>>>>>>><<<<<<<<>>>>
       >>>>>>>>>>>><<<<<<>>>>>>>
       >>>>>>>>>>>><<<<>>>>>>>>>
       >>>>>>>>>>>><<>>>>>>>>>>>
      >>>>>>>>>>>>>>>>>>>>>>>>>>>
       >>>>>>>>>>>>>>>>>>>>>>>>>
       >>>>>>>>>>>>>>>>>>>>>>>>>
       >>>>>>>>>>>>>>>>>>>>>>>>>
        >>>>>>>>>>>>>>>>>>>>>>>
         >>>>>>>>>>>>>>>>>>>>>
           >>>>>>>>>>>>>>>>>
             >>>>>>>>>>>>>
                   >
				   



*/





BEGIN ;

CREATE OR REPLACE FUNCTION demo_progress_circle(p_sleep_time FLOAT DEFAULT 0.1 ) RETURNS VOID AS $$
DECLARE
    i INTEGER;
 
BEGIN

    -- Limpiar la pantalla (opcional)
    --RAISE NOTICE E'\033[H\033[2J';
    
    -- Mostrar las barras de progreso del 0 al 100
    FOR i IN 0..100 LOOP
	 
        
        -- Simular procesamiento
        PERFORM pg_sleep(p_sleep_time);
		 
		PERFORM  print_cube( p_width =>  35 ,p_height => 20 ,p_character_cube => ' '  ,p_color_cube => 'white' ,p_character_circle =>  ':' ,p_color_circle => 'RED' ,p_percentage => i ,p_character_percentage => '=' ,p_color_percentage => 'GREEN' );
 
    END LOOP;

END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice' ;


SELECT * FROM demo_progress_circle();

ROLLBACK ;



