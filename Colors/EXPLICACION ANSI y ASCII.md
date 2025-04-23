# Detalle sobre los códigos de control ANSI y ASCII:

# ASCII (American Standard Code for Information Interchange)
ASCII es un estándar de codificación de caracteres que asigna valores numéricos (0-127) a letras, números, símbolos y caracteres de control. Por ejemplo:
- 65 = 'A'
- 97 = 'a'
- 48 = '0'
- 32 = espacio

# ANSI (American National Standards Institute)
ANSI extendió ASCII para incluir secuencias de escape que controlan la forma en que se muestra el texto en la terminal. Estas secuencias comienzan con el carácter de escape (ESC, valor ASCII 27).

## Formas de escribir el carácter de escape:
1. `\033` - Notación octal
2. `\x1B` - Notación hexadecimal
3. `\e` - Notación de escape (en algunos sistemas)

## Estructura de una secuencia ANSI:
```
\033[<n>m - Para colores y estilos
\033[<n>;<n>H - Para posicionamiento
```

## Principales códigos ANSI:

1. **Movimiento del cursor:**
```
\033[<n>A - Mover cursor arriba n líneas
\033[<n>B - Mover cursor abajo n líneas
\033[<n>C - Mover cursor derecha n columnas
\033[<n>D - Mover cursor izquierda n columnas
\033[<n>G - Mover cursor a columna n similar que \r
\033[<n>;<m>H - Mover cursor a línea n, columna m
```

2. **Limpieza de pantalla:**
```
\033[2J - Limpiar toda la pantalla
\033[K - Limpiar desde el cursor hasta el final de la línea
\033[1K - Limpiar desde el inicio de la línea hasta el cursor
\033[2K - Limpiar toda la línea
```

3. **Colores de texto (foreground):**
```
\033[30m - Negro
\033[31m - Rojo
\033[32m - Verde
\033[33m - Amarillo
\033[34m - Azul
\033[35m - Magenta
\033[36m - Cyan
\033[37m - Blanco
\033[39m - Color por defecto
```

4. **Colores de fondo (background):**
```
\033[40m - Negro
\033[41m - Rojo
\033[42m - Verde
\033[43m - Amarillo
\033[44m - Azul
\033[45m - Magenta
\033[46m - Cyan
\033[47m - Blanco
\033[49m - Color por defecto
```

5. **Estilos de texto:**
```
\033[0m - Reset todos los atributos
\033[1m - Negrita
\033[2m - Tenue
\033[3m - Cursiva
\033[4m - Subrayado
\033[5m - Parpadeo
\033[7m - Invertir colores
\033[8m - Oculto
\033[9m - Tachado
```

6. **Combinaciones:**
Puedes combinar múltiples códigos usando punto y coma. Por ejemplo:
```
\033[1;31m - Texto rojo y negrita
\033[4;44;37m - Texto blanco, subrayado, con fondo azul
```

## Ejemplos prácticos:

1. **Mover y escribir:**
```sql
-- Mover cursor 5 líneas arriba y escribir en rojo
RAISE NOTICE E'\033[5A\033[31mTexto en rojo';
```

2. **Limpiar y posicionar:**
```sql
-- Limpiar pantalla y escribir en posición específica
RAISE NOTICE E'\033[2J\033[5;10HTexto en posición 5,10';
```

3. **Estilo complejo:**
```sql
-- Texto negrita, subrayado en amarillo con fondo azul
RAISE NOTICE E'\033[1;4;33;44mTexto estilizado\033[0m';
```

## Diferencias clave:
- ASCII: Define cómo se codifican los caracteres básicos
- ANSI: Extiende ASCII para incluir control de formato y color

## Usos comunes:
1. Interfaces de línea de comandos
2. Logs con colores
3. Barras de progreso
4. Menús interactivos
5. Resaltado de sintaxis

## Consideraciones:
1. No todas las terminales soportan todos los códigos ANSI
2. Algunos sistemas pueden requerir configuración especial
3. Windows tradicionalmente ha tenido un soporte limitado



1. **los mas usados**
```
    color_rojo TEXT := '\033[31m'; -- Código ANSI para texto rojo
    reset_color TEXT := '\033[0m';  -- Código ANSI para resetear el color
	
	CLEAR_SCREEN text := E'\033[2J\033[H'; -- Limpia pantalla y mueve cursor al inicio
    CARRIAGE_RETURN text := E'\r'; -- Retorno de carro (vuelve al inicio de línea)
    
  \033[<n>G - Mover cursor a columna n similar que \r    

```

