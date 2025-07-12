---
title: Solucionar problemas con waypoints
description: Cómo investigar problemas de enrutamiento a través de proxies de waypoint.
weight: 70
owner: istio/wg-networking-maintainers
test: no
---

Esta guía describe qué hacer si has inscrito un namespace, servicio o carga de trabajo en un proxy de waypoint, pero no estás viendo el comportamiento esperado.

## Problemas con el enrutamiento de tráfico o la política de seguridad

Para enviar algunas solicitudes al servicio `reviews` a través del servicio `productpage` desde el pod `curl`:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage
{{< /text >}}

Para enviar algunas solicitudes al pod `v2` de `reviews` desde el pod `curl`:

{{< text bash >}}
$ export REVIEWS_V2_POD_IP=$(kubectl get pod -l version=v2,app=reviews -o jsonpath='{.items[0].status.podIP}')
$ kubectl exec deploy/curl -- curl -s http://$REVIEWS_V2_POD_IP:9080/reviews/1
{{< /text >}}

Las solicitudes al servicio `reviews` deben ser aplicadas por el `reviews-svc-waypoint` para cualquier política L7.
Las solicitudes al pod `v2` de `reviews` deben ser aplicadas por el `reviews-v2-pod-waypoint` para cualquier política L7.

1.  Si tu configuración L7 no se aplica, ejecuta `istioctl analyze` primero para comprobar si tu configuración tiene un problema de validación.

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

1.  Determina qué waypoint está implementando la configuración L7 para tu servicio o pod.

    Si tu origen llama al destino usando el nombre de host o la IP del servicio, usa el comando `istioctl experimental ztunnel-config service` para confirmar que tu waypoint es utilizado por el servicio de destino. Siguiendo el ejemplo anterior, el servicio `reviews` debería usar el `reviews-svc-waypoint` mientras que todos los demás servicios en el namespace `default` deberían usar el waypoint del namespace `waypoint`.

    {{< text bash >}}
    $ istioctl ztunnel-config service
    NAMESPACE    SERVICE NAME            SERVICE VIP   WAYPOINT
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      details                 10.43.160.119 waypoint
    default      kubernetes              10.43.0.1     waypoint
    default      productpage             10.43.172.254 waypoint
    default      ratings                 10.43.71.236  waypoint
    default      reviews                 10.43.162.105 reviews-svc-waypoint
    ...
    {{< /text >}}

    Si tu origen llama al destino usando una IP de pod, usa el comando `istioctl ztunnel-config workload` para confirmar que tu waypoint es utilizado por el pod de destino. Siguiendo el ejemplo anterior, el pod `v2` de `reviews` debería usar el `reviews-v2-pod-waypoint` mientras que todos los demás pods en el namespace `default` no deberían tener ningún waypoint, porque por defecto [un waypoint solo maneja el tráfico dirigido a los servicios](/es/docs/ambient/usage/waypoint/#waypoint-traffic-types).

    {{< text bash >}}
    $ istioctl ztunnel-config workload
    NAMESPACE    POD NAME                                    IP         NODE                     WAYPOINT                PROTOCOL
    default      bookinfo-gateway-istio-7c57fc4647-wjqvm     10.42.2.8  k3d-k3s-default-server-0 None                    TCP
    default      details-v1-698d88b-wwsnv                    10.42.2.4  k3d-k3s-default-server-0 None                    HBONE
    default      productpage-v1-675fc69cf-fp65z              10.42.2.6  k3d-k3s-default-server-0 None                    HBONE
    default      ratings-v1-6484c4d9bb-crjtt                 10.42.0.4  k3d-k3s-default-agent-0  None                    HBONE
    default      reviews-svc-waypoint-c49f9f569-b492t        10.42.2.10 k3d-k3s-default-server-0 None                    TCP
    default      reviews-v1-5b5d6494f4-nrvfx                 10.42.2.5  k3d-k3s-default-server-0 None                    HBONE
    default      reviews-v2-5b667bcbf8-gj7nz                 10.42.0.5  k3d-k3s-default-agent-0  reviews-v2-pod-waypoint HBONE
    ...
    {{< /text >}}

    Si el valor de la columna de waypoint del pod no es correcto, verifica que tu pod esté etiquetado con `istio.io/use-waypoint` y que el valor de la etiqueta sea el nombre de un waypoint que pueda procesar
    el tráfico de la carga de trabajo. Por ejemplo, si tu pod `v2` de `reviews` usa un waypoint que solo puede procesar tráfico de servicio, no verás ningún waypoint utilizado por ese pod.
    Si la etiqueta `istio.io/use-waypoint` en tu pod parece correcta, verifica que el recurso de Gateway para tu waypoint esté etiquetado con un valor compatible para `istio.io/waypoint-for`. En el caso de un pod, los valores adecuados serían `all` o `workload`.

1.  Comprueba el estado del proxy del waypoint a través del comando `istioctl proxy-status`.

    {{< text bash >}}
    $ istioctl proxy-status
    NAME                                                CLUSTER        CDS         LDS         EDS          RDS          ECDS         ISTIOD                      VERSION
    bookinfo-gateway-istio-7c57fc4647-wjqvm.default     Kubernetes     SYNCED      SYNCED      SYNCED       SYNCED       NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-svc-waypoint-c49f9f569-b492t.default        Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-v2-pod-waypoint-7f5dbd597-7zzw7.default     Kubernetes     SYNCED      SYNCED      NOT SENT     NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    waypoint-6f7b665c89-6hppr.default                   Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    ...
    {{< /text >}}

1.  Habilita el [registro de acceso](/es/docs/tasks/observability/logs/access-log/) de Envoy y comprueba los registros del proxy del waypoint después de enviar algunas solicitudes:

    {{< text bash >}}
    $ kubectl logs deploy/waypoint
    {{< /text >}}

    Si no hay suficiente información, puedes habilitar los registros de depuración para el proxy del waypoint:

    {{< text bash >}}
    $ istioctl pc log deploy/waypoint --level debug
    {{< /text >}}

1.  Comprueba la configuración de envoy para el waypoint a través del comando `istioctl proxy-config`, que muestra toda la información relacionada con el waypoint, como clusteres, puntos finales, escuchas, rutas y secretos:

    {{< text bash >}}
    $ istioctl proxy-config all deploy/waypoint
    {{< /text >}}

Consulta la sección [inmersión profunda en la configuración de Envoy](/es/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration) para obtener más
información sobre cómo depurar Envoy, ya que los proxies de waypoint se basan en Envoy.
