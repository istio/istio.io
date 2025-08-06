---
title: Aplicación Bookinfo
description: Despliega una aplicación de ejemplo compuesta por cuatro microservicios separados usados para demostrar varias características de Istio.
weight: 10
aliases:
    - /docs/samples/bookinfo.html
    - /docs/guides/bookinfo/index.html
    - /docs/guides/bookinfo.html
owner: istio/wg-docs-maintainers
test: yes
---

Este ejemplo despliega una aplicación de ejemplo compuesta por cuatro microservicios separados usados
para demostrar varias características de Istio.

{{< tip >}}
Si instalaste Istio usando las instrucciones de [Comenzando](/es/docs/setup/getting-started/),
ya tienes Bookinfo instalado y puedes omitir la mayoría de estos pasos
e ir directamente a [Definir las versiones del servicio](/es/docs/examples/bookinfo/#define-the-service-versions).
{{< /tip >}}

La aplicación muestra información sobre un
libro, similar a una sola entrada de catálogo de una librería en línea. Mostrado
en la página está una descripción del libro, detalles del libro (ISBN, número de
páginas, etc.), y algunas reseñas del libro.

La aplicación Bookinfo está dividida en cuatro microservicios separados:

* `productpage`. El microservicio `productpage` llama a los microservicios `details` y `reviews` para poblar la página.
* `details`. El microservicio `details` contiene información del libro.
* `reviews`. El microservicio `reviews` contiene reseñas del libro. También llama al microservicio `ratings`.
* `ratings`. El microservicio `ratings` contiene información de clasificación del libro que acompaña a una reseña del libro.

Hay 3 versiones del microservicio `reviews`:

* La versión v1 no llama al servicio `ratings`.
* La versión v2 llama al servicio `ratings`, y muestra cada calificación como 1 a 5 estrellas negras.
* La versión v3 llama al servicio `ratings`, y muestra cada calificación como 1 a 5 estrellas rojas.

La arquitectura de extremo a extremo de la aplicación se muestra a continuación.

{{< image width="80%" link="./noistio.svg" caption="Aplicación Bookinfo sin Istio" >}}

Esta aplicación es políglota, es decir, los microservicios están escritos en diferentes lenguajes.
Vale la pena señalar que estos servicios no tienen dependencias en Istio, pero hacen un ejemplo
interesante de service mesh, particularmente debido a la multitud de servicios, lenguajes y versiones
para el servicio `reviews`.

## Antes de comenzar

Si no has hecho esto aún, configura Istio siguiendo las instrucciones
en la guía de [instalación](/es/docs/setup/).

{{< boilerplate gateway-api-support >}}

## Desplegando la aplicación

Para ejecutar el ejemplo con Istio no se necesitan cambios en
la aplicación en sí. En su lugar, simplemente necesitas configurar y ejecutar los servicios en un
entorno habilitado para Istio, con sidecars de Envoy inyectados junto a cada servicio.
El resultado del despliegue será así:

{{< image width="80%" link="./withistio.svg" caption="Aplicación Bookinfo" >}}

Todos los microservicios estarán empaquetados con un sidecar de Envoy que intercepta
llamadas entrantes y salientes para los servicios, proporcionando los ganchos necesarios para controlar externamente,
a través del plano de control de Istio, la enrutamiento, la recopilación de métricas, y la aplicación de políticas.

### Iniciar los servicios de la aplicación

{{< tip >}}
Si usas GKE, asegúrate de que tu clúster tenga al menos 4 nodos estándar de GKE. Si usas Minikube, asegúrate de que tengas al menos 4GB de RAM.
{{< /tip >}}

1.  Cambia al directorio raíz de la instalación de Istio.

1.  La instalación de Istio por defecto usa [inyección de sidecar automática](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection).
    Etiqueta el namespace que alojará la aplicación con `istio-injection=enabled`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

1.  Despliega tu aplicación usando el comando `kubectl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    El comando instala todos los cuatro servicios mostrados en el diagrama de arquitectura de la aplicación Bookinfo.
    Todas las 3 versiones del servicio `reviews`, v1, v2 y v3, se inician.

    {{< tip >}}
    En un despliegue real, las nuevas versiones de un microservicio se implementan
    con el tiempo en lugar de desplegar todas las versiones simultáneamente.
    {{< /tip >}}

1.  Confirma que todos los servicios y pods están definidos y ejecutándose correctamente:

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
    kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
    productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
    ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
    reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
    {{< /text >}}

    y

    {{< text bash >}}
    $ kubectl get pods
    NAME                             READY     STATUS    RESTARTS   AGE
    details-v1-1520924117-48z17      2/2       Running   0          6m
    productpage-v1-560495357-jk1lz   2/2       Running   0          6m
    ratings-v1-734492171-rnr5l       2/2       Running   0          6m
    reviews-v1-874083890-f0qf0       2/2       Running   0          6m
    reviews-v2-1343845940-b34q5      2/2       Running   0          6m
    reviews-v3-1813607990-8ch52      2/2       Running   0          6m
    {{< /text >}}

1.  Para confirmar que la aplicación Bookinfo está funcionando, envía una solicitud a ella mediante un comando `curl` desde algún pod, por ejemplo desde `ratings`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

### Determinar la IP de entrada y el puerto

Ahora que los servicios de Bookinfo están en funcionamiento, necesitas hacer que la aplicación sea accesible desde fuera de tu
clúster de Kubernetes, por ejemplo, desde un navegador. Se usa un gateway para este propósito.

1. Crea un gateway para la aplicación Bookinfo:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    Crea un [Istio Gateway](/es/docs/concepts/traffic-management/#gateways) usando el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

    Confirma que el gateway se ha creado:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               AGE
    bookinfo-gateway   32s
    {{< /text >}}

    Sigue [estas instrucciones](/es/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) para establecer las variables `INGRESS_HOST` y `INGRESS_PORT` para acceder al gateway. Vuelve aquí cuando estén configuradas.

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< boilerplate external-loadbalancer-support >}}

    Crea un [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) usando el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Debido a que la creación de un recurso `Gateway` de Kubernetes también
    [implementará un servicio proxy asociado](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment),
    ejecuta el siguiente comando para esperar a que el gateway esté listo:

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

    Obtén la dirección y el puerto del gateway de la recurso del gateway de bookinfo:

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  Establece `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

## Confirmar que la aplicación es accesible desde fuera del clúster

Para confirmar que la aplicación Bookinfo es accesible desde fuera del clúster, ejecuta el siguiente comando `curl`:

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

También puedes apuntar tu navegador a `http://$GATEWAY_URL/productpage`
para ver la página web de Bookinfo. Si refrescas la página varias veces, deberías
ver diferentes versiones de reseñas mostradas en `productpage`, presentadas en un estilo round robin (estrellas rojas, estrellas negras, sin estrellas), ya que aún no hemos usado Istio para controlar el
enrutamiento de versiones.

## Definir las versiones del servicio

Antes de poder usar Istio para controlar el enrutamiento de versiones de Bookinfo, necesitas definir las versiones disponibles.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Istio usa *subsets*, en [destination rules](/es/docs/concepts/traffic-management/#destination-rules),
para definir versiones de un servicio.
Ejecuta el siguiente comando para crear reglas de destino por defecto para los servicios de Bookinfo:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

{{< tip >}}
Las configuraciones de perfil `default` y `demo` de [perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) tienen habilitado [auto mutual TLS](/es/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) por defecto.
Para aplicar mutual TLS, usa las reglas de destino en `samples/bookinfo/networking/destination-rule-all-mtls.yaml`.
{{< /tip >}}

Espera unos segundos para que las reglas de destino se propaguen.

Puedes mostrar las reglas de destino con el siguiente comando:

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

A diferencia de la API de Istio, que usa `DestinationRule` subsets para definir las versiones de un servicio,
la API de Kubernetes Gateway usa definiciones de servicios de backend para este propósito.

Ejecuta el siguiente comando para crear definiciones de servicios de backend para las tres versiones del servicio `reviews`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## ¿Qué sigue?

Ahora puedes usar este ejemplo para experimentar con las características de Istio
para el enrutamiento de tráfico, inyección de fallos, límites de velocidad, etc.
Para proceder, visita una o más de las [Tareas de Istio](/es/docs/tasks),
dependiendo de tu interés. [Configurar el enrutamiento de solicitudes](/es/docs/tasks/traffic-management/request-routing/)
es un buen lugar para empezar para los principiantes.

## Limpieza

Cuando hayas terminado de experimentar con el ejemplo Bookinfo, desinstala y limpia
usando el siguiente comando:

{{< text bash >}}
$ @samples/bookinfo/platform/kube/cleanup.sh@
{{< /text >}}
