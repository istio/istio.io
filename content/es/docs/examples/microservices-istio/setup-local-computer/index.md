---
title: Configurar una Computadora Local
overview: Configurar tu computadora local para el tutorial.
weight: 3
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

En este módulo preparas tu computadora local para el tutorial.

1.  Instala [`curl`](https://curl.haxx.se/download.html).

1.  Instala [Node.js](https://nodejs.org/en/download/).

1.  Instala [Docker](https://docs.docker.com/install/).

1.  Instala [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

1.  Establece la variable de entorno `KUBECONFIG` para el archivo de configuración que recibiste de los instructores del tutorial, o
    creaste tú mismo en el módulo anterior.

    {{< text bash >}}
    $ export KUBECONFIG=<the file you received or created in the previous module>
    {{< /text >}}

1.  Verifica que la configuración surtió efecto imprimiendo el namespace actual:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    Deberías ver en la salida el nombre del namespace, asignado para ti por los instructores o asignado por
    ti mismo en el módulo anterior.

1.  Descarga uno de los [archivos de release de Istio](https://github.com/istio/istio/releases) y extrae
    la herramienta de línea de comandos `istioctl` del directorio `bin`, y verifica que puedas
    ejecutar `istioctl` con el siguiente comando:

    {{< text bash >}}
    $ istioctl version
    client version: 1.22.0
    control plane version: 1.22.0
    data plane version: 1.22.0 (4 proxies)
    {{< /text >}}

¡Felicidades, configuraste tu computadora local!

Estás listo para [ejecutar un solo servicio localmente](/es/docs/examples/microservices-istio/single/).
