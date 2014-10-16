# ZEN-server

Es el modulo principal de ZEN, en el encontraras todas las herramientas necesarias para crear servidores web con NodeJS. La principal diferencia frente a otras soluciones es la no dependencia de modulos de terceros, algo muy común en proyectos NodeJS pero que puede ofrecer problemas.

Nuestro compromiso es utilizar el menor número de dependencias y ofrecer nuestra experiencia con NodeJS de una manera sencilla e intuitiva.


## 1. Inicio


### 1.1 Instalación

Para instalar una nueva instancia de ZEN-server únicamente tienes que ejecutar el comando:

```
npm install zenserver --save-dev
```

De esta manera tendrás todo lo necesario para comenzar con el proyecto. Otra manera, algo más rudimentaria, es modificar el fichero `package.json` incluyendo esta nueva dependencia:

```
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

Como puedes ver además del *package* `zenserver` hemos añadido también el package `coffee-script`, esto es así porque todos los ejemplos que vamos a ver lo vamos a realizar con este lenguaje. Esto no quiere decir que no puedas desarrollar con `JavaScript`, pero creemos que `CoffeeScript` es un *lenguaje* mucho más mantenible y legible. Si deseas aprender más sobre este lenguaje puedes descargarte el libro gratuito [CoffeeScript](https://leanpub.com/coffeescript).


### 1.2 Configuración 
Uno de los beneficios de usar ZEN es que el fichero de configuración (`zen.yml`) cobra una gran importancia a la hora de configurar los servicios disponibles en tu *server*. Vamos a ir analizando cada una de las opciones que nos permite establecer el fichero `zen.yml`:

```
protocol: http # or https
host    : localhost
port    : 8888
timezone: Europe/Amsterdam
```

Esta sección te permite establecer la configuración de tu servidor; el **protocolo** que vas a utilizar (`http` o `https`), el **nombre** del host, **puerto** y **zona horaria**.

```
environment: development
```

El atributo **environment** sirve para crear diferentes ficheros de configuración por ejemplo para utilizarlo en diferentes entornos (desarrollo, preproducción, producción...). En este caso hemos establecido el valor `development` por lo que buscará un fichero en la ruta *environments/development.yml* para sobreescribir los atributos que tengas establecidos en el fichero */zen.yml*.

```
api:
  - index

www:
  - index
```

Los atributos **api** y **www** contienen los *endpoints* de tu servidor. Estos podrán ser de dos tipos; `api` para los servicios REST y *www* para el resto de resultados (HTML, images...). En este caso ZENserver buscará los endpoints `/api/index.coffee` y `/www/index.coffee` y los cargará en el enrutador para su posterior tratamiento. En el capítulo 2 veremos como se crean los endpoints y las diferentes posibilidades que nos ofrece.

```
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

El atributo **statics** nos ofrece una forma sencilla de ofrecer ficheros estáticos en nuestro servidor. Podemos ofrecer directorios completos por medio del atributo `url` o un fichero determinado mediante `file`. Para ambos casos debemos establecer la ruta física y relativa al directorio del proyecto mediante el atributo `folder`. En el caso de que necesitemos que los recursos tenga *cache* simplemente tenemos que establecer el numero de segundos mediante el atributo condicional `maxage`.

```
session:
  # Cookie Request
  cookie: zencookie
  domain: ""
  path  : "/"
  expire: 3600 #seconds
  # HTTP Header
  authorization: zenauth
```

El atributo **session** nos permite establecer y obtener de una manera sencilla la variable de sesión de un determinado cliente. Esta puede obtenerse mediante *cookie*, donde podemos establecer el **nombre** de la misma, el **dominio**, **ruta** y **expiración**... así como por cabecera en una petición http que en este caso tiene el valor `zenauth`.

```
audit:
  interval: 60000 #miliseconds
```

El atributo **audit** nos permite que ZENserver cree una pequeña auditoria de lo que sucede en nuestro servidor mientras se está ejecutando. Genera un fichero por día en el directorio */logs* con información de todas las peticiones que le llegan al servidor. Por cada petición obtenemos los siguientes datos:

+ Endpoint que se esta solicitando
+ Método: GET, POST, PUT...
+ Tiempo de proceso en milisegundos
+ Código HTTP de respuesta
+ Tamaño de respuesta en bytes
+ Cliente (proximamente)

De esta manera podrás analizar como están usando los usuarios tu servidor e incluso poder identificar *errores*, *bottlenecks* o puntos de mejora. En el caso de que queramos auditar nuestro servidor únicamente tenemos que establecer el atributo interval  con el numero de milisegundos que queremos que tenga en memoria los datos (antes de volcar en el fichero de logs). Esto es así para no sobrecargar el numero de escrituras en disco.

```
headers:
  Access-Control-Allow-Origin: "*"
  Access-Control-Allow-Credentials: true
  Access-Control-Allow-Methods: GET,PUT,POST,DELETE
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

Por último podemos establecer el tipo de respuesta de nuestros *endpoints*, pudiendo limitar el acceso a los mismos con los típicos parámetros para el control *cross-origin*, filtrado de métodos, etc...

### 1.2 Servidor HTTPs
@TODO: coming soon...

### 1.3 Commands
Como has podido comprobar el fichero de configuración `zen.yml` te permite establecer los valores básicos de tu servidor. En el caso de que quieras hacer un arranque de tu servidor enviando atributos y sobreescribiendo (en el caso de que existan) los del fichero `zen.yml`. Puedes hacerlo de la siguiente manera:

```
node zen.js file.yml production 1980
```

En este ejemplo estamos diciendo a NodeJS que ejecute el fichero zen.js (instanciador de servidor Zenserver) además le enviamos 3 parámetros más:

+ **file.yml**: Es el nombre del fichero de configuración, sustituyendo el por defecto zen.yml.
+ **production**: El nombre del *environment* (entorno) que utilizará sustituyendo al atributo `environment` existente en el fichero de configuración.
+ **1980**: El numero de puerto a utilizar por la instancia de ZENserver sustituyendo al atributo `port` existente en el fichero de configuración.
 
Señalar que no es obligatorio tener que asignar todos los parámetros pero si respetar el orden de los mismos. Con esto en el caso de que queramos asignar un nuevo numero de puerto, deberemos asignar los parámetros anteriores.

## 2. Servidor API

En esa sección aprenderás a crear tu primera API con las diferentes funcionalidades y capacidades que te ofrece ZENserver. Como vimos en el capítulo 1, los endpoints de tipo API debemos alojarlos en la carpeta */api*.


### 2.1 Nuestro primer *API* endpoint
Vamos a crear nuestro primer API endpoint para ello vamos a crear un fichero `hello.coffee` en la carpeta */api*:

```
"use strict"

module.exports = (zen) ->

  zen.get "/hello", (request, response) -> 
  	response.json hello: "world"
```

Como podemos ver al codificar con CoffeeScript ganamos en legibilidad y mantenibilidad. En este caso el fichero `hello.coffee` exporta un único endpoint de tipo `GET` y que tiene como ruta de acceso `/hello`, el *callback* que se ejecuta cada vez que se acceda a la misma nos devuelve dos parámetros:

 + **request**: Es el objeto nativo de NodeJS pero sobrevitaminado con ZENserver. En posteriores apartados veremos las 
 + **response**: Al igual que el anterior es el objeto nativo, pero como podemos ver con la función `json` (no existente en NodeJS) viene con funcionalidades extra.

En este endpoint únicamente estamos devolviendo un objeto json `{"hello": "world"}` gracias al método `.json()` de ZENserver.

En el caso de que quisiesemos capturar otros métodos http podríamos hacerlo en el mismo fichero `hello.coffee`. Veamos como podríamos capturar otros métodos además del `GET`:

```
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

El resto de métodos están en la ruta `/api` y devuelven como respuesta otro objeto json con el tipo de método como valor.


### 2.2 URLs
En el caso de que necesitemos tener URLs condicionales y que sean manejadas por el mismo endpoint podemos usar el enrutador condicional de ZENserver. 

Por ejemplo, necesitamos un endpoint que capture cuando se accede a un usuario y a un determinada area del mismo: */user/soyjavi/messages* o */user/cataflu/followers*, para ello podríamos utilizar la URL condicional `/user/:id/:context`:
 
```
zen.get "/user/:id/:context", (request, response) ->
  response.json request.parameters
```

Como vemos devolvemos como respuesta un objeto json contenido en `request.parameters`. En el siguiente capítulo veremos con más detalle el tratamiento de parámetros, pero como adelanto este método devolvería: `{id: "soyjavi", context: "messages"}` y `{id: "cataflu", context: "followers"}`


### 2.3 Parámetros
Si continuamos con el endpoint anterior `/user/:id/:context` vamos a realizar ciertos ejercicios con los parámetros que nos lleguen. Como vimos `request.parameters` contiene un objeto con todos los parámetros que se envién. Por ejemplo para la url: 

`http://domain.com/user/soyjavi/messages?order_by=date&page=20`

Obtendríamos automáticamente: 

```
{
	id: "soyjavi",
	context: "messages",
	order_by: "date",
	page: 20}
```

Evidentemente podemos acceder a cada uno de los valores de manera independiente, por ejemplo `request.parameters.id` tendría como valor `"soyjavi"`. En el caso de que queramos testear si existe un determinado parámetros podemos utilizar el método `request.required` al cual debemos enviarle un array de parámetros a testear:

```
zen.get "/domain/:id/:context", (request, response) ->
  if request.required ["name"]
    response.json request.parameters
```
En el caso de que name no fuese enviado ZENserver devolverá una respuesta con código *httpstatus* `400` indicando el primer parámetro no encontrado: `{message: "name is required."}`


### 2.4 Control de sesión
En el caso de que queramos controlar si las peticiones que llegan a nuestro endpoint tienen sesión podemos utilizar el objeto `request.session` el cual en el caso de que exista nos devolverá el valor de la sesión. Esta podrá ser via *cookie* o via autenticación http. 

Veamos como establecer una nueva sesión via cookie, para ello vamos a crear un nuevo endpoint `/login`:

```
zen.get "/login", (request, response) ->
  response.session "10293sjad092a"
  response.json "cookie": true
```

Como vemos antes de devolver una respuesta establecemos una nueva cookie con el valor `"10293sjad092a"` mediante el método `response.session`. Hay que señalar que la persistencia de la cookie que acabas de crear viene dada por la parametrización establecida en el fichero de configuración. Ahora veamos como eliminar esa cookie por medio de otro endpoint `/logout`:

```
zen.get "/logout", (request, response) ->
  response.logout()
  response.json "cookie": false
```
Como vemos no difiere mucho a la creación, únicamente tenemos que llamar al método `response.logout` antes de devolver una respuesta.

Si retomamos el endpoint del capítulo anteriores podríamos unir la sesión (en el caso de que exista) con los parámetros:
```
zen.get "/domain/:id/:context", (request, response) ->
  if request.required ["name"]
    request.parameters.session = request.session
    response.json request.parameters
```

### 2.5 HTTP Status Messages
Por ahora solo conocemos el método json de manera superficial, además de establecer el objeto que queremos devolver podemos, indicar un *HTTPStatusCode* (por defecto 200) y unas *HTTPHeaders*. Por ejemplo:

```
values = 
  username: "cataflu",
  name    : "Catalina"headers =
  domain  : "http://domain.com"

response.json values, 201, headers
```

Como puedes comprobar es realmente sencillo, pero para facilitar aún más las cosas ZENserver te ofrece *HTTPStatus* ya predefinidos. Por ejemplo si en un determinado endpoint queremos devolver que el cliente no tiene permiso simplemente tendríamos que llamar al método `response.badRequest()` y ZENServer se ocupará de crear una respuesta `401` con el mensaje `"Bad Request"`. 

Si quieres conocer todos los mensajes predefinidos:
**2xx Successful**

```
200: "ok"
201: "created"
202: "accepted"
204: "noContent"
```
**4xx Client Error**

```
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

```
500: "internalServerError"
501: "notImplemented"
502: "badGateway"
503: "serviceUnavailable"
504: "gatewayTimeout"
505: "HTTPVersionNotSupported"
```

## 3. Servidor Páginas
Como hemos aprendido en el capítulo anterior ZENserver nos da todos los mecanismos necesarios para crear potentes APIs. En este apartado veremos de igual manera lo realmente sencillo que es crear páginas webs.


### 3.1 Nuestro primer *WWW* endpoint
Vamos a crear un fichero form.coffee en el directorio */www* el cual contendrá nuestro primer www endpoint. En este caso cuando se acceda a la ruta */form* en modo `GET` ZENserver responderá con un formulario:

```
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
Para ello utilizamos el método `response.html` que al igual que con `response.json` es un método ofrecido por ZENserver bajo el objeto nativo `response`. En este caso ofrecemos un formulario que enviará mediante POST al endpoint `/form` los datos contenidos en el mismo, para ello vamos a crear su endpoint:

```
zen.post "/form", (request, response) ->
  if request.required ["name", "username"]
    response.html "<h1>Hi #{request.parameters.name}!</h1>"
```
Al igual que en el resto de endpoints podemos tratar los parametros, ZENserver te abstrae de la captura de parametros independientemente del tipo que sean: get, post, multipart...

### 3.2 Plantillas Mustache
Ya has aprendido como devolver código HTML en un determinado endpoint, pero realmente no es la opción eficiente. Ahora vas a aprender a utilizar las plantillas [Mustache](http://mustache.github.io/) que vienen incluidas en ZENserver para facilitar la reutilización y gestión correctamente de tus páginas.


Para ello vamos a crear un fichero `base.mustache` dentro de */www/mustache*:

```
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

Ahora crearemos un nuevo endpoint `index.coffee` que permitirá mostrará la página diseñada al entrar en la ruta */*:

```
zen.get "/", (request, response) ->
  response.page "base"
```

Simplemente con el método `response.page` le indicamos a ZENserver que busque un fichero `base.mustache` dentro de */www/mustache*. 

En el caso de que el fichero mustache no existiese, no hay ningún problema puesto que ZENserver buscará un fichero `404.mustache` en el mismo directorio para mostrar una página de error html, si a su vez este fichero tampoco existe devolverá un html `<h1> 404 - Not found</h1>`.

### 3.3 Bindings
En el anterior capítulo hemos visto como renderizar una página sencilla por medio de un fichero Mustache. De todas formas todavía no hemos utilizado ninguna de las funcionalidades que nos ofrece Mustache.

Vamos a enviarle datos a nuestra plantilla para que este las renderize, comunmente conocido como *binding* de datos. Para ello vamos a modificar nuestra plantilla `base.mustache`:

```
...
  <h1>Hello World! {{title}}</h1>
...
```
Ahora desde nuestro endpoint tendríamos que enviar una variable con nombre `title`:

```
zen.get "/", (request, response) ->
  bindings = 
    title 	: "ZENserver"
    session: request.session
    
  response.page "base", bindings
```

Como ves hemos creado un objeto `bindings`, donde contenemos todos los datos que queremos enviarle a nuestra plantilla mustache. Una vez tengas los datos en tu plantilla podrás hacer condicionales, iteradores y demás funcionalidades típicas de este tipo de templates. Para conocer todo lo que puedes hacer echa un vistazo a la documentación de [Mustache](http://mustache.github.io/).

### 3.4 Bloques 
Imagina que vamos a utilizar una sección de HTML en varias páginas, lo mejor sería aislar ese código HTML y poder incluirlo en todas las plantillas que necesitemos ¿no?. Bien vamos a ver como lo podemos hacer con nuestra plantilla mustache:

```
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

Como ves hemos creado dos vínculos de bloque mustache `{{> partial.example}}` y `{{> partial.session}}`. Vamos a crearlos en el mismo nivel que el resto de templates:

**partial.example.mustache**

```
<section>
    <h2>partial.example</h2>
    subdomain: <strong>{{user.name}}</strong>
    mobile: <strong>{{mobile}}</strong>
</section>
```

**partial.session.mustache**

```
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

```
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

### 3.5 Redirecciones
En el caso de que cuando se acceda a un endpoint necesites dar como respuesta otra página por medio de una redirección, ZENserver te lo vuelve a poner fácil. Un ejemplo sería por ejemplo el acceso a endpoints solo cuando el usuario tuviese sesión y en caso contrario redirigirle al endpoint de login. Veamos como hacerlo:

```
zen.get "/dashboard", (request, response) ->
  if response.session
    response.page "dashboard", bindings, partials
  else
    response.redirect "/login"
```

Como podemos ver si el cliente quiere acceder al endpoint */dashboard* deberá tener sesión (ya sea por cookie o HTTPAuthentication), en caso de que no la tenga utilizaremos el método `response.redirect` para redirigirle al endpoint */login*.

### 3.6 Servir ficheros y streaming
A pesar de que NodeJS no es el mejor sistema para servir archivos estáticos ZENserver te ofrece una solución sencilla y eficiente para este propósito.

Únicamente tendrémos que utilizar el método `response.file` el cual se encargará de analizar el tipo de fichero que quieres servir y ofrecer el mejor método de transmisión. Por ejemplo si estamos intentando servir algún tipo de fichero multimedia como pueden ser video o audio, ZENserver automáticamente realizará un *streaming* del mismo. Veamos un ejemplo:

```
zen.get "/video/:id", (request, response) ->
  response.file "/assets/video/#{request.parameters.id}.avi"
```
	
Como puedes ver es muy sencillo, dando toda la responsabilidad a ZENserver para que decida como transmitir el archivo. Señalar que en el caso de que el fichero */assets/video/?.id* no existiese devolverá un HTTPStatusCode 404. 

El método `response.file` creará un pequeño cacheo en el cliente, por defecto de 60 segundos, en el caso de que queramos aumentar o reducir este caching, solo tenemos que pasarlo en el segundo parametro:

```
url_file = "/assets/image/tapquo.jpg"
response.file url_file, maxage = 3600
```

En este caso hemos asignado al fichero */assets/image/tapquo.jpg* una cache en el cliente de 1 hora (3600 segundos).