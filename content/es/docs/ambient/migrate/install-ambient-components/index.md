---
title: Instalar componentes ambient
description: Agrega ztunnel y actualiza el CNI para soportar el modo ambient junto a los sidecars existentes.
weight: 2
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/before-you-begin
next: /docs/ambient/migrate/migrate-policies
---

Este paso actualiza tu instalación de Istio para incluir los componentes del data plane ambient
(ztunnel y CNI actualizado) sin modificar los workloads con sidecar existentes.
Tus sidecars seguirán manejando el tráfico normalmente durante este paso.

{{< warning >}}
No elimines la inyección de sidecar ni agregues la etiqueta `istio.io/dataplane-mode=ambient` a ningún
namespace hasta el paso [Habilitar el modo ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /warning >}}

## Actualizar al perfil ambient

### Usando istioctl

Actualiza tu instalación de Istio existente para usar el perfil `ambient`. Esto agrega el
DaemonSet de ztunnel y actualiza el plugin CNI para soportar el modo ambient:

{{< text syntax=bash snip_id=none >}}
$ istioctl upgrade --set profile=ambient
{{< /text >}}

{{< tip >}}
Si instalaste Istio con un `IstioOperator` personalizado o con flags `--set`, puedes combinarlos
con el perfil ambient. Por ejemplo:
`istioctl upgrade --set profile=ambient --set values.pilot.resources.requests.cpu=500m`
{{< /tip >}}

### Usando Helm

Si instalaste Istio con Helm, actualiza cada componente para agregar el soporte ambient:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-base istio/base -n istio-system
$ helm upgrade istiod istio/istiod -n istio-system --set profile=ambient
$ helm upgrade istio-cni istio/cni -n istio-system --set profile=ambient
$ helm install ztunnel istio/ztunnel -n istio-system  # componente nuevo, no instalado anteriormente
{{< /text >}}

## Verificar los componentes ambient

Después de que la actualización se complete, verifica que ztunnel y el CNI actualizado estén en ejecución:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
{{< /text >}}

Deberías ver los pods del DaemonSet `ztunnel` ejecutándose en cada nodo, además de tus
pods existentes de Istiod y CNI:

{{< text syntax=plain snip_id=none >}}
NAME                                   READY   STATUS    RESTARTS   AGE
istio-cni-node-...                     1/1     Running   0          2m
istiod-...                             1/1     Running   0          2m
ztunnel-...                            1/1     Running   0          2m
{{< /text >}}

Confirma que ztunnel se está ejecutando como DaemonSet en todos los nodos:

{{< text syntax=bash snip_id=none >}}
$ kubectl get daemonset ztunnel -n istio-system
{{< /text >}}

## Habilitar el soporte HBONE en los sidecars existentes

Los proxies sidecar necesitan reiniciarse para obtener la nueva configuración `ISTIO_META_ENABLE_HBONE=true`
que el perfil ambient establece en `MeshConfig`. Esto permite que los sidecars
se comuniquen con los workloads en modo ambient usando el protocolo HBONE.

Reinicia cada namespace que tenga habilitada la inyección de sidecar, o reinicia tus workloads individuales según tu estrategia de despliegue. Por ejemplo, para reiniciar un namespace:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

Repite esto para cada namespace que contenga workloads con sidecar inyectado.

Para verificar que el soporte HBONE está activo en un pod reiniciado:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod <pod-name> -n <namespace> -o json | \
    jq '.spec.initContainers[] | select(.name=="istio-proxy") | .env[] | select(.name=="ISTIO_META_ENABLE_HBONE")'
{{< /text >}}

La salida debería mostrar:

{{< text syntax=json snip_id=none >}}
{
  "name": "ISTIO_META_ENABLE_HBONE",
  "value": "true"
}
{{< /text >}}

{{< tip >}}
Reiniciar pods en esta etapa no tiene impacto observable en el tráfico. HBONE solo se activa
cuando un destino es un workload en modo ambient, y aún no se han incorporado namespaces.
{{< /tip >}}

## Interoperabilidad entre sidecar y ambient durante la migración

Cuando un pod con sidecar inyectado se comunica con un workload que ya ha sido movido al
modo ambient, el sidecar usa el protocolo HBONE para tunelizar el tráfico directamente al
ztunnel del pod de destino.

La consecuencia práctica es que las políticas L7 del waypoint (como las reglas de `HTTPRoute` o
`AuthorizationPolicy` con `targetRefs`) **no se aplican** para el tráfico proveniente de workloads en modo
sidecar durante el período de migración. El sidecar aplica su propia lógica L7 antes de enviar,
pero el waypoint nunca enruta este tráfico. Esto significa que las políticas L7 no se aplicarán
dos veces porque el sidecar maneja sus propias decisiones de enrutamiento y el túnel HBONE
entrega el tráfico directamente al destino sin procesarlo nuevamente en el waypoint.

{{< warning >}}
Si usas una política de prevención de bypass del waypoint (una política DENY que rechaza el tráfico que no
proviene del waypoint), esa política también rechazará el tráfico de los workloads en modo sidecar,
ya que estos omiten el waypoint. Consulta
[Prevenir el bypass del waypoint](/docs/ambient/migrate/migrate-policies/#prevent-waypoint-bypass)
para obtener orientación sobre cómo manejar esto durante una migración incremental.
{{< /warning >}}

## Desplegar waypoint proxies (opcional)

{{< tip >}}
Omite esta sección si solo necesitas mTLS L4 y políticas de autorización. Los waypoints solo son
necesarios para características L7. Consulta [Migrar políticas](/docs/ambient/migrate/migrate-policies/)
para determinar si los necesitas.
{{< /tip >}}

Para los namespaces que requieren características L7, despliega un waypoint proxy ahora. El waypoint estará
configurado pero **aún no activado**; el tráfico seguirá fluyendo a través de los sidecars.

Despliega un waypoint con alcance de namespace usando `istioctl`:

{{< text syntax=bash snip_id=none >}}
$ istioctl waypoint apply -n <namespace>
{{< /text >}}

Verifica que el pod del waypoint esté en ejecución:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
$ kubectl get pods -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller
{{< /text >}}

{{< warning >}}
**No** agregues la etiqueta `istio.io/use-waypoint` a ningún namespace o servicio todavía.
Activar waypoints antes de que se eliminen los sidecars puede hacer que el tráfico se procese dos veces.
Espera hasta el paso [Habilitar el modo ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /warning >}}

Para más detalles sobre las opciones de configuración de waypoints (a nivel de servicio, workload o
waypoints entre namespaces), consulta [Usar waypoint proxies](/docs/ambient/usage/waypoint/).

## Próximos pasos

Continúa con [Migrar políticas](/docs/ambient/migrate/migrate-policies/) para actualizar tus políticas de tráfico y
autorización para el modo ambient.

Si no tienes recursos `VirtualService` o `DestinationRule`, y tus recursos `AuthorizationPolicy`
solo usan reglas L4 (sin coincidencia de método/path/header HTTP), omite esa página y ve
directamente a [Habilitar el modo ambient](/docs/ambient/migrate/enable-ambient-mode/).
