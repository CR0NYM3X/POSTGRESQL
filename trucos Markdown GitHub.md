# trucos Markdown GitHub


```stl
solid house_example
  facet normal 0.0 0.0 1.0
    outer loop
      vertex 0.0 0.0 0.0   // Punto A
      vertex 2.0 0.0 0.0   // Punto B
      vertex 2.0 1.0 0.0   // Punto C
    endloop
  endfacet
  facet normal 0.0 0.0 1.0
    outer loop
      vertex 0.0 0.0 0.0   // Punto A
      vertex 2.0 1.0 0.0   // Punto C
      vertex 0.0 1.0 0.0   // Punto D
    endloop
  endfacet
  facet normal 0.0 0.0 -1.0
    outer loop
      vertex 0.0 0.0 1.0   // Punto E
      vertex 2.0 0.0 1.0   // Punto F
      vertex 2.0 1.0 1.0   // Punto G
    endloop
  endfacet
  facet normal 0.0 0.0 -1.0
    outer loop
      vertex 0.0 0.0 1.0   // Punto E
      vertex 2.0 1.0 1.0   // Punto G
      vertex 0.0 1.0 1.0   // Punto H
    endloop
  endfacet
  facet normal -1.0 0.0 0.0
    outer loop
      vertex 0.0 0.0 0.0   // Punto A
      vertex 0.0 1.0 0.0   // Punto D
      vertex 0.0 1.0 1.0   // Punto H
    endloop
  endfacet
  facet normal -1.0 0.0 0.0
    outer loop
      vertex 0.0 0.0 0.0   // Punto A
      vertex 0.0 1.0 1.0   // Punto H
      vertex 0.0 0.0 1.0   // Punto E
    endloop
  endfacet
  facet normal 1.0 0.0 0.0
    outer loop
      vertex 2.0 0.0 0.0   // Punto B
      vertex 2.0 1.0 0.0   // Punto C
      vertex 2.0 1.0 1.0   // Punto G
    endloop
  endfacet
  facet normal 1.0 0.0 0.0
    outer loop
      vertex 2.0 0.0 0.0   // Punto B
      vertex 2.0 1.0 1.0   // Punto G
      vertex 2.0 0.0 1.0   // Punto F
    endloop
  endfacet
  // Techo
  facet normal 0.0 1.0 0.0
    outer loop
      vertex 0.0 1.0 0.0   // Punto D
      vertex 2.0 1.0 0.0   // Punto C
      vertex 2.0 1.0 1.0   // Punto G
    endloop
  endfacet
  facet normal 0.0 1.0 0.0
    outer loop
      vertex 0.0 1.0 0.0   // Punto D
      vertex 2.0 1.0 1.0   // Punto G
      vertex 0.0 1.0 1.0   // Punto H
    endloop
  endfacet
  // Puerta
  facet normal 0.0 -1.0 0.0
    outer loop
      vertex 0.8 0.0 0.0   // Punto I
      vertex 1.2 0.0 0.0   // Punto J
      vertex 1.2 0.6 0.0   // Punto K
    endloop
  endfacet
  facet normal 0.0 -1.0 0.0
    outer loop
      vertex 0.8 0.0 0.0   // Punto I
      vertex 1.2 0.6 0.0   // Punto K
      vertex 0.8 0.6 0.0   // Punto L
    endloop
  endfacet
  // Ventana
  facet normal 0.0 0.0 -1.0
    outer loop
      vertex 1.5 0.3 1.0   // Punto M
      vertex 1.7 0.3 1.0   // Punto N
      vertex 1.7 0.5 1.0   // Punto O
    endloop
  endfacet
  facet normal 0.0 0.0 -1.0
    outer loop
      vertex 1.5 0.3 1.0   // Punto M
      vertex 1.7 0.5 1.0   // Punto O
      vertex 1.5 0.5 1.0   // Punto P
    endloop
  endfacet
endsolid

```


<picture>
 <source media="(prefers-color-scheme: dark)" srcset="YOUR-DARKMODE-IMAGE">
 <source media="(prefers-color-scheme: light)" srcset="YOUR-LIGHTMODE-IMAGE">
 <img alt="YOUR-ALT-TEXT" src="YOUR-DEFAULT-IMAGE">
</picture>


MANUAL :  https://docs.github.com/es/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax

:footprints: EMOJIS :  https://github.com/ikatyang/emoji-cheat-sheet/blob/master/README.md

<details>

<summary>Puedes agregar secciones</summary>

### You can add a header

You can add text within a collapsed section. 

You can add an image or a code block, too.

```ruby
   puts "Hello World"
```

</details>


- [x] #739
- [ ] https://github.com/octo-org/octo-repo/issues/740
- [ ] Add delight to the experience when all tasks are complete :tada:

---- ORDENAR DE 1 , 2,3 
1. James Madison
1. James Monroe
1. John Quincy Adams

> [!NOTE]
> Esto es importante

> [!TIP]
> Esto es TIP

> [!IMPORTANT]
> Esto es TIP

> [!WARNING]
> Esto es TIP

> [!CAUTION]
> Esto es TIP

The background color is `#ffffff` for light mode and `#000000` for dark mode.
> HOLA ESTE TEXTO NO ES IMPORTANTE

---

- [Sección 1](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/trucos%20Markdown%20GitHub.md#enlaces)
  - [Subsección 1.1](#subsección-11)
  - [Subsección 1.2](#subsección-12)
- [Sección 2](#sección-2)


# Formas de Consultar o Buscar un usuario role
Contenido de la sección 1...

## Subsección 1.1
Contenido de la subsección 1.1...

### Subsección 1.2
Contenido de la subsección 1.2...

# Sección 2
Contenido de la sección 2...


### salto del linea
\<br>

Énfasis y negritas:
*Texto en cursiva*
_Texto en cursiva_
**Texto en negrita**


#### Listas ordenadas y no ordenadas: 
Copy code
- Elemento 1
- Elemento 2
  - Subelemento A
  - Subelemento B
1. Primer elemento
2. Segundo elemento

## Enlaces: 
[Google](https://www.google.com)

### Imágenes
![Logo de GitHub](https://github.com/logos/github-logo.png)

### colocar en gris el texto
`asdsa`

### hacer una cita
> Esto es una cita.
>> Esto es una cita anidada.

### Líneas horizontales: 
---

### Escapar de caracteres especiales: 
\*Esto no es una lista en Markdown\*

### Tablas

| Encabezado 1 | Encabezado 2 |
|--------------|--------------|
| Celda 1,1    | Celda 1,2    |
| Celda 2,1    | Celda 2,2    |


#### Notas al pie de página:
Esto es un ejemplo de una nota al pie de página[^1].
[^1]: Esta es la nota al pie de página.


### Listas de tareas:
- [ ] Tarea por hacer
- [x] Tarea completada


Esto es código en línea: `print("Hola, mundo")`

```sh python
def mi_funcion():
    print("Hola, mundo")
```
### Texto tachado	
Esto es ~~texto tachado~~.

### este es como cuando pones codigo pero no sale opcion para copiar
<pre>

**Esto es un bloque de código sin resaltado de sintaxis.**

</pre>

#### Comentarios solo cuando ves el codigo
<!-- Esto es un comentario -->

### CEntrar texto
$$
bueno bueno bueno
$$

