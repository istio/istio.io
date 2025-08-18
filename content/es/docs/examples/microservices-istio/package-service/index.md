---
title: Ejecutar ratings en Docker
overview: Ejecutar un solo microservicio en un contenedor Docker.

weight: 20

owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

Este módulo muestra cómo crear una imagen [Docker](https://www.docker.com) y ejecutarla localmente.

1.  Descarga el [`Dockerfile`](https://docs.docker.com/engine/reference/builder/) para el microservicio `ratings`.

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/ratings/Dockerfile -o Dockerfile
    {{< /text >}}

1.  Observa el `Dockerfile`.

    {{< text bash >}}
    $ cat Dockerfile
    {{< /text >}}

    Nota que copia los archivos
    en el sistema de archivos del contenedor y luego ejecuta el comando `npm install` que ejecutaste en el módulo anterior.
    El comando `CMD` instruye a Docker para ejecutar el Service `ratings` en el puerto `9080`.

1.  Crea una variable de entorno para almacenar tu ID de usuario que se usará para etiquetar la imagen docker para el Service `ratings`.
    Por ejemplo, `user`.

    {{< text bash >}}
    $ export USER=user
    {{< /text >}}

1.  Construye una imagen Docker desde el `Dockerfile`:

    {{< text bash >}}
    $ docker build -t $USER/ratings .
    ...
    Step 9/9 : CMD node /opt/microservices/ratings.js 9080
    ---> Using cache
    ---> 77c6a304476c
    Successfully built 77c6a304476c
    Successfully tagged user/ratings:latest
    {{< /text >}}

1.  Ejecuta ratings en Docker. El siguiente comando [docker run](https://docs.docker.com/engine/reference/commandline/run/)
    instruye a Docker para exponer el puerto `9080` del contenedor al puerto `9081` de tu computadora, permitiéndote acceder al
    microservicio `ratings` en el puerto `9081`.

    {{< text bash >}}
    $ docker run --name my-ratings  --rm -d -p 9081:9080 $USER/ratings
    {{< /text >}}

1.  Accede a [http://localhost:9081/ratings/7](http://localhost:9081/ratings/7) en tu navegador o usa el siguiente comando `curl`:

    {{< text bash >}}
    $ curl localhost:9081/ratings/7
    {"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

1.  Observa el contenedor en ejecución. Ejecuta el comando [docker ps](https://docs.docker.com/engine/reference/commandline/ps/)
    para listar todos los contenedores en ejecución y nota el contenedor con la imagen `<your user name>/ratings`.

    {{< text bash >}}
    $ docker ps
    CONTAINER ID        IMAGE            COMMAND                  CREATED             STATUS              PORTS                    NAMES
    47e8c1fe6eca        user/ratings     "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes        0.0.0.0:9081->9080/tcp   elated_stonebraker
    ...
    {{< /text >}}

1.  Detén el contenedor en ejecución:

    {{< text bash >}}
    $ docker stop my-ratings
    {{< /text >}}

Has aprendido cómo empaquetar un solo Service en un contenedor. El siguiente paso es aprender cómo [desplegar toda la aplicación en un Cluster de Kubernetes](/es/docs/examples/microservices-istio/bookinfo-kubernetes).
