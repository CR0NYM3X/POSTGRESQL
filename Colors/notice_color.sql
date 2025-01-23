
/*


FUNCION QUE TE PERMITE AGREGARLE COLOR AL TEXTO
23/01/2025



*/
 

--- DROP FUNCTION notice_color(text,text,text,text,boolean,text,text);


CREATE OR REPLACE FUNCTION notice_color(
    text_to_print TEXT,
    color TEXT DEFAULT '',
    style TEXT DEFAULT '',
	is_return BOOLEAN DEFAULT TRUE ,-- retorna el texto 
    log_to_file TEXT DEFAULT NULL, --- solicita el la ruta y nombre de archivo donde va guardar
    include_timestamp BOOLEAN DEFAULT false, 
    case_transform TEXT DEFAULT NULL, --- upper , lower 
    typography TEXT DEFAULT NULL -- 'bold', 'italic', 'fraktur'
)
RETURNS TEXT AS $$
DECLARE
    color_code TEXT := '';
    style_code TEXT := '';
    reset_code TEXT := E'\033[0m';
    is_psql BOOLEAN := false;
    formatted_text TEXT;
    timestamp_prefix TEXT := '';
    log_filepath TEXT := '/tmp/notice_color.log';


    transformed_text TEXT := '';
    char_index INT;
BEGIN
 
    -- Verificar si el cliente es psql
    SELECT current_setting('application_name') ILIKE 'psql%' INTO is_psql;

    -- Añadir marca de tiempo si se solicita
    IF include_timestamp THEN
        timestamp_prefix := '[' || to_char(now(), 'YYYY-MM-DD HH24:MI:SS') || '] ';
    END IF;

    -- Aplicar transformación de mayúsculas/minúsculas si se especifica
    IF case_transform = 'upper' THEN
        text_to_print := upper(text_to_print);
    ELSIF case_transform = 'lower' THEN
        text_to_print := lower(text_to_print);
    END IF;
 
    -- Transformar a tipografía Unicode si se especifica
    IF typography IS NOT NULL THEN
	 
		
		CASE lower(typography)
			-- negrita
			WHEN 'bold' THEN transformed_text := TRANSLATE(text_to_print, 
											   'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
											   '𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭');
			-- 	cursiva							   
			WHEN 'italic' THEN transformed_text := TRANSLATE(text_to_print, 
												 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
												 '𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁');
			-- negrita_cursiva									 
			WHEN 'bold_italic' THEN transformed_text := TRANSLATE(text_to_print, 
													 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
													 '𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁');
			-- 	subrayado									 
			WHEN 'underlined' THEN transformed_text := TRANSLATE(text_to_print, 
													'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
													'a̲b̲c̲d̲e̲f̲g̲h̲i̲j̲k̲l̲m̲n̲o̲p̲q̲r̲s̲t̲u̲v̲w̲x̲y̲z̲A̲B̲C̲D̲E̲F̲G̲H̲I̲J̲K̲L̲M̲N̲O̲P̲Q̲R̲S̲T̲U̲V̲W̲X̲Y̲Z̲');
			-- tachado										
			WHEN 'strikethrough' THEN transformed_text := TRANSLATE(text_to_print, 
													   'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
													   'a̶b̶c̶d̶e̶f̶g̶h̶i̶j̶k̶l̶m̶n̶o̶p̶q̶r̶s̶t̶u̶v̶w̶x̶y̶z̶A̶B̶C̶D̶E̶F̶G̶H̶I̶J̶K̶L̶M̶N̶O̶P̶Q̶R̶S̶T̶U̶V̶W̶X̶Y̶Z̶');
			-- superindice										   
			WHEN 'superscript' THEN transformed_text := TRANSLATE(text_to_print, 
													 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 
													 'ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᵠᴿˢᵀᵁⱽᵂˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹');
			-- subindice										 
			WHEN 'subscript' THEN transformed_text := TRANSLATE(text_to_print, 
												   'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 
												   'ₐₑᵢₒᵤᵢₑᵢₒᵤₖₗₘₙₒₚₓᵩᵣₛₜᵤᵥₓₜₜₘₙₓₓₓ₀₁₂₃₄₅₆₇₈₉');
			-- burbujas									   
			WHEN 'bubble' THEN transformed_text := TRANSLATE(text_to_print, 
												 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 
												 'ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩⒶⒷⒸⒹⒺⒻⒼⒽⒾⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏ⓪①②③④⑤⑥⑦⑧⑨');
			-- invertido									 
			WHEN 'inverted' THEN transformed_text := TRANSLATE(text_to_print, 
												  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 
												  'ɐqɔpǝɟƃɥᴉɾʞןɯuodbɹsʇnʌʍxʎz∀ԐↃpƎℲ⅁HIſ⋊⅃WNOԀΌɹS⊥∩ΛMX⅄Z');
			ELSE
					 
					RAISE EXCEPTION E'Tipografía no soportada: %', typography;
 
		END CASE; 

		
    ELSE
        transformed_text := text_to_print;
    END IF;
 
 

    -- Construir texto formateado
    formatted_text := timestamp_prefix || transformed_text;



    -- Definir códigos de color
    CASE lower(color)
		WHEN   '' THEN color_code := E'';
        WHEN 'black' THEN color_code := E'\033[30m';
        WHEN 'red' THEN color_code := E'\033[31m';
        WHEN 'green' THEN color_code := E'\033[32m';
        WHEN 'yellow' THEN color_code := E'\033[33m';
        WHEN 'blue' THEN color_code := E'\033[34m';
        WHEN 'magenta' THEN color_code := E'\033[35m';
        WHEN 'cyan' THEN color_code := E'\033[36m';
        WHEN 'white' THEN color_code := E'\033[37m';
        ELSE
            RAISE EXCEPTION 'Color no soportado: %', color;
    END CASE;

    -- Definir códigos de estilo
    CASE lower(style)
		WHEN '' THEN style_code := E'';
        WHEN 'bold' THEN style_code := E'\033[1m';
        WHEN 'dim' THEN style_code := E'\033[2m';
        WHEN 'italic' THEN style_code := E'\033[3m';
        WHEN 'underline' THEN style_code := E'\033[4m';
        WHEN 'blink' THEN style_code := E'\033[5m';
        WHEN 'reverse' THEN style_code := E'\033[7m';
        WHEN 'hidden' THEN style_code := E'\033[8m';
        ELSE
            RAISE EXCEPTION E'Estilo no soportado: %', style;
    END CASE;
 

	IF color = '' AND style = '' THEN
		reset_code := '';
	END IF;


    -- Imprimir con o sin color/estilo según el cliente
    IF is_psql THEN
        --RAISE NOTICE E'\r  %', style_code || color_code || formatted_text || reset_code;
		formatted_text := E'\r' || style_code || color_code || formatted_text || reset_code;
		
		IF is_return THEN
			RAISE NOTICE '%', formatted_text;
			RETURN NULL;
		ELSE
			RETURN formatted_text;
		END IF;
		
    ELSE
        
		
		IF is_return THEN
			RAISE NOTICE E'\r%', formatted_text;
			RETURN NULL;
		ELSE
			RETURN formatted_text;
		END IF;
		
		
    END IF;
	
	

    -- Registrar en archivo si es necesario
    IF log_to_file IS NOT NULL THEN
        PERFORM pg_file_write(log_filepath, formatted_text || E'\n', true);
    END IF;
	
	
	
END;
$$ LANGUAGE plpgsql
SET client_min_messages = 'notice' 
;




        
        
        
         
        
          
        
        /*


---- RETORNO DE TEXTO ESCAPE
SELECT notice_color('Text Transformado bold' , 'YELLOW', 'bold'  , FALSE );
		
		
---- COLORES 
SELECT notice_color('Text Color black'   , 'black' , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color red'    , 'red'  , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color green'    , 'green'  , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color yellow'   , 'yellow' , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color blue'    , 'blue'  , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color magenta'  , 'magenta', 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color cyan'    , 'cyan'  , 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Color white'    , 'white'  , 'blink'  ,NULL, FALSE);
		
		
---- ESTILOS  
SELECT notice_color('Text Estilo bold'  , '', 'bold'  ,NULL, FALSE);
SELECT notice_color('Text Estilo dim'    , '', 'dim'    ,NULL, FALSE);
SELECT notice_color('Text Estilo italic' , '', 'italic' ,NULL, FALSE);
SELECT notice_color('Text Estilo underlin', '', 'underline' ,NULL, FALSE);
SELECT notice_color('Text Estilo blink'  , '', 'blink'  ,NULL, FALSE);
SELECT notice_color('Text Estilo reverse', '', 'reverse' ,NULL, FALSE);
SELECT notice_color('Text Estilo hidden' , '', 'hidden'  ,NULL, FALSE);



---- TRANSFORMACIONES   
SELECT notice_color('Text Transformado bold' , '', ''  ,NULL, FALSE,NULL ,'bold' );
SELECT notice_color('Text Transformado italic' , '', ''  ,NULL, FALSE,NULL ,'italic' );
SELECT notice_color('Text Transformado bold_italic' , '', ''  ,NULL, FALSE,NULL ,'bold_italic' );
SELECT notice_color('Text Transformado underlined' , '', ''  ,NULL, FALSE,NULL ,'underlined' );
SELECT notice_color('Text Transformado strikethrough' , '', ''  ,NULL, FALSE,NULL ,'strikethrough' );
SELECT notice_color('Text Transformado superscript' , '', ''  ,NULL, FALSE,NULL ,'superscript' );
SELECT notice_color('Text Transformado subscript' , '', ''  ,NULL, FALSE,NULL ,'subscript' );
SELECT notice_color('Text Transformado bubble' , '', ''  ,NULL, FALSE,NULL ,'bubble' );
SELECT notice_color('Text Transformado inverted' , '', ''  ,NULL, FALSE,NULL ,'inverted' );

 

--- MAYÚSCULAS Y MINÚSCULAS
SELECT notice_color('Text Transformado bold' , '', '' ,TRUE  ,NULL, false, 'upper' ,'bold' );
SELECT notice_color('TEXT TRANSFORMADO BOLD' , '', '' ,TRUE  ,NULL, false, 'lower' ,'bold' );




 

*/
 
 
 