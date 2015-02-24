# ZEN-server

Is the main module of ZEN, that there you will find all necessary tools to create web servers with NodeJS. The main difference from others solutions is the not dependency of third modules, very common in NodeJS projects but that ultimately can create problems.

Our engagement is use the fewer dependencies and offer our experiences with NodeJS easily and intuitive.

## 1. Introduction

ZENserver wants to offer all you need to build applications robust and easy to maintain. Also provides connectors databases with MongoDB and Redis and a connector with [APPNIMA](https://github.com/tapquo/appnima.docs).

So, the structure of files and folders to work with those features are:

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

### 1.1 Installation

To install a new instance of ZENserver only you have to run this command:

```bash
  npm install zenserver --save
```

Another option is modify the package.json including this new dependency:

```yaml
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
We include **coffee-script** package too, because we go to do all examples in this language. But if you want to develop in JavaScript, you can.

We believe that CoffeeScript is more maintainable and legible, so if you want to learn more of CoffeeScript you can download this free book <https://leanpub.com/coffeescript>.

### 1.2 Configuration

It is easy to configure ZEN because everything you need is in the configuration file **zen.yml**. We are goint to analyze these options:

```yaml
# -- General Info --------------------------------------------------------------
  protocol: http # or https
  host    : localhost
  port    : 8888
  timezone: Europe/Amsterdam
```

In this section you can set your server configuration, the protocol that you use (http or https), host name, port and timezone.

```yaml
# -- Environment ---------------------------------------------------------------
  environment: development
```

With this attribute you can create different configuration files to use in different environments (development, preproduction, production...).

In this example we have established environment so when the server is started searches a file in **environment/development.yml** route to overwrite the previous configuration on **/zen.yml**.

```yaml
# -- RESTful services ----------------------------------------------------------
api:
  - index

# -- HTML pages ----------------------------------------------------------------
www:
  - index
```

The attributes **api** and **www** contain the endpoints of your server.
The *api* is for REST services and the *www* for others results (HTML, images...).

In this example, ZENserver searches the endpoints **/api/index.coffee** and **/www/index.coffee** and will load on the router for further proccesing.

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

This attribute gives us a simple way to provide static files on our server. We can offer complete directories with the **url** attribute or a specific file by **file** attribute. In both cases we set the path relative to the project directory using the **folder** attribute. In case we need to have cache resources we have to set the number of seconds using the attribute **maxage**.

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

With this attribute we can establish and get easily the session variable for a particular customer. This variable we can get with the attribute **cookie**.

```yaml
# -- Monitor -------------------------------------------------------------------
monitor:
  password: mypassword
  process : 10000
  request : 1000
```

With this attribute we can create an audit to control what happens in our server when it is running. This audit creates a file per day in **/logs** directory with this information:

-   Endpoint requested.
-   Which methods: GET, POST, PUT, DELETE,...
-   Processing time in milliseconds.
-   HTTP code response.
-   Response length.
-   Client (coming soon).


![image](https://raw.githubusercontent.com/cat2608/contacts/master/assets/img/screen-18.png)

[Learn how to use ZENmonitor](https://github.com/soyjavi/zen-monitor).

```yaml
# -- firewall ------------------------------------------------------------------
firewall:
  ip: 100 #Number of request per firewall rule
  extensions:
    - php
    - sql
```
You can control packets transiting using `firewall` option. You just need to set extensions that your application is not configured to handle and ZENserver will return `403 Forbidden`. Also, with `ip` parameter you can set a number of maximum requests that a host can do before get into list **blacklist.json**.

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

Finally we set the type of response from our endpoints, to limit access to the same with typical parameters for cross-origin control filtering methods, etc ...

### 1.3 HTTPS servers
You can create a HTTPS server with ZENserver just setting the protocol attribute and certificates files names:

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
This files must be at **certificates* folder at the root of the project. Then you can start your app like always but type in browser: `https://127.0.0.1:8888`.

#### 1.4 Commands
To initialize server the command is:

```bash
  $node zen.js zen
```

The server runs in the port that you established in **zen.yml** file. You can overwrite values of zen.yml with command line:

```bash
  $node [JS file] [YML file] [ENVIRONMENT] [PORT]
  $node zen zen production 1980

```

In this example we established that run *zen.js* file with these attributes:

  - **config**: Is the configuration file, replacing *zen.yml* that it is the default file (must be passed without extension *yml*).
  - **production**: The name of the file of environment for replace the existing environment attribute in the configuration file zen.yml.
  - **1980**: The new port, replacing the declared in zen.yml

Note that it is not mandatory to set all parameters but respect the order thereof. With this, in case you want to assign a new port number, you must pass the following arguments.

# 2. API server

## 2.1 Our first API endpoint
We go to create a new file called *hello.coffee* in **/api** folder with this code:

```coffee
  "use strict"
  module.exports = (zen) ->
      zen.get "/hello", (request, response) ->
        response.json hello: "world"
```

In this case the exported file *hello.coffee* GET a single endpoint type and whose has path /hello, the callback that runs whenever you access it gives us two parameters:


  - **request**: It is the native object NodeJS but powered with zenserver. In later sections we will see the extras options that zenserver offers on this item.
  - **response**: Like the above is the native object, but as we can see with the (nonexistent in NodeJS) json function comes with extra features.

In this endpoint we are only returning a json object `"hello": "world"` thanks to **.json()** method of zenserver.

If we want to capture other methods http we could do it in the same file hello.coffee:

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

## 2.2 URLs
If we need have conditional URLs and that it is managed by the same endpoint, we might to use the conditional router of ZENserver.

For example, we need an endpoint to get when access to an user and a determinated area like this: */user/soyjavi/messages* or */user/cataflu/followers*, for this we use the conditional URL **/user/:id/:context**

## 2.3 Parameters
With **request.parameters** we have an object with sended parameters. For example, with the URL:

`http://domain.com/user/soyjavi/messages?order_by=date&page=20`

We have an object like this:

```json
  {
    "id"      : "soyjavi",
    "context" : "messages",
    "order_by": "date",
    "page"    : 20
  }
```

## 2.4 Session control
In case you want to control whether requests that have come to our meeting endpoint can use the request.session which in the case there will return the value of the session object. This may be via cookie or authentication via http.
If we want to control if the requests have session, we could use the object **request.session**. This migth be via cookie or HTTP authentication.

In the following example show how to established the cookie and how to do logout:

```coffee
  zen.get "/login", (request, response) ->
    response.session "10293sjad092a"
    response.json "cookie": true

  zen.get "/logout", (request, response) ->
    response.logout()
    response.json "cookie": false
```

## 2.5 HTTP Status Messages
For now we only know the json method superficially, besides setting the object that we want to return, we can indicate a HttpStatusCode (default 200) and a HTTPHeaders. For example:

```coffee
  values =
      username: "cataflu",
      name    : "Catalina"
  headers =
    domain    : "http://domain.com"
  response.json values, 201, headers
```

As you can see it's really simple, but to further facilitate the zenserver things HTTPStatus offers predefined. For example if a given endpoint want to return the client does not have permission just have to call response.badRequest () method and will handle zenserver create a 401 response with the message "Bad Request".

ZENserver offers HTTPStatus predefined:

`response.badRequest()`

Then list all HTTPStatus:
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

3. Rendering
------------

## 3.1 Our firts WWW endpoint
We are goint to create *form.coffee* file in **/www** directory and with this code:

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

We use **.html()** method to render all HTML code; it is similar to *.json()*.

## 3.2 Mustache template
You've learned how to return HTML code in a particular endpoint, but really, this is not efficient option. Now you will learn to use the Mustache templates that are included in zenserver to facilitate reuse and management of your pages correctly.

We are goint to create a file *base.mustache* in **/www/mustache** directory with this code:

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

Now we create a new endpoint (index.coffee) that render create template when access to */*:

```coffee
zen.get "/", (request, response) ->
  response.page "base"
```

With the method **.page()** we indicate to ZENserver that search a file with name "base" in */www/mustache directory*.

If this file not exists, ZENserver search a 404.mustache file to render. And if you dont create it, ZENserver return a **<h1> 404 - Not found</h1>** HTML.

## 3.3 Bindings
In the previous chapter we have seen a simple page rendering by a Mustache file. Anyway we have not used any of the features Mustache offers.

We will send details to our staff so that renderize, this is known as data binding. To do this we will modify our base.mustache template:

```html
...
  <h1>Hello World! {{title}}</h1>
...
```
Now, we send through our enpoints the bingin `title`:

```coffee
zen.get "/", (request, response) ->
  bindings =
    title   : "ZENserver"
    session: request.session

  response.page "base", bindings
```

## 3.4 Blocks
Imagine that we will use a section of HTML in multiple pages, it would be better to insulate this HTML code and to include it in all the templates you need, right?. Well let's see what we can do with our mustache template:

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

We have created two references to mustache block *{{> partial.example}}* and *{{> partial.session}}*. We are goint to create in the same level of the rest of mustaches with **partial.example.mustache** name:

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


Now, from our endpoint we completed the new binding:

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

## 3.5 Redirections
If we need to do redirection to an another endpoint, we use the following method **.redirect()**:

```coffee
zen.get "/dashboard", (request, response) ->
  if response.session
    response.page "dashboard", bindings, partials
  else
    response.redirect "/login"
```

## 3.6 Render files and streaming

Although NodeJS is not the best way to serve static files zenserver provides a simple and efficient solution for this purpose.

Only we shall have to use the response.file method which will analyze the file type you want to serve and provide the best method of transmission. For example if we are trying to serve some sort of multimedia files such as video or audio, zenserver automatically performs a streaming it. Here's an example:

```coffee
  zen.get "/vídeo/:id", (request, response) ->
    response.file "/assets/vídeo/#{request.parameters.id}.avi"
```

As you can see it is very simple, since all zenserver responsibility to decide how to transmit the file is delegated. Noted that in the event that the file did not exist zenserver /assets/vídeo/?.id return a HttpStatusCode 404.

The response.file method will make a small caching on the client, by default 60 seconds, in case you want to increase or decrease the caching, we just have to pass in the second parameter:

```coffee
  url_file = "/assets/image/tapquo.jpg"
  response.file url_file, maxage = 3600
```

In this case, we have assigned the file /assets/image/tapquo.jpg a cache on the client 1 hour (3600 seconds).
