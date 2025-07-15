---
title: Solucionar problemas de conectividad con ztunnel
description: Cómo validar que los proxies de nodo tienen la configuración correcta.
weight: 60
owner: istio/wg-networking-maintainers
test: no
---

Esta guía describe algunas opciones para monitorear la configuración y la ruta de datos del proxy ztunnel. Esta información también puede ayudar con algunas soluciones de problemas de alto nivel y en la identificación de información que sería útil recopilar y proporcionar en un informe de error si hay algún problema.

## Ver el estado del proxy ztunnel

El proxy ztunnel obtiene la configuración y la información de descubrimiento del {{< gloss >}}control plane{{< /gloss >}} de istiod a través de las API de xDS.

El comando `istioctl ztunnel-config` te permite ver las cargas de trabajo descubiertas tal como las ve un proxy ztunnel.

En el primer ejemplo, ves todas las cargas de trabajo y los componentes del control plane que ztunnel está rastreando actualmente, incluida la información sobre la dirección IP y el protocolo que se debe usar al conectarse a ese componente y si hay un proxy de waypoint asociado con esa carga de trabajo.

{{< text bash >}}
$ istioctl ztunnel-config workloads
NAMESPACE          POD NAME                                IP          NODE                  WAYPOINT PROTOCOL
default            bookinfo-gateway-istio-59dd7c96db-q9k6v 10.244.1.11 ambient-worker        None     TCP
default            details-v1-cf74bb974-5sqkp              10.244.1.5  ambient-worker        None     HBONE
default            productpage-v1-87d54dd59-fn6vw          10.244.1.10 ambient-worker        None     HBONE
default            ratings-v1-7c4bbf97db-zvkdw             10.244.1.6  ambient-worker        None     HBONE
default            reviews-v1-5fd6d4f8f8-knbht             10.244.1.16 ambient-worker        None     HBONE
default            reviews-v2-6f9b55c5db-c94m2             10.244.1.17 ambient-worker        None     HBONE
default            reviews-v3-7d99fd7978-7rgtd             10.244.1.18 ambient-worker        None     HBONE
default            curl-7656cf8794-r7zb9                   10.244.1.12 ambient-worker        None     HBONE
istio-system       istiod-7ff4959459-qcpvp                 10.244.2.5  ambient-worker2       None     TCP
istio-system       ztunnel-6hvcw                           10.244.1.4  ambient-worker        None     TCP
istio-system       ztunnel-mf476                           10.244.2.6  ambient-worker2       None     TCP
istio-system       ztunnel-vqzf9                           10.244.0.6  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-2sms2                10.244.0.3  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-5bf9c                10.244.0.2  ambient-control-plane None     TCP
local-path-storage local-path-provisioner-7577fdbbfb-pslg6 10.244.0.4  ambient-control-plane None     TCP

{{< /text >}}

El comando `ztunnel-config` se puede usar para ver los secretos que contienen los certificados TLS que el proxy ztunnel ha recibido del control plane de istiod para usar en mTLS.

{{< text bash >}}
$ istioctl ztunnel-config certificates "$ZTUNNEL".istio-system
CERTIFICATE NAME                                              TYPE     STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/default/sa/bookinfo-details         Leaf     Available     true           c198d859ee51556d0eae13b331b0c259     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-details         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Leaf     Available     true           64c3828993c7df6f85a601a1615532cc     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Leaf     Available     true           720479815bf6d81a05df8a64f384ebb0     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Leaf     Available     true           285697fb2cf806852d3293298e300c86     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/curl                    Leaf     Available     true           fa33bbb783553a1704866842586e4c0b     2024-05-05T09:25:49Z     2024-05-04T09:23:49Z
spiffe://cluster.local/ns/default/sa/curl                    Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
{{< /text >}}

Usando estos comandos, puedes verificar que los proxies ztunnel estén configurados con todas las cargas de trabajo y el certificado TLS esperados. Además, la información faltante se puede usar para solucionar cualquier error de red.

Puedes usar la opción `all` para ver todas las partes de la configuración de ztunnel con un solo comando de la CLI:

{{< text bash >}}
$ istioctl ztunnel-config all -o json
{{< /text >}}

También puedes ver el volcado de configuración sin procesar de un proxy ztunnel a través de un `curl` a un punto final dentro de su pod:

{{< text bash >}}
$ kubectl debug -it $ZTUNNEL -n istio-system --image=curlimages/curl -- curl localhost:15000/config_dump
{{< /text >}}

## Ver el estado de Istiod para los recursos xDS de ztunnel

A veces, es posible que desees ver el estado de los recursos de configuración del proxy ztunnel tal como se mantienen en el control plane de istiod, en el formato de los recursos de la API de xDS definidos especialmente para los proxies ztunnel. Esto se puede hacer ejecutando un comando dentro del pod de istiod y obteniendo esta información desde el puerto 15014 para un proxy ztunnel determinado, como se muestra en el siguiente ejemplo. Esta salida también se puede guardar y ver con una utilidad de formateo de impresión bonita de JSON para facilitar la navegación (no se muestra en el ejemplo).

{{< text bash >}}
$ export ISTIOD=$(kubectl get pods -n istio-system -l app=istiod -o=jsonpath='{.items[0].metadata.name}')
$ kubectl debug -it $ISTIOD -n istio-system --image=curlimages/curl -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system
{{< /text >}}

## Verificar el tráfico de ztunnel a través de los registros

Los registros de tráfico de ztunnel se pueden consultar utilizando las instalaciones de registro estándar de Kubernetes.

{{< text bash >}}
$ kubectl -n default exec deploy/curl -- sh -c 'for i in $(seq 1 10); do curl -s -I http://productpage:9080/; done'
HTTP/1.1 200 OK
Server: Werkzeug/3.0.1 Python/3.12.1
--snip--
{{< /text >}}

La respuesta que se muestra confirma que el pod cliente recibe respuestas del servicio. Ahora puedes verificar los registros de los pods de ztunnel para confirmar que el tráfico se envió a través del túnel HBONE.

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2024-05-04T09:59:05.028709Z info    access  connection complete src.addr=10.244.1.12:60059 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.10:9080 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="inbound" bytes_sent=175 bytes_recv=80 duration="1ms"
2024-05-04T09:59:05.028771Z info    access  connection complete src.addr=10.244.1.12:58508 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.10:15008 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="outbound" bytes_sent=80 bytes_recv=175 duration="1ms"
--snip--
{{< /text >}}

Estos mensajes de registro confirman que el tráfico se envió a través del proxy ztunnel. Se puede realizar un monitoreo adicional de grano fino verificando los registros en las instancias específicas del proxy ztunnel que se encuentran en los mismos nodos que los pods de origen y destino del tráfico. Si no se ven estos registros, entonces una posibilidad es que la [redirección de tráfico](/es/docs/ambient/architecture/traffic-redirection) no funcione correctamente.

{{< tip >}}
El tráfico siempre atraviesa el pod de ztunnel, incluso cuando el origen y el destino del tráfico se encuentran en el mismo nodo de cómputo.
{{< /tip >}}

### Verificar el balanceo de carga de ztunnel

El proxy ztunnel realiza automáticamente el balanceo de carga del lado del cliente si el destino es un servicio con múltiples puntos finales. No se necesita configuración adicional. El algoritmo de balanceo de carga es un algoritmo interno fijo de Round Robin L4 que distribuye el tráfico en función del estado de la conexión L4 y no es configurable por el usuario.

{{< tip >}}
Si el destino es un servicio con múltiples instancias o pods y no hay un waypoint asociado con el servicio de destino, entonces el ztunnel de origen realiza el balanceo de carga L4 directamente a través de estas instancias o backends de servicio y luego envía el tráfico a través de los proxies ztunnel remotos asociados con esos backends. Si el servicio de destino está configurado para usar uno o más proxies de waypoint, entonces el proxy ztunnel de origen realiza el balanceo de carga distribuyendo el tráfico a través de estos proxies de waypoint y envía el tráfico a través de los proxies ztunnel remotos en el nodo que aloja las instancias del proxy de waypoint.
{{< /tip >}}

Al llamar a un servicio con múltiples backends, podemos validar que el tráfico del cliente se equilibra entre las réplicas del servicio.

{{< text bash >}}
$ kubectl -n default exec deploy/curl -- sh -c 'for i in $(seq 1 10); do curl -s -I http://reviews:9080/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "outbound"
--snip--
2024-05-04T10:11:04.964851Z info    access  connection complete src.addr=10.244.1.12:35520 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.969578Z info    access  connection complete src.addr=10.244.1.12:35526 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.974720Z info    access  connection complete src.addr=10.244.1.12:35536 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.7:15008 dst.hbone_addr="10.244.1.7:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v1-5fd6d4f8f8-26j92" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.979462Z info    access  connection complete src.addr=10.244.1.12:35552 src.workload="curl-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/curl" dst.addr=10.244.1.8:15008 dst.hbone_addr="10.244.1.8:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v2-6f9b55c5db-c2dtw" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
{{< /text >}}

Este es un algoritmo de balanceo de carga de round robin y es independiente de cualquier algoritmo de balanceo de carga que se pueda configurar dentro del campo `TrafficPolicy` de un `VirtualService`, ya que, como se discutió anteriormente, todos los aspectos de los objetos de la API de `VirtualService` se instancian en los proxies de Waypoint y no en los proxies de ztunnel.

### Observabilidad del tráfico en modo ambient

Además de verificar los registros de ztunnel y otras opciones de monitoreo mencionadas anteriormente, también puedes usar las funciones normales de monitoreo y telemetría de Istio para monitorear el tráfico de la aplicación usando el modo de data plane ambient.

* [Instalación de Prometheus](/es/docs/ops/integrations/prometheus/#installation)
* [Instalación de Kiali](/es/docs/ops/integrations/kiali/#installation)
* [Métricas de Istio](/es/docs/reference/config/metrics/)
* [Consultar métricas de Prometheus](/es/docs/tasks/observability/metrics/querying-metrics/)

Si un servicio solo usa la superposición segura proporcionada por ztunnel, las métricas de Istio informadas solo serán las métricas de TCP L4 (a saber, `istio_tcp_sent_bytes_total`, `istio_tcp_received_bytes_total`, `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`). El conjunto completo de métricas de Istio y Envoy se informará si se utiliza un proxy de waypoint.
