---
title: Ejecutar un Microservicio Localmente
overview: Aprende cómo trabajar en un solo servicio en tu máquina local.
weight: 10
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Antes del advenimiento de la arquitectura de microservicios, los equipos de desarrollo construían,
desplegaban y ejecutaban toda la aplicación como un gran bloque de software. Para probar un
pequeño cambio en su módulo no solo mediante pruebas unitarias, los desarrolladores tenían que
construir toda la aplicación. Por lo tanto, las construcciones tomaban una gran cantidad de tiempo.
Después de la construcción, los desarrolladores desplegaban su versión de la aplicación en un
servidor de prueba. Los desarrolladores ejecutaban el servidor ya sea en una máquina remota, o en su
computadora local. En el último caso, los desarrolladores tenían que instalar y operar un
entorno bastante complejo en su computadora local.

En la era de la arquitectura de microservicios, los desarrolladores escriben, construyen, prueban y
ejecutan pequeños servicios de software. Las construcciones son rápidas. Con frameworks modernos como
[Node.js](https://nodejs.org/en/) no hay necesidad de instalar y operar
entornos de servidor complejos para probar un solo servicio, ya que el servicio se ejecuta como
un proceso regular. No tienes que desplegar tu servicio a algún entorno para
simplemente probarlo, así que solo construyes tu servicio y lo ejecutas inmediatamente en tu
computadora local.

Este módulo cubre los diferentes aspectos involucrados en desarrollar un solo servicio
en una máquina local. Sin embargo, no necesitas escribir código. En su lugar, construyes,
ejecutas y pruebas un servicio existente: `ratings`.

El servicio `ratings` es una pequeña aplicación web escrita en
[Node.js](https://nodejs.org/en/) que puede ejecutarse por sí sola. Realiza acciones similares
a las de otras aplicaciones web:

- Escucha en el puerto que recibe como parámetro.
- Espera solicitudes `HTTP GET` en la ruta `/ratings/{productID}` y retorna las
  calificaciones del producto que coincide con el valor que el cliente especifica para `productID`.
- Espera solicitudes `HTTP POST` en la ruta `/ratings/{productID}` y actualiza las
  calificaciones del producto que coincide con el valor que especificas para `productID`.

Sigue estos pasos para descargar el código de la aplicación, instalar sus dependencias,
y ejecutarla localmente:

1. Descarga
    [el código del servicio]({{< github_blob >}}/samples/bookinfo/src/ratings/ratings.js)
    y
    [el archivo de paquete]({{< github_blob >}}/samples/bookinfo/src/ratings/package.json)
    en un directorio separado:

    {{< text bash >}}
    $ mkdir ratings
    $ cd ratings
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/ratings.js -o ratings.js
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/package.json -o package.json
    {{< /text >}}

1. Examina superficialmente el código del servicio y nota los siguientes elementos:
    - Las características del servidor web:
        - escuchar en un puerto
        - manejar solicitudes y respuestas
    - Los aspectos relacionados con HTTP:
        - headers
        - path
        - código de estado

    {{< tip >}}
    En Node.js, la funcionalidad del servidor web está embebida en el código de la aplicación. Una aplicación
    web de Node.js se ejecuta como un proceso independiente.
    {{< /tip >}}

1. Las aplicaciones de Node.js están escritas en JavaScript, lo que significa que no hay
    paso de compilación explícito. En su lugar, usan [compilación just-in-time](https://en.wikipedia.org/wiki/Just-in-time_compilation). Construir una aplicación de Node.js, entonces significa instalar sus dependencias. Instala
    las dependencias del servicio `ratings` en la misma carpeta donde almacenaste
    el código del servicio y el archivo de paquete:

    {{< text bash >}}
    $ npm install
    npm notice created a lockfile as package-lock.json. You should commit this file.
    npm WARN ratings No description
    npm WARN ratings No repository field.
    npm WARN ratings No license field.

    added 24 packages in 2.094s
    {{< /text >}}

1. Ejecuta el servicio, pasando `9080` como parámetro. La aplicación entonces escucha en el puerto 9080.

    {{< text bash >}}
    $ npm start 9080
    > @ start /tmp/ratings
    > node ratings.js "9080"
    Server listening on: http://0.0.0.0:9080
    {{< /text >}}

{{< tip >}}
El servicio `ratings` es una aplicación web y puedes comunicarte con ella como lo harías
con cualquier otra aplicación web. Puedes usar un navegador o un cliente web de línea de comandos como
[`curl`](https://curl.haxx.se) o [`Wget`](https://www.gnu.org/software/wget/).
Ya que ejecutas el servicio `ratings` localmente, también puedes acceder a él a través del
hostname `localhost`.
{{< /tip >}}

1. Abre [http://localhost:9080/ratings/7](http://localhost:9080/ratings/7) en
    tu navegador o accede a `ratings` usando el comando `curl` desde una ventana de terminal diferente:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1. Usa el método `POST` del comando `curl` para establecer las calificaciones para el
    producto a `1`:

    {{< text bash >}}
    $ curl -X POST localhost:9080/ratings/7 -d '{"Reviewer1":1,"Reviewer2":1}'
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. Verifica las calificaciones actualizadas:

    {{< text bash >}}
    $ curl localhost:9080/ratings/7
    {"id":7,"ratings":{"Reviewer1":1,"Reviewer2":1}}
    {{< /text >}}

1. Usa `Ctrl-C` en la terminal que ejecuta el servicio para detenerlo.

¡Felicidades, ahora puedes construir, probar y ejecutar un servicio en tu computadora local!

Estás listo para [empaquetar el servicio](/es/docs/examples/microservices-istio/package-service) en un contenedor.
