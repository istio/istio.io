---
title: Gateways de salida
description: Controla y observa el tráfico que sale de la mesh usando un waypoint como gateway de salida.
weight: 45
keywords: [ambient,egress,gateway,serviceentry,waypoint]
owner: istio/wg-networking-maintainers
test: yes
---

Un gateway de salida es un proxy dedicado por el que debe pasar todo el tráfico saliente hacia servicios externos. Proporciona un único punto de salida verificable para el tráfico que abandona la mesh, donde puedes aplicar políticas de autorización, habilitar la observabilidad y originar TLS.

En el {{< gloss "sidecar" >}}modo sidecar{{< /gloss >}}, configurar un gateway de salida para un único host requiere coordinar cinco objetos distintos: un `ServiceEntry`, un `Gateway`, dos recursos `HTTPRoute` (uno para dirigir el tráfico de la mesh hacia el gateway y otro para reenviar el tráfico desde el gateway hasta el destino) y un `DestinationRule`. Cada nuevo host externo repite la mayor parte de ese trabajo.

En el {{< gloss "ambient" >}}modo ambient{{< /gloss >}}, un {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} actúa de forma natural como gateway de salida. ztunnel enruta automáticamente el tráfico al waypoint de un servicio antes de reenviarlo al destino. Si colocas un [`ServiceEntry`](/es/docs/reference/config/networking/service-entry/) en un namespace inscrito para usar un waypoint, todo el tráfico de la mesh hacia ese host externo pasa por el waypoint automáticamente, sin necesidad de reglas de enrutamiento adicionales.

## Antes de empezar

- Instala Istio con el [modo ambient habilitado](/es/docs/ambient/install/).
- Despliega un workload que sirva como origen del tráfico. El ejemplo [curl]({{< github_tree >}}/samples/curl) funciona bien:

    {{< text syntax=bash snip_id=deploy_curl >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

- Etiqueta el namespace del workload para el modo ambient para que ztunnel intercepte su tráfico:

    {{< text syntax=bash snip_id=label_default_ambient >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    {{< /text >}}

## Configurar el namespace de salida

Crea un namespace dedicado para los recursos de salida. Aislar las definiciones de servicios externos y sus políticas de los namespaces de las aplicaciones simplifica la administración y reduce el impacto de posibles errores de configuración.

{{< text syntax=bash snip_id=create_egress_ns >}}
$ kubectl create namespace istio-egress
$ kubectl label namespace istio-egress istio.io/dataplane-mode=ambient
{{< /text >}}

## Desplegar el waypoint de salida

Despliega un waypoint proxy en el namespace de salida e inscribe el namespace para que lo use. El flag `--enroll-namespace` agrega la etiqueta `istio.io/use-waypoint` al namespace, de modo que todos los servicios definidos allí, incluidos los respaldados por un `ServiceEntry`, se enrutarán a través del waypoint.

{{< boilerplate gateway-api-install-crds >}}

{{< text syntax=bash snip_id=apply_egress_waypoint >}}
$ istioctl waypoint apply --for service --enroll-namespace --namespace istio-egress
✅ waypoint istio-egress/waypoint applied
✅ namespace istio-egress labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Confirma que el waypoint está listo:

{{< text syntax=bash snip_id=wait_egress_waypoint >}}
$ istioctl waypoint list -n istio-egress
NAME       REVISION  TRAFFIC TYPE  PROGRAMMED
waypoint   default   service       True
{{< /text >}}

## Definir un servicio externo

Crea un `ServiceEntry` en el namespace de salida para representar el host externo. Como el namespace está inscrito para usar el waypoint, ztunnel enruta automáticamente a través del waypoint todo el tráfico de la mesh hacia ese host. El `ServiceEntry` es visible en todo el clúster por defecto (`exportTo: *`), por lo que el ztunnel de cada nodo resuelve `httpbin.org` al waypoint de `istio-egress` sin ninguna configuración adicional.

{{< text syntax=bash snip_id=apply_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

## Verificar que el tráfico pasa por el waypoint de salida

Envía una request desde el pod de curl al host externo y confirma que llega al destino:

{{< text syntax=bash snip_id=verify_egress_traffic >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

Para confirmar que el tráfico atravesó el waypoint, revisa las estadísticas de Envoy del waypoint:

{{< text syntax=bash snip_id=check_waypoint_logs >}}
$ kubectl exec -n istio-egress deploy/waypoint -c istio-proxy -- pilot-agent request GET stats | grep upstream_rq_total
{{< /text >}}

Un valor distinto de cero en `upstream_rq_total` (el número de solicitudes que el waypoint reenvió upstream) confirma que el waypoint está actuando como gateway de salida.

{{< warning >}}
Inscribir un namespace hace que el tráfico pase por el waypoint, pero no impide rutas directas si el waypoint no está disponible. Si el control de salida es un requisito de seguridad, agrega una `AuthorizationPolicy` que solo permita la identidad del waypoint, aplicada en L4 por ztunnel. Consulta [Requerir que el tráfico atraviese el waypoint](/es/docs/ambient/usage/waypoint/#require-waypoint).
{{< /warning >}}

## Aplicar políticas de acceso

Como el tráfico pasa por el waypoint, puedes adjuntar políticas de autorización de capa 7 directamente al `ServiceEntry`. La siguiente política permite que cualquier origen realice solicitudes `GET` únicamente a `/get`:

{{< text syntax=bash snip_id=apply_authz_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  targetRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-org
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get"]
EOF
{{< /text >}}

Después de aplicar la política, verifica que las solicitudes permitidas tienen éxito:

{{< text syntax=bash snip_id=verify_allowed_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

Confirma que una solicitud no permitida es rechazada:

{{< text syntax=bash snip_id=verify_denied_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" -X POST http://httpbin.org/post
403
{{< /text >}}

## Originar TLS en el gateway de salida

Los pods de la aplicación pueden enviar HTTP en texto plano al gateway de salida; el gateway lo actualiza a HTTPS antes de reenviarlo al host externo. Esto concentra la gestión de credenciales TLS en el gateway y evita distribuir certificados a cada pod de la aplicación.

Actualiza el `ServiceEntry` para mapear el puerto de texto plano al puerto TLS y agrega un `DestinationRule` para originar la conexión TLS:

{{< text syntax=bash snip_id=apply_tls_origination >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: httpbin-org-tls
  namespace: istio-egress
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
EOF
{{< /text >}}

Verifica que la aplicación sigue recibiendo una respuesta, ahora enviada sobre HTTPS por el gateway:

{{< text syntax=bash snip_id=verify_tls_origination >}}
$ kubectl exec deploy/curl -- curl -s http://httpbin.org/get | head -5
{{< /text >}}

{{< tip >}}
ztunnel proporciona mTLS automáticamente entre el pod de la aplicación y el waypoint de salida. El `DestinationRule` de este ejemplo solo controla el TLS saliente desde el waypoint hacia el host externo.
{{< /tip >}}

## Agregar un servicio externo sin originación de TLS

Para exponer hosts externos adicionales a través del mismo waypoint de salida, crea otro `ServiceEntry` en el mismo namespace. No se necesita configuración adicional del waypoint porque el namespace ya está inscrito:

{{< text syntax=bash snip_id=apply_second_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: example-com
  namespace: istio-egress
spec:
  hosts:
  - example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Verifica que el tráfico hacia el nuevo host también se enruta a través del waypoint:

{{< text syntax=bash snip_id=verify_second_serviceentry >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://example.com
200
{{< /text >}}

Cada `ServiceEntry` del namespace se enruta automáticamente a través del waypoint y puede tener su propia `AuthorizationPolicy`.

## Limpieza

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete namespace istio-egress
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

## Ver también

- [Configurar proxies de waypoint](/es/docs/ambient/usage/waypoint/): despliegue e inscripción general de waypoints
- [Requerir que el tráfico atraviese el waypoint](/es/docs/ambient/usage/waypoint/#require-waypoint): fuerza que el tráfico de salida no pueda evitar el waypoint
- [Visibilidad de ServiceEntry](/docs/ambient/usage/serviceentry-visibility/): controla qué namespaces pueden descubrir cada `ServiceEntry`
- [Usar características de capa 7](/es/docs/ambient/usage/l7-features/): lista completa de políticas y rutas L7 disponibles en un waypoint
- [Gateways de salida (modo sidecar)](/es/docs/tasks/traffic-management/egress/egress-gateway/): la configuración equivalente en modo sidecar para comparar
