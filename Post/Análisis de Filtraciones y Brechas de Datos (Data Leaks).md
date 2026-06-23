 

### 🔍 Análisis de Filtraciones y Brechas de Datos (Data Leaks)

* **[DeHashed](https://dehashed.com/search#breachCheck)**
* **¿Para qué sirve?** Es un motor de búsqueda de credenciales hackeadas extremadamente potente. Indexa miles de millones de registros filtrados de la Dark Web y hackeos masivos, permitiendo buscar por nombres, correos, IPs, nombres de usuario y contraseñas.
* **¿Para qué lo usan? / Caso de uso:** Lo utilizan analistas OSINT para el *pivoting* (saltar de un dato a otro). Si investigas un correo electrónico, buscas en DeHashed para encontrar qué contraseñas usaba esa persona en el pasado y usar esas mismas contraseñas para rastrear otras cuentas antiguas del objetivo.


* **[LeakPeek](https://leakpeek.com/)**
* **¿Para qué sirve?** Similar a DeHashed, es una base de datos de consulta de brechas de datos que expone registros de información que han sido robados en filtraciones de grandes empresas u organizaciones.
* **¿Para qué lo usan? / Caso de uso:** Se utiliza para verificar de manera rápida si una empresa o individuo específico tiene credenciales expuestas en internet profunda, permitiendo descubrir combinaciones antiguas de usuario/contraseña asociadas a un dominio.


* **[Have I Been Pwned](https://haveibeenpwned.com/)** *(Entrada fusionada)*
* **¿Para qué sirve?** Es la base de datos de referencia global y pública para verificar de forma gratuita si cuentas de correo electrónico o números de teléfono han sido comprometidos en violaciones de datos. Es la base de datos pública más confiable del mundo para saber si tus datos personales (correos, contraseñas, teléfonos) han sido filtrados en hackeos masivos a empresas (como LinkedIn, Adobe, etc.).
* **¿Para qué lo usan? / Caso de uso:** Es el punto de partida en auditorías defensivas y OSINT pasivo para mapear rápidamente el nivel de exposición histórica de los correos corporativos o personales de un objetivo. Se utiliza para auditorías rápidas de credenciales. Si sospechas que una de tus contraseñas antiguas ha sido comprometida en una filtración masiva, recurres a este sitio para confirmar si debes cambiarla urgentemente.


* **[Mozilla Monitor](https://monitor.mozilla.org/)**
* **¿Para qué sirve?** Es un servicio gratuito respaldado por la Fundación Mozilla que se conecta con bases de datos de filtraciones para alertar si tus datos aparecen en la Dark Web.
* **¿Para qué lo usan? / Caso de uso:** Se utiliza en la seguridad defensiva personal o corporativa para mantener un monitoreo continuo y automatizado; emite alertas tempranas si un correo bajo investigación es comprometido en un nuevo hackeo.


* **[Google Dark Web Report](https://one.google.com/)**
* **¿Para qué sirve?** Es una utilidad integrada dentro de los servicios de Google One que escanea de forma constante la Dark Web en busca de información de identificación personal (SSN, correos, contraseñas, nombres, direcciones).
* **¿Para qué lo usan? / Caso de uso:** Casos de protección de identidad ejecutiva. Se implementa para monitorear perfiles VIP dentro de una organización y mitigar riesgos de suplantación de identidad o ataques dirigidos (*Spear Phishing*).



---

### 🛡️ Búsqueda de Personas, Usuarios y Correos (Pivoting de Identidad)

* **[WhatsMyName App](https://whatsmyname.app/)**
* **¿Para qué sirve?** Es una herramienta de enumeración que busca un nombre de usuario (*username*) específico en cientos de plataformas web, foros y redes sociales de manera simultánea.
* **¿Para qué lo usan? / Caso de uso:** Es fundamental para perfilar objetivos. Si descubres el alias de un investigado en un videojuego, usas esta app para ver si reutilizó el mismo alias en foros de discusión, portales de empleo o redes sociales donde exponga su identidad real.


* **[IntelTechniques Email Search](https://inteltechniques.com/tools/Search.html)**
* **¿Para qué sirve?** Creado por el célebre experto en privacidad Michael Bazzell, este portal reúne un conjunto avanzado de herramientas y scripts optimizados para realizar búsquedas profundas de código abierto en motores de búsqueda enfocados en correos electrónicos.
* **¿Para qué lo usan? / Caso de uso:** Lo utilizan investigadores de fraude e investigadores privados para desglosar y exprimir información estructurada a partir de un correo electrónico huérfano, buscando su vinculación con registros públicos o combinaciones de búsquedas avanzadas (Google Dorks).


* **[Epieos](https://epieos.com/)**
* **¿Para qué sirve?** Es una herramienta OSINT excepcional que realiza búsquedas inversas de correos electrónicos y números de teléfono sin alertar al objetivo, revelando perfiles de Google vinculados, reseñas en Google Maps, cuentas de Skype y perfiles en plataformas de streaming o redes sociales.
* **¿Para qué lo usan? / Caso de uso:** Casos de verificación de perfiles y ciberinvestigaciones. Sirve para corroborar si el remitente de un correo anónimo dejó reseñas públicas en Google Maps que revelen su ubicación física o sus hábitos diarios.


* **[Behind The Email](https://behindtheemail.com)**
* **¿Para qué sirve?** Es una herramienta de OSINT (Inteligencia de Fuentes Abiertas). Sirve para investigar qué cuentas o perfiles en redes sociales y plataformas web están vinculados a un correo electrónico específico.
* **¿Para qué lo usan? / Caso de uso:** Lo utilizan analistas de seguridad e investigadores para verificar la identidad de un remitente sospechoso, combatir fraudes de suplantación de identidad o auditar la exposición de tu propia huella digital en internet.


* **[ClarityCheck](https://claritycheck.com/) y [OkCaller**](https://okcaller.com/)
* **¿Para qué sirve?** Son directorios de búsqueda inversa de números telefónicos enfocados en identificar registros públicos, operadoras telefónicas y nombres asociados a líneas móviles o fijas (principalmente en Norteamérica).
* **¿Para qué lo usan? / Caso de uso:** Se usan en investigaciones de ciberacoso o estafas telefónicas para desenmascarar identidades detrás de números desconocidos o llamadas sospechosas VOIP (Voz por IP).


* **[OSINT Industries](https://www.osint.industries/)**
* **¿Para qué sirve?** Una plataforma comercial de nivel institucional para inteligencia de fuentes abiertas que conecta correos y teléfonos con más de 300 plataformas en tiempo real de forma masiva.
* **¿Para qué lo usan? / Caso de uso:** Investigaciones corporativas a gran escala. Es utilizada por agencias gubernamentales y corporativos privados para agilizar los flujos de trabajo e identificar instantáneamente a los propietarios de cuentas de correo maliciosas.



---

### 👁️ Marcos de Trabajo (Frameworks) y Automatización OSINT

* **[OSINT Framework](https://osintframework.com/)**
* **¿Para qué sirve?** Es un mapa mental interactivo que organiza de forma lógica y estructurada casi todas las fuentes de información disponibles en la web para realizar OSINT (clasificadas por dirección IP, geolocalización, metadatos, registros públicos, etc.).
* **¿Para qué lo usan? / Caso de uso:** Es la "Biblia" de consulta para investigadores. Se utiliza cuando el analista se queda estancado en un punto de la investigación y necesita ideas o herramientas específicas para rastrear un dato inusual (como un número de placa, patentes o registros de aviación).


* **[OSINT Rocks](https://osint.rocks/)**
* **¿Para qué sirve?** Es un portal especializado que consolida guías, repositorios de herramientas y recursos selectos para profesionales de la inteligencia de fuentes abiertas.
* **¿Para qué lo usan? / Caso de uso:** Se utiliza para mantenerse actualizado sobre las últimas metodologías de investigación y descubrir nuevas utilidades de software antes de que queden obsoletas debido a los cambios de políticas de las redes sociales.


* **[SpiderFoot](https://www.spiderfoot.net/) / [TheHarvester](https://github.com/laramies/theHarvester) / [Sherlock OSINT**](https://github.com/sherlock-project/sherlock)
* **¿Para qué sirven?** Son herramientas automatizadas de recolección de información que se ejecutan por línea de comandos (CLI). **Sherlock** busca nombres de usuario en más de 400 webs. **TheHarvester** recopila subdominios, correos, IPs y nombres de un dominio usando motores de búsqueda. **SpiderFoot** automatiza el escaneo completo contra más de 100 fuentes públicas. *(Nota: Para Sherlock puedes consultar el sitio informativo [SherlockOSINT](https://sherlockosint.com/)).*
* **¿Para qué lo usan? / Caso de uso:** Reconocimiento en la fase inicial de un *Penetration Testing*. En lugar de buscar manualmente durante días, los analistas ejecutan estas herramientas para mapear en minutos la superficie de ataque y los correos de una empresa objetivo.


* **[OSINTgram](https://github.com/Datalux/Osintgram)**
* **¿Para qué sirve?** Es un framework de consola diseñado específicamente para realizar análisis forense y OSINT en perfiles de Instagram. Permite extraer datos que visualmente tomaría horas recopilar.
* **¿Para qué lo usan? / Caso de uso:** Se usa para obtener análisis de relaciones. Permite listar de forma automatizada las direcciones de correo provistas en las biografías, los usuarios que más comentan las fotos del objetivo, ubicaciones frecuentes etiquetadas y fotos en las que ha recibido "likes".



---

### 🌐 Buscadores Avanzados e Infraestructura de Red

* **[Shodan](https://www.shodan.io/)**
* **¿Para qué sirve?** Conocido como el "buscador de los dispositivos conectados", Shodan no indexa páginas web, sino servidores, routers, cámaras de seguridad, semáforos, plantas de energía y cualquier dispositivo IoT con una IP pública.
* **¿Para qué lo usan? / Caso de uso:** Ciberinteligencia y auditorías de infraestructura. Los analistas lo usan para encontrar servidores expuestos a internet que pertenezcan a la organización que investigan y verificar si tienen puertos vulnerables o contraseñas por defecto.


* **[Yandex](https://yandex.com/)**
* **¿Para qué sirve?** Es el motor de búsqueda más importante de Rusia.
* **¿Para qué lo usan? / Caso de uso:** En el mundo OSINT es venerado por poseer el algoritmo de **búsqueda inversa de imágenes** más preciso del mercado. Se utiliza para encontrar clones de personas, identificar ubicaciones geográficas exactas basadas en paisajes arquitectónicos y localizar perfiles en redes sociales rusas o asiáticas que Google ignora por completo.


* **[Twitter / X](https://twitter.com/)**
* **¿Para qué sirve?** Red social de microblogging.
* **¿Para qué lo usan? / Caso de uso:** Es la mina de oro para SOCMINT (Inteligencia de Redes Sociales) en tiempo real. Sus capacidades de "Búsqueda Avanzada" se utilizan para rastrear qué decía un objetivo en una fecha exacta, geolocalizar declaraciones públicas o seguir el rastro de ataques informáticos en el momento preciso en que ocurren.



---

### 📸 Análisis de Imágenes, Rostros y Reconocimiento Biométrico

* **[TinEye](https://tineye.com/)**
* **¿Para qué sirve?** Un motor de búsqueda y reconocimiento inverso de imágenes especializado en encontrar modificaciones y duplicados de archivos gráficos en la red.
* **¿Para qué lo usan? / Caso de uso:** Verificación de autenticidad en investigaciones periodísticas u OSINT. Se usa para descubrir si una fotografía de evidencia ha sido recortada, editada con Photoshop o extraída de un banco de imágenes antiguo.


* **[PimEyes](https://pimeyes.com/)**
* **¿Para qué sirve?** Es un motor de búsqueda de reconocimiento facial extremadamente avanzado que utiliza Inteligencia Artificial para rastrear el rostro de una persona a lo largo de todo internet.
* **¿Para qué lo usan? / Caso de uso:** Investigaciones de identidad y sextorsión. Se utiliza para subir la foto de un rostro y encontrar páginas web, blogs, artículos periodísticos o foros oscuros donde aparezca esa misma persona, incluso si la foto es antigua o de baja calidad.


* **[FaceCheck ID](https://facecheck.id/es)**
* **¿Para qué sirve?** Un motor de búsqueda biométrica facial enfocado en comparar rostros contra bases de datos de sospechosos, delincuentes, perfiles en redes sociales y registros públicos en internet.
* **¿Para qué lo usan? / Caso de uso:** Casos de verificación de confianza y estafas de romance (*catfishing*). Se utiliza para corroborar si la persona con la que un cliente habla por internet es real o si su fotografía corresponde a un perfil criminal o a una identidad suplantada.


* **[Exposing.ai](https://exposing.ai)**
* **¿Para qué sirve?** Es una herramienta de privacidad enfocada en Inteligencia Artificial. Te permite saber si las fotos que subiste alguna vez a plataformas públicas (como Flickr) fueron utilizadas sin tu consentimiento para entrenar sistemas de reconocimiento facial.
* **¿Para qué lo usan? / Caso de uso:** Lo usan activistas y usuarios que buscan defender su privacidad biométrica, verificando si sus rostros están formando parte de tecnologías de vigilancia comercial o gubernamental sin saberlo.



---

### 🔒 Privacidad, Anonimato y Análisis Forense

* **[Temp-Mail](https://temp-mail.org/es/)**
* **¿Para qué sirve?** Proveedor de correos electrónicos temporales, desechables y anónimos que expiran después de un tiempo determinado.
* **¿Para qué lo usan? / Caso de uso:** Creación de *Sock Puppets* (perfiles falsos de investigación). Los analistas OSINT jamás usan sus cuentas reales para investigar; utilizan Temp-Mail para registrarse en foros sospechosos o plataformas donde necesitan husmear sin dejar rastros de su identidad.


* **[VirusTotal](https://virustotal.com/)** *(Entrada fusionada)*
* **¿Para qué sirve?** Analizador de malware y archivos maliciosos mediante más de 70 motores antivirus independientes. Es la navaja suiza de la seguridad en internet. Analiza archivos sospechosos o enlaces (URLs) antes de que los abras, pasándolos simultáneamente por más de 70 antivirus y motores de seguridad.
* **¿Para qué lo usan? / Caso de uso:** Análisis de amenazas y enlaces. En una investigación OSINT, si un objetivo te envía un archivo o un enlace para rastrear tu IP de vuelta, se pasa primero por VirusTotal para certificar que estás a salvo de troyanos o ataques dirigidos. Se usa como primera línea de defensa ante la duda. Si te llega un correo con un archivo adjunto extraño o un enlace de procedencia dudosa, lo pasas por aquí para descartar virus o ataques de *phishing* antes de interactuar con él.


* **[ViewExifData](https://www.viewexifdata.com/)**
* **¿Para qué sirve?** Es un visor online de metadatos EXIF. Extrae la información oculta dentro de las fotografías (modelo de cámara, software de edición, fecha y, lo más importante, **coordenadas GPS** de donde se tomó la foto).
* **¿Para qué lo usan? / Caso de uso:** Geolocalización forense. Si un objetivo publica la foto de un paisaje, el analista la procesa en este sitio para ver si la cámara guardó en secreto las coordenadas de latitud y longitud del escondite de la persona.


* **[Wayback Machine (Internet Archive)](https://web.archive.org)**
* **¿Para qué sirve?** Es la biblioteca digital más grande del mundo que guarda capturas de pantalla históricas de casi cualquier página web desde los inicios del internet.
* **¿Para qué lo usan? / Caso de uso:** Preservación de evidencia y rastreo de contenido borrado. Si un criminal borra su página web de estafas o un político borra un tuit comprometedor, el analista OSINT viaja en el tiempo usando esta web para extraer la información tal como estaba guardada hace meses o años.



---

### 🛠️ Diagnóstico Técnico y Privacidad del Navegador

* **[Am I Unique?](https://amiunique.org)**
* **¿Para qué sirve?** Analiza el *Browser Fingerprinting* (huella digital del navegador). Aunque borres las cookies o uses modo incógnito, las páginas web pueden identificarte por la resolución de tu pantalla, tus fuentes instaladas y tus extensiones. Este sitio te dice qué tan único (y rastreable) eres.
* **¿Para qué lo usan? / Caso de uso:** Se usa para comprobar la efectividad de tus herramientas antirrastreo. Los usuarios preocupados por la privacidad lo consultan para ver si la configuración de su navegador los hace "demasiado únicos" y fáciles de seguir por las empresas publicitarias.


* **[BrowserLeaks](https://browserleaks.com)**
* **¿Para qué sirve?** Similar a la número 3, pero mucho más técnica y profunda. Es una suite completa para auditorías de seguridad en el navegador: revela qué sabe la web sobre tu WebRTC (que puede filtrar tu IP real), tu tarjeta gráfica, tu batería y tu geolocalización.
* **¿Para qué lo usan? / Caso de uso:** Lo utilizan administradores de sistemas y entusiastas de la ciberseguridad para realizar pruebas técnicas exhaustivas y ajustar con precisión los bloqueadores de scripts o extensiones de privacidad del navegador.


* **[DNS Leak Test](https://dnsleaktest.com)**
* **¿Para qué sirve?** Verifica la salud de tu VPN. A veces, aunque una VPN dice que oculta tu ubicación, tu navegador sigue enviando solicitudes de traducción de páginas (DNS) a tu proveedor de internet real, revelando tu ubicación e identidad.
* **¿Para qué lo usan? / Caso de uso:** Se utiliza inmediatamente después de encender una VPN nueva o de actualizar el sistema, asegurando que tu proveedor de internet local no esté registrando en secreto las páginas que visitas.



---

### 🧹 Limpieza Digital y Utilidades Generales

* **[Just Delete Me](https://justdeleteme.xyz)**
* **¿Para qué sirve?** Es un directorio de enlaces directos para eliminar cuentas en cientos de servicios web. Muchas empresas ocultan el botón de "eliminar cuenta" bajo siete llaves para que no te vayas; esta web rompe esa barreara.
* **¿Para qué lo usan? / Caso de uso:** Se usa para "limpieza digital" express. Cuando decides darte de baja de múltiples servicios antiguos que ya no usas y quieres reducir drásticamente la cantidad de empresas que guardan tus datos personales.


* **[Should I Remove It?](https://shouldiremoveit.com)**
* **¿Para qué sirve?** Identifica programas basura (*bloatware*), barras de herramientas molestas o adware que ralentizan tu computadora de manera silenciosa. Te dice qué programas son seguros y cuáles deberías borrar.
* **¿Para qué lo usan? / Caso de uso:** Se utiliza para optimizar computadoras nuevas o lentas. Sirve para revisar el listado de aplicaciones instaladas de fábrica y decidir cuáles son seguras de desinstalar sin romper el sistema operativo.


* **[12ft Ladder](https://www.google.com/search?q=https://12ft.io)**
* **¿Para qué sirve?** Intenta saltarse los muros de pago (*paywalls*) de los periódicos y sitios de noticias para dejarte leer el artículo gratis.
* **¿Nota de seguridad/ética? / Caso de uso:** Esta no es una herramienta de seguridad, sino de evasión. Se usa para saltar restricciones de lectura mostrando la versión de la página optimizada para el robot de indexación de Google (Googlebot). *Nota actual: Muchos medios grandes ya han bloqueado este truco, por lo que su efectividad es variable.*

 

¡Oído cocina! Aquí tienes la versión rápida, al grano y sin rodeos:

### 🛒 Detección de Estafas

* **[desenmascara.me](https://desenmascara.me/)**: Sirve para comprobar si una tienda online es **falsa o un fraude** antes de comprar.

 

### 📧 Listas Negras (Si tus correos rebotan o van a Spam)

* **[blacklistalert.org](https://www.blacklistalert.org/)**: Revisa rápido si la IP de tu servidor está marcada como **emisora de correo no deseado**.
* **[blacklistmaster.com](https://www.blacklistmaster.com/)**: Lo mismo que la anterior, pero optimizado para revisar **muchas IPs a la vez**.
* **[mxtoolbox.com](https://mxtoolbox.com/blacklists.aspx)**: La más profesional. Te dice si estás bloqueado y **cómo salir de la lista negra**.
 

### 🛡️ Ciberseguridad y Hackeos

* **[pentester.com](https://pentester.com/)**: Busca **fallos de seguridad** en páginas web y revisa si tus correos o contraseñas se han **filtrado en internet**.


---


Aquí tienes la lista explicada de forma rápida y directa. Todas estas herramientas son motores de búsqueda de **ciberinteligencia (OSINT)**, diseñados para escanear internet y encontrar dispositivos expuestos o amenazas:

### 🌐 Buscadores de Dispositivos e Infraestructura (Estilo "Shodan")

* **[zoomeye.org](https://www.zoomeye.org/)**: Busca cámaras, routers, servidores y dispositivos IoT conectados a internet, detallando sus fallos de seguridad.
* **[search.censys.io](https://search.censys.io/) / [platform.censys.io**](https://platform.censys.io/home): Analiza y encuentra servidores, redes y certificados SSL de todo el mundo para evaluar su nivel de exposición.
* **[criminalip.io](https://www.criminalip.io/en)**: Rastrea direcciones IP y dominios para detectar reputación fraudulenta, phishing y ciberamenazas en tiempo real.
* **[onyphe.io](https://www.onyphe.io)**: Escanea internet constantemente para recopilar datos sobre servidores expuestos y ayudar a empresas a ver qué información suya es pública.
* **[scans.io](https://www.scans.io)**: Un repositorio histórico de datos que almacena los resultados de escaneos masivos de internet (muy usado por investigadores).

 **[netlas.io](https://netlas.io/)**: Es otro motor de búsqueda de ciberinteligencia (OSINT), muy similar a Shodan o Censys.


### 🛡️ Detección de Amenazas y Especializados

* **[ismalicious.com](https://ismalicious.com/)**: Una herramienta rápida para comprobar si una página web o un dominio es **malicioso, fraudulento o tiene virus**.
* **[mrlooquer.com](https://www.mrlooquer.com/)**: Un buscador de ciberinteligencia especializado exclusivamente en descubrir y analizar dispositivos que utilizan el protocolo de internet **IPv6**.
 



---
 
### 🌐 Motores de Búsqueda de Ciberespacio

* **[FOFA](https://fofa.info)**: Clon y alternativa masiva a Shodan enfocada en componentes web.
* **[Hunter.how](https://hunter.how)**: Buscador rápido de activos globales y mapeo de certificados.
* **[Quake](https://quake.360.net)**: Mapeo de ciberespacio y topología de red global.
* **[Odin](https://odin.io)**: Descubrimiento de activos y gestión de superficie de ataque.

 
### 🛡️ Vulnerabilidades y Tráfico

* **[LeakIX](https://leakix.net)**: Rastreador de malas configuraciones y bases de datos expuestas.
* **[GreyNoise](https://greynoise.io)**: Analizador del ruido de fondo e IPs que escanean internet.
* **[BinaryEdge](https://binaryedge.io)**: Escáner de puertos y servicios críticos expuestos.
 

### 🗺️ DNS e Infraestructura

* **[SecurityTrails](https://securitytrails.com)**: Archivo histórico de registros DNS e IPs reales tras Cloudflare.
* **[FullHunt](https://fullhunt.io)**: Monitoreo y descubrimiento de la superficie de ataque en tiempo real.



```
-- Paginas para ver si son debiles mis contraseñas
https://haveibeenpwned.com/passwords
https://password.kaspersky.com/es/
https://ciberprotector.com/comprobador-de-contrase%C3%B1as/


```
