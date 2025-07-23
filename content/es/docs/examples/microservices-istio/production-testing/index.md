---
title: Pruebas en producción
overview: Probar una nueva versión de un microservicio en producción.

weight: 40

owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

¡Prueba tu microservicio, en producción!

## Probar microservicios individuales

1.  Emite una solicitud HTTP desde el Pod de prueba a uno de tus servicios:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=curl -o jsonpath='{.items[0].metadata.name}') -- curl -sS http://ratings:9080/ratings/7
    {{< /text >}}

## Pruebas de caos

Realiza algunas [pruebas de caos](http://www.boyter.org/2016/07/chaos-testing-engineering/)
en producción y ve cómo reacciona tu aplicación. Después de cada operación de caos,
accede a la página web de la aplicación y ve si algo cambió. Verifica
el estado de los pods con `kubectl get pods`.

1.  Termina el Service `details` en un Pod.

    {{< text bash >}}
    $ kubectl exec $(kubectl get pods -l app=details -o jsonpath='{.items[0].metadata.name}') -- pkill ruby
    {{< /text >}}

1.  Verifica el estado de los pods:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   1          47m
    details-v1-6d86fd9949-mksv7     1/1     Running   0          47m
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          48m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          47m
    productpage-v1-c9965499-nccwq   1/1     Running   0          47m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          47m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          47m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          47m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          47m
    curl-88ddbcfdd-l9zq4            1/1     Running   0          47m
    {{< /text >}}

    Nota que el primer Pod se reinició una vez.

1.  Termina el servicio `details` en todos sus pods:

    {{< text bash >}}
    $ for pod in $(kubectl get pods -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating "$pod"; kubectl exec "$pod" -- pkill ruby; done
    {{< /text >}}

1.  Verifica la página web de la aplicación:

    {{< image width="80%"
        link="bookinfo-details-unavailable.png"
        caption="Aplicación Web Bookinfo, detalles no disponibles"
        >}}

    Nota que la sección de detalles contiene mensajes de error en lugar de detalles del libro.

1.  Verifica el estado de los pods:

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   2          48m
    details-v1-6d86fd9949-mksv7     1/1     Running   1          48m
    details-v1-6d86fd9949-q8rrf     1/1     Running   1          49m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          48m
    productpage-v1-c9965499-nccwq   1/1     Running   0          48m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          48m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          48m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          48m
    curl-88ddbcfdd-l9zq4            1/1     Running   0          48m
    {{< /text >}}

    El primer Pod se reinició dos veces y otros dos pods `details`
    se reiniciaron una vez. Puedes experimentar el estado `Error` y el
    estado `CrashLoopBackOff` hasta que los pods alcancen el estado `Running`.

1. Usa Ctrl-C en la terminal para detener el bucle infinito que se está ejecutando para simular tráfico.

En ambos casos, la aplicación no falló. El fallo en el
microservicio `details` no causó que otros microservicios fallaran. Este comportamiento significa que
no tuviste una **falla en cascada** en esta situación. En su lugar, tuviste
**degradación gradual del servicio**: a pesar de que un microservicio falló, la
aplicación aún pudo proporcionar funcionalidad útil. Mostró las reseñas
y la información básica sobre el libro.

Estás listo para
[agregar una nueva versión de la aplicación reviews](/es/docs/examples/microservices-istio/add-new-microservice-version).
