ZEN-server
==========

Es el módulo principal de ZEN, en el encontrarás todas las herramientas
necesarias para crear servidores web con NodeJS. La principal diferencia frente
a otras soluciones es la no dependencia de módulos de terceros, algo muy común
en proyectos NodeJS pero que a la larga, puede ofrecer problemas.

Nuestro compromiso es utilizar el menor número de dependencias y ofrecer nuestra
experiencia con NodeJS de una manera sencilla e intuitiva.

- [Inicio](#a.1)
  - [Instalación](#a.1.1)
  - [Configuración](#a.1.2)
  - [Servidor HTTPS](#a.1.3)
  - [Commands](#a.1.4)
- [Servidor API](#a.2)
  - [Nuestro primer *API* endpoint](#a.2.1)
  - [URLs](#a.2.2)
  - [Parámetros](#a.2.3)
  - [Control de sesión](#a.2.4)
  - [HTTP Status Messages](#a.2.5)
- [Servidor Páginas](#a.3)
  - [Nuestro primer *WWW* endpoint](#a.3.1)
  - [Plantillas Mustache](#a.3.2)
  - [Bindings](#a.3.3)
  - [Bloques](#a.3.4)
  - [Redirecciones](#a.3.5)
  - [Servir ficheros y streming](#a.3.6)


<a name="a.1"/>
1. Inicio
---------

<a name="a.1.1"/>
### 1.1 Instalación

Para instalar una nueva instancia de ZENserver únicamente tienes que ejecutar el
comando:

```bash
npm install zenserver --save
```

De esta manera tendrás todo lo necesario para comenzar con el proyecto. Otra
manera, algo más rudimentaria, es modificar el fichero `package.json` incluyendo
esta nueva dependencia:

```json
{
  "name"            : "zen-server-instance",
  "version"         : "1.0.0",
  "dependencies": {
    "coffee-script" : "*",
    "zenserver"     : "*" },
  "scripts"         : {"start": "node zen.js"},
  "engines"         : {"node": "*"}
}
```

Como puedes ver además del *package* `zenserver` hemos añadido también el
package `coffee-script`, esto es así porque todos los ejemplos que vamos a ver
lo vamos a realizar con este lenguaje. Esto no quiere decir que no puedas
desarrollar con `JavaScript`, pero creemos que `CoffeeScript` es un *lenguaje*
mucho más mantenible y legible. Si deseas aprender más sobre este lenguaje
puedes descargarte el libro gratuito [CoffeeScript][1].

[1]: <https://leanpub.com/coffeescript>

<a name="a.1.2"/>
### 1.2 Configuración

ZENserver busca ofrecer todo lo necesario para crear aplicación robustas y mantenibles teniendo como escencia JavaScript desde el cliente hasta el servidor. Así, pasaremos a describir los servicios que ofrece ZENserver desde las bases de datos como **MongoDB** y **Redis** hasta directivas de firewall además de métodos para controlar las peticiones y respuestas del servidor.

Además, ZENserver ofrece un conector con [Appnima](https://github.com/tapquo/appnima.docs) por si quisieras utilizar esta plataforma API REST que provee de los servicios lógicos para tus proyectos.

Por ello, teniendo en cuenta lo comentado anteriormente, la estructura básica de ficheros y directorios para trabajar con ZENserver y sus servicios es la que se muestra a continuación:

```
.
├── api
├── common
│   └── models
├── environment
├── www
│   └── index.html
├── package.json
├── zen.js
├── zen.yml
```

Uno de los beneficios de usar ZEN es que el fichero de configuración (`zen.yml`) cobra una gran importancia a la hora de configurar los servicios disponibles en tu *server*. Vamos a ir analizando cada una de las opciones que nos permite establecer el fichero `zen.yml`:

```yaml
protocol: http # or https
host    : localhost
port    : 8888
timezone: Europe/Amsterdam
```

Esta sección te permite establecer la configuración de tu servidor; el **protocolo** que vas a utilizar (`http` o `https`), el **nombre** del host, **puerto** y **zona horaria**.

```yaml
environment: development
```

El atributo **environment** sirve para crear diferentes ficheros de configuración por ejemplo para utilizarlo en diferentes entornos (desarrollo, preproducción, producción...). En este caso, como hemos establecido el valor `development`, cuando arranques el servidor, éste buscará un fichero en la ruta *environment/development.yml* para sobreescribir los atributos que tengas establecidos en el fichero */zen.yml*.

```yaml
# -- RESTful services ----------------------------------------------------------
api:
  - index

# -- HTML pages ----------------------------------------------------------------
www:
  - index
```

Los atributos **api** y **www** contienen los *endpoints* de tu servidor. Estos podrán ser de dos tipos; `api` para los servicios REST y *www* para el resto de resultados (HTML, images...). En este ejemplo, ZENserver buscará los endpoints `/api/index.coffee` y `/www/index.coffee` y los cargará en el enrutador para su posterior tratamiento. En el capítulo 2 veremos como se crean los endpoints y las diferentes posibilidades que nos ofrece.

```yaml
# -- Static resources ----------------------------------------------------------
statics:
  - url     : /temp/resources
    folder  : /static
    maxage  : 60 #secods
  - url     : /img
    folder  : /static/img
  - file    : humans.txt
    folder  : /static
    maxage  : 3600
  - file    : robots.txt
    folder  : /static
```

El atributo **statics** nos ofrece una forma sencilla de ofrecer ficheros estáticos en nuestro servidor. Podemos ofrecer directorios completos por medio del atributo `url` o un fichero determinado mediante `file`. Para ambos casos debemos establecer la ruta relativa al directorio del proyecto mediante el atributo `folder`. En el caso de que necesitemos que los recursos tenga *caché* simplemente tenemos que establecer el número de segundos mediante el atributo condicional `maxage`.

```yaml
# -- session -------------------------------------------------------------------
session:
  # Cookie Request
  cookie: zencookie
  domain: ""
  path  : "/"
  expire: 3600 #seconds
  # HTTP Header
  authorization: zenauth
```

El atributo **session** nos permite establecer y obtener de una manera sencilla la variable de sesión de un determinado cliente. Esta variable se puede obtener mediante el atributo **cookie**, al cual se le asigna un nombre, el **dominio** para el cual es válida la cookie, **ruta** y **expiración**. **session** también nos permite que la asignación sea por cabecera en una petición http. En este ejemplo, ese atributo tiene el valor `zenauth`.

```yaml
# -- Monitor -------------------------------------------------------------------
monitor:
  password: mypassword
  process : 10000
  request : 1000
```

El atributo **monitor** nos permite que ZENserver cree una pequeña auditoria de lo que sucede en nuestro servidor mientras se está ejecutando. Genera un fichero por día en el directorio */logs* con información de todas las peticiones que le llegan al servidor. Por cada petición obtenemos los siguientes datos:

-   Endpoint que se esta solicitando.
-   Método (GET, POST, PUT, DELETE,...).
-   Tiempo de proceso en milisegundos.
-   Código HTTP de respuesta.
-   Tamaño de respuesta en bytes.
-   Cliente (próximamente).

![image](https://raw.githubusercontent.com/cat2608/contacts/master/assets/img/screen-18.png)

De esta manera podrás analizar como están usando los usuarios tu servidor e incluso poder identificar *errores*, *bottlenecks* o puntos de mejora. [Aquí](https://github.com/soyjavi/zen-monitor) puedes encontrar más información sobre como leer los datos de la auditoría.

```yaml
# -- firewall ------------------------------------------------------------------
firewall:
  ip: 100 #Number of request per firewall rule
  extensions:
    - php
    - sql
```

Gracias al atributo **firewall** podemos filtrar peticiones entrantes a nuestro server. Declara las extensiones que tu aplicación no esté configurada para servir y ZENserver se encargará de devolver un `403 Forbidden`. Además, si configuras el parámetro `ip`, los hosts que hagan el número de peticiones indicado serán puestos en la `blacklist.json` y ZENserver devolverá un `403 Forbidden` antes de que nuevas peticiones vuelvan a llegar a los endpoints.

```yaml
# -- CORS Properties -----------------------------------------------------------
headers:
  Access-Control-Allow-Origin: "*"
  Access-Control-Allow-Credentials: true
  Access-Control-Allow-Methods: GET,PUT,POST,DELETE,OPTIONS
  Access-Control-Max-Age: 1
  Access-Control-Allow-Headers:
    - Accept
    - Accept-Version
    - Content-Length
    - Content-MD5
    - Content-Type
    - Date
    - Api-Version
    - Response-Time
    - Authorization
  Access-Control-Expose-Headers:
    - api-version
    - content-length
    - content-md5
    - content-type
    - date
    - request-id
    - response-time
```

Por último, podemos establecer el tipo de respuesta de nuestros *endpoints*, pudiendo limitar el acceso a los mismos con los típicos parámetros para el control *cross-origin*, filtrado de métodos, etc... Recuerda que si en el apartado de *session* decides cambiar el nombre del parámetro de autorización (`authorization`), deberás reflejar este cambio en el CORS (`Authorization`).

<a name="a.1.3"/>
### 1.3 Servidor HTTPS
ZENserver también permite trabajar como servidor HTTPS. Las modificaciones en nuestro fichero de configuración son mínimas; debemos indicar que el protocolo es **https** y los nombre de los fichero de autenticación:

```yaml
# -- General Info --------------------------------------------------------------
protocol : https
host     : localhost
port     : 8888
timezone : Europe/Amsterdam

# -- Certificates --------------------------------------------------------------
cert: server.crt
key : server.key
```

Estos ficheros los debes almacenar en la carpeta **certificates** en la raíz del proyecto. Una vez tengas todo configurado, solo tienes que levantar el servidor como siempre pero ahora la url es: `https://127.0.0.1:8888`.


<a name="a.1.4"/>
### 1.4 Commands

Como has podido comprobar el fichero de configuración `zen.yml` te permite
establecer los valores básicos de tu servidor. Si has nombrado tus ficheros de
arranque y configuración como `zen.js` y `zen.yml` la forma de iniciar el
servidor es de la siguiente manera:

```bash
$node zen.js zen
```

De esta forma, el servidor arrancará en el puerto que hayas establecido en el
fichero zen.yml así como el environment declarado.

Puedes arrancar tu servidor sobreescribiendo los valores del zen.yml pasando por
línea de comando los siguientes argumentos:

```bash
$node [fichero JS] [fichero YML] [ENVIRONMENT] [PUERTO]
$node zen config production 1980
```

En este ejemplo estamos diciendo a NodeJS que ejecute el fichero zen.js
(instanciador de servidor ZENserver) pero además le estamos enviamos 3
argumentos más:

-   **config**: Es el nombre del fichero de configuración, sustituyendo el por
    defecto zen.yml (se debe pasar sin la extensión yml).

-   **production**: El nombre del *environment* (entorno) que utilizará
    sustituyendo al atributo `environment` existente en el fichero de
    configuración zen.yml.

-   **1980**: El número de puerto a utilizar por la instancia de ZENserver
    sustituyendo al atributo `port` existente en el fichero de configuración
    zen.yml.

Señalar que no es obligatorio tener que asignar todos los parámetros pero si
respetar el orden de los mismos. Con esto, en el caso de que queramos asignar un
nuevo número de puerto, es necesario pasar los argumentos anteriores.

<a name="a.2"/>
2. Servidor API
---------------

En esa sección aprenderás a crear tu primera API con las diferentes
funcionalidades y capacidades que te ofrece ZENserver. Como vimos en el capítulo
1, los endpoints de tipo API debemos alojarlos en la carpeta */api*.

<a name="a.2.1"/>
### 2.1 Nuestro primer *API* endpoint

Vamos a crear nuestro primer API endpoint para ello vamos a crear un fichero
`hello.coffee` en la carpeta */api*:

```coffee
"use strict"

module.exports = (zen) ->

  zen.get "/hello", (request, response) ->
    response.json hello: "world"
```

Como podemos ver al codificar con CoffeeScript ganamos en legibilidad y
mantenibilidad. En este caso el fichero `hello.coffee` exporta un único endpoint
de tipo `GET` y que tiene como ruta de acceso `/hello`, el *callback* que se
ejecuta cada vez que se acceda a la misma nos devuelve dos parámetros:

-   **request**: Es el objeto nativo de NodeJS pero sobrevitaminado con
    ZENserver. En posteriores apartados veremos las opcions extras que ZENserver
    nos ofrece sobre este objeto.

-   **response**: Al igual que el anterior es el objeto nativo, pero como
    podemos ver con la función `json` (no existente en NodeJS) viene con
    funcionalidades extra.

En este endpoint únicamente estamos devolviendo un objeto json `{"hello":
"world"}` gracias al método `.json()` de ZENserver.

En el caso de que quisiesemos capturar otros métodos http podríamos hacerlo en
el mismo fichero `hello.coffee`. Veamos como podríamos capturar otros métodos
además del `GET`:

```coffee
"use strict"

module.exports = (zen) ->

  zen.get "/hello", (request, response) ->
    response.json hello: "world"

  zen.post "/hello", (request, response) ->
    response.json method: "POST"

  zen.put "/api", (request, response) ->
    response.json method: "PUT"

  zen.delete "/api", (request, response) ->
    response.json method: "DELETE"

  zen.head "/api", (request, response) ->
    response.json method: "HEAD"

  zen.options "/api", (request, response) ->
    response.json method: "OPTIONS"
```

El resto de métodos están en la ruta `/api` y devuelven como respuesta otro
objeto json con el tipo de método como valor.

<a name="a.2.2"/>
### 2.2 URLs

En el caso de que necesitemos tener URLs condicionales y que sean manejadas por
el mismo endpoint podemos usar el enrutador condicional de ZENserver.

Por ejemplo, necesitamos un endpoint que capture cuando se accede a un usuario y
a una determinada area del mismo: */user/soyjavi/messages* o
*/user/cataflu/followers*, para ello podríamos utilizar la URL condicional
`/user/:id/:context`:

```coffee
zen.get "/user/:id/:context", (request, response) ->
  response.json request.parameters
```

Como vemos, devolvemos como respuesta un objeto json contenido en
`request.parameters`. En el siguiente capítulo veremos con más detalle el
tratamiento de parámetros, pero como adelanto, este método devolvería: `{id:
"soyjavi", context: "messages"}` y `{id: "cataflu", context: "followers"}`

<a name="a.2.3"/>
### 2.3 Parámetros

Si continuamos con el endpoint anterior `/user/:id/:context` vamos a realizar
ciertos ejercicios con los parámetros que nos lleguen. Como vimos
`request.parameters` contiene un objeto con todos los parámetros que se le
envíen. Por ejemplo para la url:

`http://domain.com/user/soyjavi/messages?order_by=date&page=20`

Obtendríamos automáticamente:

```json
{
    "id"      : "soyjavi",
    "context" : "messages",
    "order_by": "date",
    "page"    : 20
}
```

Evidentemente podemos acceder a cada uno de los valores de manera independiente,
por ejemplo `request.parameters.id` tendría como valor `"soyjavi"`. En el caso
de que queramos testear si existe un determinado parámetros podemos utilizar el
método `request.required` al cual debemos enviarle un array de parámetros a
testear:

```coffee
zen.get "/domain/:id/:context", (request, response) ->
  if request.required ["name"]
    response.json request.parameters
```

Si el parámetro `"name"` no fuese enviado, ZENserver devolverá una respuesta con
código *httpstatus* `400` indicando que el parámetro no ha sido encontrado:
`{message: "name is required."}`

<a name="a.2.4"/>
### 2.4 Control de sesión

En el caso de que queramos controlar si las peticiones que llegan a nuestro
endpoint tienen sesión podemos utilizar el objeto `request.session` el cual en
el caso de que exista nos devolverá el valor de la sesión. Esta podrá ser via
*cookie* o via autenticación http.

Veamos como establecer una nueva sesión via cookie, para ello vamos a crear un
nuevo endpoint `/login`:

```coffee
zen.get "/login", (request, response) ->
  response.session "10293sjad092a"
  response.json "cookie": true
```

Como vemos, antes de devolver una respuesta establecemos una nueva cookie con el
valor `"10293sjad092a"` mediante el método `response.session`. Hay que señalar
que la persistencia de la cookie que acabas de crear viene dada por la
parametrización establecida en el fichero de configuración `zen.yml`. Ahora
veamos como eliminar esa cookie por medio de otro endpoint `/logout`:

```coffee
zen.get "/logout", (request, response) ->
  response.logout()
  response.json "cookie": false
```

Como vemos, no difiere mucho a la creación, únicamente tenemos que llamar al
método `response.logout()` antes de devolver una respuesta.

Si retomamos el endpoint del capítulo anteriores podríamos unir la sesión (en el
caso de que exista) con los parámetros:

```coffee
zen.get "/domain/:id/:context", (request, response) ->
  if request.required ["name"]
    request.parameters.session = request.session
    response.json request.parameters
```

<a name="a.2.5"/>
### 2.5 HTTP Status Messages

Por ahora solo conocemos el método json de manera superficial, además de
establecer el objeto que queremos devolver, podemos indicar un *HTTPStatusCode*
(por defecto 200) y unas *HTTPHeaders*. Por ejemplo:

```coffee
values =
  username: "cataflu",
  name    : "Catalina"
headers =
  domain  : "http://domain.com"

response.json values, 201, headers
```

Como puedes comprobar es realmente sencillo, pero para facilitar aún más las
cosas ZENserver te ofrece *HTTPStatus* ya predefinidos. Por ejemplo si en un
determinado endpoint queremos devolver que el cliente no tiene permiso
simplemente tendríamos que llamar al método `response.badRequest()` y ZENServer
se ocupará de crear una respuesta `401` con el mensaje `"Bad Request"`.

A continuación, se listan los mensajes predefinidos que puede devolver
ZENserver:

**2xx Successful**

```yaml
200: "ok"
201: "created"
202: "accepted"
204: "noContent"
```

**4xx Client Error**

```yaml
400: "badRequest"
401: "unauthorized"
402: "paymentRequired"
403: "forbidden"
404: "notFound"
405: "methodNotAllowed"
406: "notAcceptable"
407: "proxyAuthenticationRequired"
408: "requestTimeout"
409: "conflict"
```

**5xx Server Error**

```yaml
500: "internalServerError"
501: "notImplemented"
502: "badGateway"
503: "serviceUnavailable"
504: "gatewayTimeout"
505: "HTTPVersionNotSupported"
```

<a name="a.3"/>
3. Servidor Páginas
-------------------

Como hemos aprendido en el capítulo anterior ZENserver nos da todos los
mecanismos necesarios para crear potentes APIs. En este apartado veremos de
igual manera lo realmente sencillo que es crear páginas webs.

<a name="a.3.1"/>
### 3.1 Nuestro primer *WWW* endpoint

Vamos a crear un fichero form.coffee en el directorio */www* el cual contendrá
nuestro primer www endpoint. En este caso, cuando se acceda a la ruta */form* en
modo `GET` ZENserver responderá con un formulario:

```coffee
zen.get "/form", (request, response) ->
  response.html """
    <form action="/form" method="post">
      <input type="text" name="name">
      <input type="text" name="username">
      <input type="file" name="media">
      <input type="submit" value="Submit">
    </form>
  """
```

Para ello utilizamos el método `response.html` que al igual que con
`response.json` es un método ofrecido por ZENserver bajo el objeto nativo
`response`. En este caso, ofrecemos un formulario que enviará mediante POST al
endpoint `/form` los datos contenidos en el mismo, para ello vamos a crear su
endpoint:

```coffee
zen.post "/form", (request, response) ->
  if request.required ["name", "username"]
    response.html "<h1>Hi #{request.parameters.name}!</h1>"
```

Al igual que en el resto de endpoints aquí también podemos tratar los parametros
de la request. ZENserver te abstrae de la captura de parametros
independientemente del tipo que sean: get, post, multipart...

<a name="a.3.2"/>
### 3.2 Plantillas Mustache

Ya has aprendido como devolver código HTML en un determinado endpoint, pero
realmente, esta no es la opción eficiente. Ahora vas a aprender a utilizar las
plantillas [Mustache][2] que vienen incluidas en ZENserver para facilitar la
reutilización y gestión correctamente de tus páginas.

[2]: <http://mustache.github.io/>

Para ello vamos a crear un fichero `base.mustache` dentro de */www/mustache*:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>ZENServer</title>
</head>
<body>
    <header>
        <h1>Hello World!</h1>
        More info & code
        <a href="https://github.com/soyjavi/zen-server" target="_blank">GitHUB</a>
    </header>

</body>
</html>
```

Ahora crearemos un nuevo endpoint `index.coffee` que mostrará la página diseñada
al entrar en la ruta */*:

```coffee
zen.get "/", (request, response) ->
  response.page "base"
```

Simplemente con el método `response.page` le indicamos a ZENserver que busque un
fichero `base.mustache` dentro de */www/mustache*.

En el caso de que el fichero mustache no existiese, no hay ningún problema
puesto que ZENserver buscará un fichero `404.mustache` en el mismo directorio
para mostrar una página de error html, si a su vez este fichero tampoco
existiera, ZENserver devolverá un html `<h1> 404 - Not found</h1>`.

<a name="a.3.3"/>
### 3.3 Bindings

En el anterior capítulo hemos visto como renderizar una página sencilla por
medio de un fichero Mustache. De todas formas todavía no hemos utilizado ninguna
de las funcionalidades que nos ofrece Mustache.

Vamos a enviarle datos a nuestra plantilla para que las renderize, esto se
conoce como *binding* de datos. Para ello vamos a modificar nuestra plantilla
`base.mustache`:

```html
...
  <h1>Hello World! {{title}}</h1>
...
```

Ahora desde nuestro endpoint tendríamos que enviar una variable con nombre
`title`:

```coffee
zen.get "/", (request, response) ->
  bindings =
    title   : "ZENserver"
    session: request.session

  response.page "base", bindings
```

Como ves, hemos creado un objeto `bindings` que contiene todos los datos que
queremos enviarle a nuestra plantilla mustache. Una vez tengas los datos en tu
plantilla podrás hacer condicionales, iteradores y demás funcionalidades típicas
de este tipo de templates. Para conocer todo lo que puedes hacer echa un vistazo
a la documentación de [Mustache][3].

[3]: <http://mustache.github.io/>

<a name="a.3.4"/>
### 3.4 Bloques

Imagina que vamos a utilizar una sección de HTML en varias páginas, lo mejor
sería aislar ese código HTML y poder incluirlo en todas las plantillas que
necesitemos, ¿no?. Bien vamos a ver como lo podemos hacer con nuestra plantilla
mustache:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{title}}</title>
</head>
<body>
    <header>
        <h1>{{title}}</h1>
        More info & code
        <a href="https://github.com/soyjavi/zen-server" target="_blank">GitHUB</a>
    </header>

    {{> partial.example}}
    {{> partial.session}}
</body>
</html>
```

Como ves hemos creado dos vínculos de bloque mustache `{{> partial.example}}` y
`{{> partial.session}}`. Vamos a crearlos en el mismo nivel que el resto de
templates:

**partial.example.mustache**

```html
<section>
    <h2>partial.example</h2>
    subdomain: <strong>{{user.name}}</strong>
    mobile: <strong>{{mobile}}</strong>
</section>
```

**partial.session.mustache**

```html
<section>
    <h2>partial.session</h2>
    Session: <strong>{{session}}</strong>
    <nav>
        <a href="/session/login">Login</a>
        <a href="/session/logout">Logout</a>
    </nav>
</section>
```

Ahora desde nuestro endpoint vamos a completar el binding:

```coffee
zen.get "/", (request, response, next) ->
  bindings =
    title : "zenserver"
    user:
      name: "@soyjavi"
    session: request.session
    mobile : request.mobile
  partials = ["partial.example", "partial.session"]

  response.page "base", bindings, partials
```

<a name="a.3.5"/>
### 3.5 Redirecciones

En el caso de que cuando se acceda a un endpoint necesites dar como respuesta
otra página por medio de una redirección, ZENserver te lo vuelve a poner fácil.
Un ejemplo es el acceso a endpoints solo cuando el usuario tenga sesión y en
caso contrario redirigirle al endpoint de login. Veamos como hacerlo:

```coffee
zen.get "/dashboard", (request, response) ->
  if response.session
    response.page "dashboard", bindings, partials
  else
    response.redirect "/login"
```

Como podemos ver si el cliente quiere acceder al endpoint */dashboard* deberá
tener sesión (ya sea por cookie o HTTPAuthentication), en caso de que no la
tenga utilizaremos el método `response.redirect` para redirigirle al endpoint
*/login*.

<a name="a.3.6"/>
### 3.6 Servir ficheros y streaming

A pesar de que NodeJS no es el mejor sistema para servir archivos estáticos
ZENserver te ofrece una solución sencilla y eficiente para este propósito.

Únicamente tendrémos que utilizar el método `response.file` el cual se encargará
de analizar el tipo de fichero que quieres servir y ofrecer el mejor método de
transmisión. Por ejemplo si estamos intentando servir algún tipo de fichero
multimedia como pueden ser vídeo o audio, ZENserver automáticamente realizará un
*streaming* del mismo. Veamos un ejemplo:

```coffee
zen.get "/vídeo/:id", (request, response) ->
  response.file "/assets/vídeo/#{request.parameters.id}.avi"
```

Como puedes ver es muy sencillo, ya que se delega toda la responsabilidad a
ZENserver para que decida como transmitir el archivo. Señalar que en el caso de
que el fichero */assets/vídeo/?.id* no existiese ZENserver devolverá un
HTTPStatusCode 404.

El método `response.file` creará un pequeño cacheo en el cliente, por defecto de
60 segundos, en el caso de que queramos aumentar o reducir este caching, solo
tenemos que pasarlo en el segundo parametro:

```coffee
url_file = "/assets/image/tapquo.jpg"
response.file url_file, maxage = 3600
```

En este caso, hemos asignado al fichero */assets/image/tapquo.jpg* una caché en
el cliente de 1 hora (3600 segundos).
