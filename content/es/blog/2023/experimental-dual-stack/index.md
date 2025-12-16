---
title: "Soporte para Clústeres Kubernetes de Doble Pila"
description: "Soporte experimental para Clústeres Kubernetes de Doble Pila."
publishdate: 2023-03-10
attribution: "Steve Zhang (Intel), Alex Xu (Intel), Iris Ding (Intel), Jacob Delgado (F5), Ying-chun Cai (anteriormente F5)"
keywords: [dual-stack]
---

Durante el último año, Intel y F5 han colaborado en un esfuerzo para brindar soporte para
[Redes de Doble Pila de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/dual-stack/) a Istio.

## Antecedentes

Este proceso nos ha llevado más tiempo del previsto y continuamos teniendo trabajo por hacer. El equipo inicialmente comenzó con un diseño basado
en una implementación de referencia de F5. El diseño llevó a un [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing) que nos hizo reexaminar nuestro enfoque. En particular, existían preocupaciones sobre problemas de memoria y rendimiento que la comunidad quería
abordar antes de la implementación. El diseño original tuvo que duplicar la configuración de Envoy para listeners, clusters, rutas y endpoints. Dado que muchas personas ya experimentan problemas de consumo de memoria y CPU de Envoy, los comentarios iniciales querían que reevaluáramos completamente este enfoque. Muchos proxies manejan transparentemente el tráfico saliente de doble pila independientemente de cómo se originó el tráfico. Gran parte de los comentarios más tempranos fue implementar el mismo comportamiento en Istio y Envoy.

## Redefiniendo el soporte de Doble Pila

Gran parte de los comentarios proporcionados por la comunidad para el RFC original fue actualizar Envoy para soportar mejor los casos de uso de doble pila
internamente en lugar de soportarlo dentro de Istio. Esto nos ha llevado a un [nuevo diseño](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing) donde hemos tomado las lecciones aprendidas así como los comentarios y las hemos aplicado para ajustarse a un diseño simplificado.

## Soporte para Doble Pila en Istio 1.17

Hemos trabajado con la comunidad de Envoy para resolver numerosas preocupaciones, lo cual es una razón por la cual la habilitación de doble pila nos
ha tomado un tiempo implementar. Hemos implementado [familia de IP coincidente para listener saliente](https://github.com/envoyproxy/envoy/issues/16804)
y [soportado múltiples direcciones por listener](https://github.com/envoyproxy/envoy/issues/11184). Alex Xu también ha
estado trabajando fervientemente para resolver problemas pendientes de larga data, con la capacidad de que Envoy tenga una
[forma más inteligente de elegir endpoints para doble pila](https://github.com/envoyproxy/envoy/issues/21640). Algunas de estas mejoras
a Envoy, como la capacidad de [habilitar opciones de socket en múltiples direcciones](https://github.com/envoyproxy/envoy/pull/23496),
han llegado en el lanzamiento de Istio 1.17 (p. ej. [direcciones de origen adicionales en clusters entrantes](https://github.com/istio/istio/pull/41618)).

Los cambios de API de Envoy realizados por el equipo se pueden encontrar en su sitio en [Direcciones de listener](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses) y [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig). Asegurarnos de que podamos tener soporte adecuado tanto en la conexión downstream como upstream para Envoy es importante para realizar
el soporte de doble pila.

En total, el equipo ha enviado más de una decena de PRs a Envoy y está trabajando en al menos media docena más para facilitar la adopción de doble pila
de Envoy para Istio.

Mientras tanto, en el lado de Istio puedes seguir el progreso en [Issue #40394](https://github.com/istio/istio/issues/40394).
El progreso se ha ralentizado un poco últimamente mientras continuamos trabajando con Envoy en varios temas, sin embargo, estamos felices de
¡anunciar soporte experimental para doble pila en Istio 1.17!

## Un experimento rápido usando Doble Pila

{{< tip >}}
Si quieres usar KinD para tu prueba, puedes configurar un clúster de doble pila con el siguiente comando:

{{< text bash >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

{{< /tip >}}
1. Habilita el soporte experimental de doble pila en Istio 1.17.0+ con lo siguiente:

    {{< text bash >}}
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_DUAL_STACK: "true"
      values:
        pilot:
          env:
            ISTIO_DUAL_STACK: "true"
    EOF
    {{< /text >}}

1. Crea tres namespaces:

    * `dual-stack`: `tcp-echo` escuchará tanto en una dirección IPv4 como IPv6.
    * `ipv4`: `tcp-echo` escuchará solo en una dirección IPv4.
    * `ipv6`: `tcp-echo` escuchará solo en una dirección IPv6.

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. Habilita la inyección de sidecar en todos esos namespaces así como en el namespace default:

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. Crea deployments `tcp-echo` en los namespaces:

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f {{< github_file >}}/samples/tcp-echo/tcp-echo-dual-stack.yaml
    $ kubectl apply --namespace ipv4 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv4.yaml
    $ kubectl apply --namespace ipv6 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv6.yaml
    {{< /text >}}

1. Crea deployment sleep en el namespace default:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

1. Verifica el tráfico:

    {{< text bash >}}
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
    hello dualstack
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

¡Ahora puedes experimentar con servicios de doble pila en tu entorno!

## Cambios importantes en Listeners y Endpoints

Para el experimento anterior, notarás que se hacen cambios en listeners y rutas:

{{< text bash >}}
$ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
{{< /text >}}

Verás que los listeners ahora están vinculados a múltiples direcciones, pero solo para servicios de doble pila. Otros servicios solo
estarán escuchando en una sola dirección IP.

{{< text json >}}
        "name": "fd00:10:96::f9fc_9000",
        "address": {
            "socketAddress": {
                "address": "fd00:10:96::f9fc",
                "portValue": 9000
            }
        },
        "additionalAddresses": [
            {
                "address": {
                    "socketAddress": {
                        "address": "10.96.106.11",
                        "portValue": 9000
                    }
                }
            }
        ],
{{< /text >}}

Las direcciones entrantes virtuales ahora también están configuradas para escuchar tanto en `0.0.0.0` como en `[::]`.

{{< text json >}}
    "name": "virtualInbound",
    "address": {
        "socketAddress": {
            "address": "0.0.0.0",
            "portValue": 15006
        }
    },
    "additionalAddresses": [
        {
            "address": {
                "socketAddress": {
                    "address": "::",
                    "portValue": 15006
                }
            }
        }
    ],
{{< /text >}}

Los endpoints de Envoy ahora están configurados para enrutar tanto a IPv4 como IPv6:

{{< text bash >}}
$ istioctl proxy-config endpoints "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" --port 9000
ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
{{< /text >}}

## Participa

Queda mucho trabajo por hacer, y eres bienvenido a ayudarnos con las tareas restantes necesarias para que el soporte de doble pila llegue a
Alpha [aquí](https://github.com/istio/enhancements/blob/master/features/dual-stack-support.md).

Por ejemplo, Iris Ding (Intel) y Li Chun (Intel) ya están trabajando con la comunidad para obtener la redirección de
tráfico de red para ambient, y esperamos que ambient soporte doble pila para su próximo lanzamiento alpha en
Istio 1.18.

Nos encantaría recibir tus comentarios y si estás ansioso por trabajar con nosotros, pasa por nuestro canal de slack, #dual-stack dentro del
[Istio Slack](https://slack.istio.io/).

_¡Gracias al equipo que ha trabajado en doble pila de Istio!_
* Intel: [Steve Zhang](https://github.com/zhlsunshine), [Alex Xu](https://github.com/soulxu), [Iris Ding](https://github.com/irisdingbj)
* F5: [Jacob Delgado](https://github.com/jacob-delgado)
* [Yingchun Cai](https://github.com/ycai-aspen) (anteriormente de F5)
