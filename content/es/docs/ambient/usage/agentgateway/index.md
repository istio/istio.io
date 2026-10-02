---
title: Usar agentgateway
description: Configura agentgateway como un ingress gateway y como un waypoint en modo ambient.
weight: 40
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

[agentgateway](https://agentgateway.dev) es un proxy de data plane que se puede usar como
alternativa a Envoy. Está diseñado específicamente para el tráfico de agentes de IA y
[Model Context Protocol (MCP)](https://modelcontextprotocol.io), a la vez que admite
enrutamiento de propósito general en la capa 7 (L7). Cuando agentgateway está habilitado, Istio puede programarlo en lugar de
Envoy para dos roles en una {{< gloss "ambient" >}}mesh ambient{{< /gloss >}}:

* como un **ingress gateway**, que maneja el tráfico norte-sur que entra a la mesh, y
* como un proxy {{< gloss >}}waypoint{{< /gloss >}}, que maneja el procesamiento de capa 7 (L7) este-oeste para un conjunto de workloads.

Esta guía explica cómo funciona la integración, qué APIs son compatibles y cómo instalar Istio
y configurar agentgateway para cada rol.

## Cómo funciona la integración

Istiod configura agentgateway **exclusivamente a través de recursos de la Gateway API de Kubernetes**, que
entrega al proxy mediante xDS. El proxy es una implementación de {{< gloss >}}data plane{{< /gloss >}}
distinta de Envoy: cuando un `Gateway` selecciona una
[`GatewayClass`](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/) de agentgateway, Istiod aprovisiona y
gestiona un `Deployment` y un `Service` de agentgateway para él, de la misma manera que gestiona los gateways de Istio
basados en Envoy.

Al habilitar agentgateway se registran dos recursos `GatewayClass`:

| `GatewayClass` | Controlador | Rol |
| -------------- | ---------- | ---- |
| `istio-agentgateway` | `istio.io/agentgateway-controller` | Ingress gateway |
| `istio-agentgateway-waypoint` | `istio.io/agentgateway-waypoint-controller` | Proxy waypoint |

Debido a que el data plane se selecciona por `Gateway` mediante el campo `gatewayClassName`, agentgateway
y los gateways y waypoints basados en Envoy de Istio pueden coexistir en el mismo clúster. Eliges
agentgateway para un gateway o waypoint específico simplemente haciendo referencia a una de las clases anteriores.

## Configuración compatible y no compatible

Istio admite los siguientes recursos de [Gateway API](https://gateway-api.sigs.k8s.io/) para
agentgateway:

* `Gateway` (usando la clase `istio-agentgateway` o `istio-agentgateway-waypoint`)
* `HTTPRoute`, `GRPCRoute`, `TCPRoute` y `TLSRoute`
* `InferencePool`, de la [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/), para enrutar hacia workloads de inferencia de IA

{{< warning >}}
Istio configura agentgateway **únicamente** a través de los recursos de Gateway API enumerados anteriormente. Las
propias APIs de configuración de Istio —como `VirtualService`, `DestinationRule`, `Sidecar`, `AuthorizationPolicy`,
`PeerAuthentication`, `RequestAuthentication`, `Telemetry`, `WasmPlugin` y `EnvoyFilter`— **no**
se aplican a los proxies de agentgateway. Usa la Gateway API para expresar el enrutamiento y las políticas en su lugar.

El formato de configuración nativo propio de agentgateway y sus recursos personalizados tampoco son gestionados por
Istio; Istio programa el proxy únicamente a través de los recursos de Gateway API descritos en esta guía.
{{< /warning >}}

## Antes de empezar

{{< boilerplate gateway-api-install-crds >}}

### Instalar Istio con agentgateway habilitado

El soporte de agentgateway está controlado por la feature flag `PILOT_ENABLE_AGENTGATEWAY` en istiod, y está
deshabilitado de forma predeterminada. Instala Istio usando el perfil `ambient` con la flag habilitada. El perfil
`ambient` es necesario para que la `GatewayClass` de waypoint también se registre:

{{< text syntax=bash snip_id=install_istio >}}
$ istioctl install --set profile=ambient --set values.pilot.env.PILOT_ENABLE_AGENTGATEWAY=true -y
{{< /text >}}

{{< tip >}}
Al instalar con Helm, establece la misma flag en el chart de `istiod` con
`--set pilot.env.PILOT_ENABLE_AGENTGATEWAY=true`.
{{< /tip >}}

Confirma que ambos recursos `GatewayClass` de agentgateway están registrados:

{{< text syntax=bash snip_id=verify_gateway_classes >}}
$ kubectl get gatewayclass istio-agentgateway istio-agentgateway-waypoint
NAME                          CONTROLLER                                  ACCEPTED   AGE
istio-agentgateway            istio.io/agentgateway-controller            True       30s
istio-agentgateway-waypoint   istio.io/agentgateway-waypoint-controller   True       30s
{{< /text >}}

### Desplegar una aplicación de ejemplo

Despliega la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/), que se usa en los ejemplos de
esta guía:

{{< text syntax=bash snip_id=deploy_bookinfo >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

## Configurar agentgateway como un ingress gateway

Para usar agentgateway como un ingress gateway, crea un `Gateway` que haga referencia a la
clase `istio-agentgateway`. Istiod aprovisiona y gestiona automáticamente el despliegue de agentgateway
correspondiente.

{{< text syntax=bash snip_id=deploy_ingress_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio-agentgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

El campo `gatewayClassName: istio-agentgateway` es lo que selecciona el data plane de agentgateway en lugar
de Envoy. De forma predeterminada, Istio crea un servicio `LoadBalancer` para un gateway; la
anotación `networking.istio.io/service-type: ClusterIP` solicita en su lugar un servicio `ClusterIP` para
que el gateway se pueda alcanzar con `kubectl port-forward` en esta guía.

Adjunta un `HTTPRoute` para exponer el servicio `productpage` a través del gateway:

{{< text syntax=bash snip_id=deploy_ingress_route >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookinfo
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
    - path:
        type: Exact
        value: /productpage
    - path:
        type: PathPrefix
        value: /static
    - path:
        type: Exact
        value: /login
    - path:
        type: PathPrefix
        value: /api/v1/products
    backendRefs:
    - name: productpage
      port: 9080
EOF
{{< /text >}}

Confirma que el gateway se ha aprovisionado y está programado. La columna `CLASS` muestra la
clase de agentgateway:

{{< text syntax=bash snip_id=verify_ingress_gateway >}}
$ kubectl get gateway bookinfo-gateway
NAME               CLASS                ADDRESS                                      PROGRAMMED   AGE
bookinfo-gateway   istio-agentgateway   bookinfo-gateway.default.svc.cluster.local   True         30s
{{< /text >}}

Ahora puedes acceder a la aplicación a través del ingress gateway de agentgateway. Reenvía un puerto local al
servicio del gateway y abre `http://localhost:8080/productpage` en tu navegador:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway 8080:80
{{< /text >}}

## Configurar agentgateway como un waypoint

Un proxy waypoint agrega procesamiento de capa 7 (L7) a un conjunto de workloads en una mesh ambient. Para usar
agentgateway en este rol, despliega un `Gateway` que haga referencia a la clase
`istio-agentgateway-waypoint`.

Primero, confirma que el namespace está inscrito en el data plane ambient:

{{< text syntax=bash snip_id=label_ambient >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

{{< warning >}}
Los subcomandos `istioctl waypoint` (`apply`, `generate`, `list` y `status`) actualmente solo
admiten la clase `istio-waypoint` predeterminada basada en Envoy. Para desplegar un waypoint de agentgateway, aplica un
recurso `Gateway` directamente, como se muestra a continuación.
{{< /warning >}}

Despliega el waypoint. Como todos los waypoints, debe definir un único listener llamado `mesh` en el puerto
`15008` usando el protocolo `HBONE`; la única diferencia con un waypoint de Envoy es el
`gatewayClassName`:

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-waypoint
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-agentgateway-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Confirma que el waypoint está programado:

{{< text syntax=bash snip_id=verify_waypoint >}}
$ kubectl get gateway agentgateway-waypoint
NAME                    CLASS                         ADDRESS        PROGRAMMED   AGE
agentgateway-waypoint   istio-agentgateway-waypoint   10.96.15.112   True         30s
{{< /text >}}

Inscribe un servicio para usar el waypoint agregando la etiqueta `istio.io/use-waypoint` con el nombre
del waypoint. Por ejemplo, para enviar el tráfico destinado al servicio `reviews` a través del
waypoint de agentgateway:

{{< text syntax=bash snip_id=enroll_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint=agentgateway-waypoint
service/reviews labeled
{{< /text >}}

Las solicitudes de los workloads en la mesh ambient hacia el servicio `reviews` ahora se enrutan a través del
waypoint de agentgateway para el procesamiento de capa 7 (L7). Para obtener más información sobre cómo inscribir namespaces, servicios y
pods, y cómo los waypoints manejan los diferentes tipos de tráfico, consulta
[Configurar proxies waypoint](/es/docs/ambient/usage/waypoint/).

Para aplicar una política de enrutamiento de capa 7 (L7) en el waypoint, adjunta una ruta de la Gateway API al `Service` usando una
`parentRef` cuyo `kind` sea `Service`. Por ejemplo, el siguiente `HTTPRoute` envía el 90% del tráfico
del servicio `reviews` a `reviews-v1` y el 10% a `reviews-v2`:

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

## Limpieza

Elimina el ingress gateway y su ruta:

{{< text syntax=bash snip_id=cleanup_ingress >}}
$ kubectl delete httproute bookinfo
$ kubectl delete gateway bookinfo-gateway
{{< /text >}}

Elimina el waypoint y desinscribe el servicio `reviews`:

{{< text syntax=bash snip_id=cleanup_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint-
$ kubectl delete gateway agentgateway-waypoint
{{< /text >}}

Elimina la aplicación de ejemplo y la etiqueta ambient:

{{< text syntax=bash snip_id=cleanup_bookinfo >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

Desinstala Istio:

{{< text syntax=bash snip_id=uninstall_istio >}}
$ istioctl uninstall --purge -y
$ kubectl delete namespace istio-system
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
