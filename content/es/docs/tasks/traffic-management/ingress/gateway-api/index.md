---
title: Kubernetes Gateway API
description: Describe cómo configurar el Kubernetes Gateway API con Istio.
weight: 50
aliases:
    - /docs/tasks/traffic-management/ingress/service-apis/
    - /latest/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

Además de su propia API de gestión de tráfico,
{{< boilerplate gateway-api-future >}}
Este documento describe las diferencias entre las APIs de Istio y Kubernetes y proporciona un ejemplo simple
que te muestra cómo configurar Istio para exponer un servicio fuera del clúster de service mesh usando el Gateway API.
Ten en cuenta que estas APIs son una evolución desarrollada activamente de las APIs de [Servicio](https://kubernetes.io/docs/concepts/services-networking/service/)
e [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) de Kubernetes.

{{< tip >}}
Muchos de los documentos de gestión de tráfico de Istio incluyen instrucciones para usar tanto la API de Istio como la de Kubernetes
(consulta la [tarea de controlar tráfico de ingreso](/es/docs/tasks/traffic-management/ingress/ingress-control), por ejemplo).
Puedes usar el Gateway API, desde el principio, siguiendo las [instrucciones de comenzar](/es/docs/setup/getting-started/).
{{< /tip >}}

## Configuración

1. Las APIs de Gateway no vienen instaladas por defecto en la mayoría de los clústeres de Kubernetes. Instala los CRDs del Gateway API si no están presentes:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1. Instala Istio usando el perfil `minimal`:

    {{< text bash >}}
    $ istioctl install --set profile=minimal -y
    {{< /text >}}

## Diferencias de las APIs de Istio

Las APIs de Gateway comparten muchas similitudes con las APIs de Istio como Gateway y VirtualService.
El recurso principal comparte el mismo nombre, `Gateway`, y los recursos sirven objetivos similares.

Las nuevas APIs de Gateway buscan incorporar las lecciones de varias implementaciones de ingress de Kubernetes, incluyendo Istio,
para crear una API estandarizada neutral de proveedores. Estas APIs generalmente sirven los mismos propósitos que las APIs de Gateway y VirtualService,
con algunas diferencias clave:

* En las APIs de Istio, un `Gateway` *configura* un Deployment/Service de gateway existente que [ha sido desplegado](/es/docs/setup/additional-setup/gateway/).
  En las APIs de Gateway, el recurso `Gateway` tanto *configura como despliega* un gateway.
  Consulta [Métodos de despliegue](#métodos-de-despliegue) para más información.
* En el `VirtualService` de Istio, todos los protocolos se configuran en un solo recurso.
  En las APIs de Gateway, cada tipo de protocolo tiene su propio recurso, como `HTTPRoute` y `TCPRoute`.
* Aunque las APIs de Gateway ofrecen una gran funcionalidad de enrutamiento, no cubren aún el 100% de la funcionalidad de Istio.
  El trabajo continúa para extender la API para cubrir estos casos de uso, así como para utilizar las APIs [extensibilidad](https://gateway-api.sigs.k8s.io/#gateway-api-concepts)
  para exponer mejor la funcionalidad de Istio.

## Configuración de un Gateway

Consulta la [documentación de la API de Gateway](https://gateway-api.sigs.k8s.io/) para información sobre las APIs.

En este ejemplo, desplegaremos una aplicación simple y la expondremos externamente usando un `Gateway`.

1. Primero, despliega la aplicación de prueba `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Despliega la configuración del Gateway API que incluye una sola ruta expuesta (es decir, `/get`):

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-ingress
    spec:
      gatewayClassName: istio
      listeners:
      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  Establece la variable de entorno Ingress Host:

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

1.  Accede al servicio `httpbin` usando _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {{< /text >}}

    Nota el uso del flag `-H` para establecer el encabezado HTTP _Host_ a
    "httpbin.example.com". Esto es necesario porque la regla `HTTPRoute` está configurada para manejar "httpbin.example.com",
    pero en tu entorno de prueba no tienes un enlace DNS para ese host y simplemente envías tu solicitud al IP de ingress.

1.  Accede a cualquier otro URL que no haya sido expuesto explícitamente. Deberías ver un error HTTP 404:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

1.  Actualiza la regla de ruta para exponer `/headers` y añade un encabezado a la solicitud:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        - path:
            type: PathPrefix
            value: /headers
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  Accede a `/headers` de nuevo y observa que el encabezado `My-Added-Header` ha sido añadido a la solicitud:

    {{< text bash >}}
    $ curl -s -HHost:httpbin.example.com "http://$INGRESS_HOST/headers" | jq '.headers["My-Added-Header"][0]'
    ...
    "added-value"
    ...
    {{< /text >}}

## Métodos de despliegue

En el ejemplo anterior, no necesitaste instalar un gateway de ingress `Deployment` antes de configurar un Gateway.
En la configuración por defecto, un gateway `Deployment` y `Service` se provisionan automáticamente basándose en la configuración del `Gateway`.
Para casos de uso avanzados, el despliegue manual aún está permitido.

### Despliegue automático

Por defecto, cada `Gateway` provisionará automáticamente un `Service` y un `Deployment`.
Estos se nombrarán `<Nombre-Gateway>-<Nombre-GatewayClass>` (con la excepción del `GatewayClass` `istio-waypoint`, que no añade un sufijo).
Estas configuraciones se actualizarán automáticamente si el `Gateway` cambia (por ejemplo, si se añade un nuevo puerto).

Estos recursos pueden ser personalizados usando el campo `infrastructure`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  infrastructure:
    annotations:
      some-key: some-value
    labels:
      key: value
    parametersRef:
      group: ""
      kind: ConfigMap
      name: gw-options
  gatewayClassName: istio
{{< /text >}}

Los pares clave-valor bajo `labels` y `annotations` se copiarán en los recursos generados.
El `parametersRef` puede ser usado para personalizar completamente los recursos generados.
Este debe referenciar un `ConfigMap` en el mismo namespace que el `Gateway`.

Un ejemplo de configuración:

{{< text yaml >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: gw-options
data:
  horizontalPodAutoscaler: |
    spec:
      minReplicas: 2
      maxReplicas: 2

  deployment: |
    metadata:
      annotations:
      additional-annotation: some-value
    spec:
      replicas: 4
      template:
        spec:
          containers:
          - name: istio-proxy
            resources:
              requests:
                cpu: 1234m

  service: |
    spec:
      ports:
      - "\$patch": delete
        port: 15021
{{< /text >}}

Estas configuraciones se superpondrán en los recursos generados usando una estrategia de [Strategic Merge Patch](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-api-machinery/strategic-merge-patch.md)
Las siguientes claves son válidas:
* `service`
* `deployment`
* `serviceAccount`
* `horizontalPodAutoscaler`
* `podDisruptionBudget`

{{< tip >}}
Un `HorizontalPodAutoscaler` y un `PodDisruptionBudget` no se crean por defecto.
Sin embargo, si el campo correspondiente está presente en la personalización, se crearán.
{{< /tip >}}

#### Configuración por defecto de GatewayClass

Las configuraciones por defecto para todos los `Gateway`s pueden ser configuradas para cada `GatewayClass`.
Esto se hace con un `ConfigMap` con la etiqueta `gateway.istio.io/defaults-for-class: <nombre-gateway-class>`.
Este `ConfigMap` debe estar en el [namespace raíz](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-root_namespace) (generalmente, `istio-system`).
Solo se permite un `ConfigMap` por `GatewayClass`.
Este `ConfigMap` tiene el mismo formato que el `ConfigMap` para un `Gateway`.

La personalización puede estar presente tanto en un `GatewayClass` como en un `Gateway`.
Si ambos están presentes, la personalización del `Gateway` se aplica después de la personalización del `GatewayClass`.

Este `ConfigMap` también puede ser creado en el momento de la instalación. Por ejemplo:

{{< text yaml >}}
kind: IstioOperator
spec:
  values:
    gatewayClasses:
      istio:
        deployment:
          spec:
            replicas: 2
{{< /text >}}

#### Asociación de recursos y escalado

Los recursos pueden ser *asociados* a un `Gateway` para personalizarlo.
Sin embargo, la mayoría de los recursos de Kubernetes no soportan actualmente la asociación directa a un `Gateway`, pero pueden ser asociados al `Deployment` y `Service` generado correspondiente.
Esto es fácil de hacer porque [los recursos están generados con etiquetas bien conocidas](https://gateway-api.sigs.k8s.io/geps/gep-1762/#resource-attachment) (`gateway.networking.k8s.io/gateway-name: <nombre-gateway>`) y nombres:

* Gateway: `<nombre-gateway>-<nombre-gateway-class>`
* Waypoint: `<nombre-gateway>`

Por ejemplo, para desplegar un `Gateway` con un `HorizontalPodAutoscaler` y un `PodDisruptionBudget`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway
spec:
  # Coincide con el Deployment generado por referencia
  # Nota: No use `kind: Gateway`.
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gateway-istio
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: gateway
spec:
  minAvailable: 1
  selector:
    # Coincide con el Deployment generado por etiqueta
    matchLabels:
      gateway.networking.k8s.io/gateway-name: gateway
{{< /text >}}

### Despliegue manual

Si no quieres tener un despliegue automático, un `Deployment` y un `Service` pueden ser [configurados manualmente](/es/docs/setup/additional-setup/gateway/).

Cuando esta opción se realiza, necesitarás enlazar manualmente el `Gateway` al `Service`, así como mantener la configuración de sus puertos sincronizada.

Para soportar la asociación de políticas, por ejemplo, cuando estás usando el campo [`targetRef`](/es/docs/reference/config/type/workload-selector/#PolicyTargetReference) en una AuthorizationPolicy, también necesitarás referenciar el nombre de tu `Gateway` añadiendo la siguiente etiqueta a tu pod de gateway: `gateway.networking.k8s.io/gateway-name: <nombre-gateway>`.

Para enlazar un `Gateway` a un `Service`, configura el campo `addresses` para apuntar a un **único** `Hostname`.

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
...
{{< /text >}}

## Tráfico de Mesh

El Gateway API también puede ser usado para configurar el tráfico de mesh.
Esto se hace configurando el `parentRef` para apuntar a un servicio, en lugar de un gateway.

Por ejemplo, para añadir un encabezado a todas las llamadas a un servicio en clúster `example`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: example
  rules:
  - filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: my-added-header
          value: added-value
    backendRefs:
    - name: example
      port: 80
{{< /text >}}

Más detalles y ejemplos pueden ser encontrados en otras [tareas de gestión de tráfico](/es/docs/tasks/traffic-management/).

## Limpieza

1. Elimina la muestra `httpbin` y el gateway:

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete httproute http
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ kubectl delete ns istio-ingress
    {{< /text >}}

1. Desinstala Istio:

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    {{< /text >}}

1. Elimina los CRDs del Gateway API si ya no son necesarios:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
