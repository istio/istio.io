---
title: Configurar proxies de waypoint
description: Obtén el conjunto completo de características de Istio con proxies opcionales de capa 7.
weight: 30
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: yes
---

Un **proxy de waypoint** es un despliegue opcional del proxy basado en Envoy para agregar procesamiento de capa 7 (L7) a un conjunto definido de cargas de trabajo.

Los proxies de waypoint se instalan, actualizan y escalan independientemente de las aplicaciones; el propietario de una aplicación no debería ser consciente de su existencia. En comparación con el modo de {{< gloss >}}data plane{{< /gloss >}} de sidecar, que ejecuta una instancia del proxy de Envoy junto con cada carga de trabajo, el número de proxies necesarios se puede reducir sustancialmente.

Un waypoint, o un conjunto de waypoints, se puede compartir entre aplicaciones con un límite de seguridad similar. Esto podría ser todas las instancias de una carga de trabajo en particular, o todas las cargas de trabajo en un namespace.

A diferencia del modo {{< gloss >}}sidecar{{< /gloss >}}, en el modo ambient las políticas son aplicadas por el waypoint de **destino**. En muchos sentidos, el waypoint actúa como una gateway a un recurso (un namespace, servicio o pod). Istio garantiza que todo el tráfico que ingresa al recurso pase a través del waypoint, que luego aplica todas las políticas para ese recurso.

## ¿Necesitas un proxy de waypoint?

El enfoque por capas de ambient permite a los usuarios adoptar Istio de una manera más incremental, pasando sin problemas de ninguna malla, a la superposición segura L4, al procesamiento L7 completo.

La mayoría de las características del modo ambient son proporcionadas por el proxy de nodo ztunnel. Ztunnel está diseñado para procesar solo el tráfico en la capa 4 (L4), de modo que pueda operar de forma segura como un componente compartido.

Cuando configuras la redirección a un waypoint, el tráfico será reenviado por ztunnel a ese waypoint. Si tus aplicaciones requieren alguna de las siguientes funciones de mesh L7, deberás usar un proxy de waypoint:

* **Gestión del tráfico**: enrutamiento y balanceo de carga HTTP, interrupción de circuito, limitación de velocidad, inyección de fallas, reintentos, tiempos de espera
* **Seguridad**: políticas de autorización enriquecidas basadas en primitivas L7 como el tipo de solicitud o el encabezado HTTP
* **Observabilidad**: métricas HTTP, registro de acceso, trazado

## Desplegar un proxy de waypoint

Los proxies de waypoint se despliegan usando los recursos de la API de Gateway de Kubernetes.

{{< boilerplate gateway-api-install-crds >}}

Puedes usar los subcomandos de istioctl waypoint para generar, aplicar o listar estos recursos.

Después de que se despliegue el waypoint, todo el namespace (o los servicios o pods que elijas) deben estar [inscritos](#useawaypoint) para usarlo.

Antes de desplegar un proxy de waypoint para un namespace específico, confirma que el namespace esté etiquetado con `istio.io/data plane-mode: ambient`:

{{< text syntax=bash snip_id=check_ns_label >}}
$ kubectl get ns -L istio.io/data plane-mode
NAME              STATUS   AGE   data plane-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

`istioctl` puede generar un recurso de Gateway de Kubernetes para un proxy de waypoint. Por ejemplo, para generar un proxy de waypoint llamado `waypoint` para el namespace `default` que pueda procesar el tráfico para los servicios en el namespace:

{{< text syntax=bash snip_id=gen_waypoint_resource >}}
$ istioctl waypoint generate --for service -n default
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Observa que el recurso de Gateway tiene un `gatewayClassName` de `istio-waypoint`, que instancia un waypoint gestionado por Istio. El recurso de Gateway está etiquetado con `istio.io/waypoint-for: service`, lo que indica que el waypoint puede procesar el tráfico para los servicios, que es el valor predeterminado.

Para desplegar un proxy de waypoint directamente, usa `apply` en lugar de `generate`:

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

O bien, puedes desplegar el recurso de Gateway generado:

{{< text syntax=bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Después de que se aplique el recurso de Gateway, Istiod monitoreará el recurso, desplegará y gestionará el despliegue y el servicio del waypoint correspondiente para los usuarios automáticamente.

### Tipos de tráfico de waypoint

Por defecto, un waypoint solo manejará el tráfico destinado a los **servicios** en sus namespaces. Esta elección se hizo porque el tráfico dirigido solo a un pod es raro y, a menudo, se usa para fines internos, como el raspado de Prometheus, y es posible que no se desee la sobrecarga adicional del procesamiento L7.

También es posible que el waypoint maneje todo el tráfico, solo maneje el tráfico enviado directamente a las **cargas de trabajo** (pods o VM) en el cluster, o ningún tráfico en absoluto. Los tipos de tráfico que se redirigirán al waypoint se determinan mediante la etiqueta `istio.io/waypoint-for` en el objeto `Gateway`.

Usa el argumento `--for` para `istioctl waypoint apply` para cambiar los tipos de tráfico que se pueden redirigir al waypoint:

| Valor de `waypoint-for` | Tipo de destino original |
| -------------------- | ------------ |
| `service`            | Servicios de Kubernetes |
| `workload`           | IP de pod o IP de VM |
| `all`                | Tráfico de servicio y de carga de trabajo |
| `none`               | Sin tráfico (útil para pruebas) |

La selección del waypoint se produce en función del tipo de destino, `service` o `workload`, al que se dirigió _originalmente_ el tráfico. Si el tráfico se dirige a un servicio que no tiene un waypoint, no se transitará un waypoint: incluso si la carga de trabajo final a la que llega _sí_ tiene un waypoint adjunto.

## Usar un proxy de waypoint {#useawaypoint}

Cuando se despliega un proxy de waypoint, no lo utiliza ningún recurso hasta que configures explícitamente esos recursos para que lo usen.

Para habilitar un namespace, servicio o Pod para que use un waypoint, agrega la etiqueta `istio.io/use-waypoint` con un valor del nombre del waypoint.

{{< tip >}}
La mayoría de los usuarios querrán aplicar un waypoint a todo un namespace, y te recomendamos que comiences con este enfoque.
{{< /tip >}}

Si usas `istioctl` para desplegar tu waypoint de namespace, puedes usar el parámetro `--enroll-namespace` para etiquetar automáticamente un namespace:

{{< text syntax=bash snip_id=enroll_ns_waypoint >}}
$ istioctl waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Alternativamente, puedes agregar la etiqueta `istio.io/use-waypoint: waypoint` al namespace `default` usando `kubectl`:

{{< text syntax=bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

Después de que un namespace se inscriba para usar un waypoint, cualquier solicitud de cualquier pod que use el modo de data plane ambient, a cualquier servicio que se ejecute en ese namespace, se enrutará a través del waypoint para el procesamiento L7 y la aplicación de políticas.

Si prefieres más granularidad que usar un waypoint para todo un namespace, puedes inscribir solo un servicio o pod específico para que use un waypoint. Esto puede ser útil si solo necesitas características L7 para algunos servicios en un namespace, si solo quieres que una extensión como un `WasmPlugin` se aplique a un servicio específico, o si estás llamando a un
servicio [headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) de Kubernetes por su dirección IP de pod.

{{< tip >}}
Si la etiqueta `istio.io/use-waypoint` existe tanto en un namespace como en un servicio, el waypoint del servicio tiene prioridad sobre el waypoint del namespace siempre que el waypoint del servicio pueda manejar el tráfico de `service` o `all`. Del mismo modo, una etiqueta en un pod tendrá prioridad sobre una etiqueta de namespace.
{{< /tip >}}

### Configurar un servicio para que use un waypoint específico

Usando los servicios de la aplicación de ejemplo [bookinfo](/es/docs/examples/bookinfo/), podemos desplegar un waypoint llamado `reviews-svc-waypoint` para el servicio `reviews`:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Etiqueta el servicio `reviews` para que use el waypoint `reviews-svc-waypoint`:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

Cualquier solicitud de los pods en la mesh al servicio `reviews` ahora se enrutará a través del waypoint `reviews-svc-waypoint`.

### Configurar un pod para que use un waypoint específico

Despliega un waypoint llamado `reviews-v2-pod-waypoint` para el pod `reviews-v2`.

{{< tip >}}
Recuerda que el valor predeterminado para los waypoints es apuntar a los servicios; como queremos apuntar explícitamente a un pod, debemos usar la etiqueta `istio.io/waypoint-for: workload`, que podemos generar usando el parámetro `--for workload` para istioctl.
{{< /tip >}}

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Etiqueta el pod `reviews-v2` para que use el waypoint `reviews-v2-pod-waypoint`:

{{< text syntax=bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

Cualquier solicitud de los pods en la mesh ambient a la IP del pod `reviews-v2` ahora se enrutará a través del waypoint `reviews-v2-pod-waypoint` para el procesamiento L7 y la aplicación de políticas.

{{< tip >}}
El tipo de destino original del tráfico se utiliza para determinar si se utilizará un waypoint de servicio o de carga de trabajo. Al usar el tipo de destino original, la mesh ambient evita que el tráfico transite dos veces por el waypoint, incluso si tanto el servicio como la carga de trabajo tienen waypoints adjuntos.
Por ejemplo, el tráfico que se dirige a un servicio, aunque finalmente se resuelva en una IP de pod, siempre es tratado por la mesh ambient como para el servicio y usaría un waypoint adjunto al servicio.
{{< /tip >}}

## Uso de waypoint entre namespaces {#usewaypointnamespace}

De forma predeterminada, un proxy de waypoint es utilizable por los recursos dentro del mismo namespace. A partir de Istio 1.23, es posible usar waypoints en diferentes namespaces. En esta sección, examinaremos
la configuración de la gateway necesaria para habilitar el uso entre namespaces y cómo configurar tus recursos para usar un waypoint de un namespace diferente.

### Configurar un waypoint para uso entre namespaces

Para habilitar el uso entre namespaces de un waypoint, la `Gateway` debe configurarse para [permitir rutas](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.AllowedRoutes) de otros namespaces.

{{< tip >}}
La palabra clave `All` se puede especificar como el valor para `allowedRoutes.namespaces.from` para permitir rutas desde cualquier namespace.
{{< /tip >}}

La siguiente `Gateway` permitiría que los recursos en un namespace llamado "cross-namespace-waypoint-consumer" usen esta `egress-gateway`:

{{< text syntax=yaml >}}
kind: Gateway
metadata:
  name: egress-gateway
  namespace: common-infrastructure
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: cross-namespace-waypoint-consumer
{{< /text >}}

### Configurar recursos para usar un proxy de waypoint entre namespaces

De forma predeterminada, el control plane de Istio buscará un waypoint especificado usando la etiqueta `istio.io/use-waypoint` en el mismo namespace que el recurso al que se aplica la etiqueta. Es posible usar
un waypoint en otro namespace agregando una nueva etiqueta, `istio.io/use-waypoint-namespace`. `istio.io/use-waypoint-namespace` funciona para todos los recursos que admiten la etiqueta `istio.io/use-waypoint`.
Juntas, las dos etiquetas especifican el nombre y el namespace de tu waypoint, respectivamente. Por ejemplo, para configurar un `ServiceEntry` llamado `istio-site` para que use un waypoint llamado `egress-gateway` en el namespace
llamado `common-infrastructure`, podrías usar los siguientes comandos:

{{< text syntax=bash >}}
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint=egress-gateway
serviceentries.networking.istio.io/istio-site labeled
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint-namespace=common-infrastructure
serviceentries.networking.istio.io/istio-site labeled
{{< /text >}}

### Limpieza

Puedes eliminar todos los waypoints de un namespace haciendo lo siguiente:

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
