---
title: Notas de Actualización de Istio 1.24
description: Cambios importantes a considerar al actualizar a Istio 1.24.0.
weight: 20
publishdate: 2024-11-07
---

Al actualizar de Istio 1.23.x a Istio 1.24.x, ten en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con Istio 1.23.x.
También se mencionan cambios que mantienen la compatibilidad hacia atrás pero introducen un nuevo comportamiento.
Solo se incluyen cambios cuyo nuevo comportamiento resultaría inesperado para un usuario de Istio 1.23.x.

## Perfiles de compatibilidad actualizados

Para dar soporte a la compatibilidad con versiones anteriores, Istio 1.24 introduce un nuevo [perfil de compatibilidad](/docs/setup/additional-setup/compatibility-versions/) 1.23 y actualiza sus otros perfiles para tener en cuenta los cambios de Istio 1.24.

Este perfil establece los siguientes valores:

{{< text yaml >}}
ENABLE_INBOUND_RETRY_POLICY: "false"
EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY: "false"
PREFER_DESTINATIONRULE_TLS_FOR_EXTERNAL_SERVICES: "false"
ENABLE_ENHANCED_DESTINATIONRULE_MERGE: "false"
PILOT_UNIFIED_SIDECAR_SCOPE: "false"
ENABLE_DEFERRED_STATS_CREATION: "false"
BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS: "false"
{{< /text >}}

Consulta las notas de cambios y actualización individuales para más información.

## Los CRDs de Istio se instalan mediante plantillas por defecto y pueden instalarse y actualizarse con `helm install istio-base`

Esto modifica la forma en que se actualizan los CRDs.
Anteriormente, la documentación recomendaba:

- Instalación: `helm install istio-base`
- Actualización: `kubectl apply -f manifests/charts/base/files/crd-all.gen.yaml` o similar.
- Desinstalación: `kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

Este cambio permite:

- Instalación: `helm install istio-base`
- Actualización: `helm upgrade istio-base`
- Desinstalación: `kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

Anteriormente esto solo funcionaba bajo ciertas condiciones y, al usar ciertos flags de instalación, podía generar CRDs no actualizables mediante Helm que requerían intervención manual.

Como consecuencia necesaria, las etiquetas de los CRDs cambian para ser coherentes con otros recursos instalados con Helm.

Si antes instalabas o actualizabas CRDs con `kubectl apply` y no con Helm, puedes seguir haciéndolo.

Si antes instalabas CRDs con `helm install istio-base` O `kubectl apply`, puedes empezar a actualizar los CRDs de Istio de forma segura con `helm upgrade istio-base` desde esta y todas las versiones posteriores, tras ejecutar los siguientes comandos de kubectl como migración única:

- `kubectl label $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "app.kubernetes.io/managed-by=Helm"`
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-name=istio-base"` (reemplaza con el nombre real del release Helm de `istio-base`)
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-namespace=istio-system"` (reemplaza con el namespace real de Istio)

Si lo deseas, las etiquetas heredadas se pueden generar estableciendo `base.enableCRDTemplates=false` durante `helm install base`, aunque esta opción se eliminará en una versión futura.

## El chart `istiod-remote` se reemplaza con el perfil `remote`

Nunca se ha documentado ni estabilizado oficialmente la instalación de clústeres de Istio con un control plane remoto/externo mediante Helm. Este cambio modifica cómo se instalan los clústeres que usan una instancia de Istio remota, en preparación para documentarlo.

El chart Helm `istiod-remote` se ha fusionado con el chart Helm regular `istio-discovery`.

Antes:
- `helm install istiod-remote istio/istiod-remote`

Con este cambio:
- `helm install helm install istiod istio/istiod --set profile=remote`

Nota que, según la nota de actualización anterior, la instalación del chart `istio-base` es ahora obligatoria tanto en clústeres locales como remotos.

## Cambios en el alcance de `Sidecar`

Al procesar servicios, Istio tiene diversas estrategias de resolución de conflictos.
Históricamente, estas han diferido sutilmente según si el usuario tiene definido un recurso `Sidecar` o no.
Esto se aplicaba incluso si el recurso `Sidecar` solo tenía `egress: "*/*"`, lo cual debería ser equivalente a no tenerlo definido.

En esta versión, el comportamiento de ambos casos se ha unificado:

*Múltiples servicios definidos con el mismo hostname*
Comportamiento anterior, sin `Sidecar`: preferir un `Service` de Kubernetes (en lugar de un `ServiceEntry`); de lo contrario, elegir uno arbitrariamente.
Comportamiento anterior, con `Sidecar`: preferir el Service del mismo namespace que el proxy; de lo contrario, elegir uno arbitrariamente.
Nuevo comportamiento: preferir el Service del mismo namespace que el proxy, luego el Service de Kubernetes (no ServiceEntry); de lo contrario, elegir uno arbitrariamente.

*Múltiples rutas de Gateway API definidas para el mismo servicio*
Comportamiento anterior, sin `Sidecar`: preferir el namespace local del proxy, para permitir overrides del consumidor.
Comportamiento anterior, con `Sidecar`: orden arbitrario.
Nuevo comportamiento: preferir el namespace local del proxy, para permitir overrides del consumidor.

El comportamiento anterior se puede mantener temporalmente estableciendo `PILOT_UNIFIED_SIDECAR_SCOPE=false`.

## Estandarización de los atributos de metadatos del peer

Las expresiones CEL en la API de telemetría deben usar los [atributos estándar de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes) en lugar de los atributos extendidos personalizados de Wasm.

Los metadatos del peer ahora se almacenan en `filter_state.downstream_peer` y `filter_state.upstream_peer` en lugar de `filter_state["wasm.downstream_peer"]` y `filter_state["wasm.upstream_peer"]`.
Los metadatos del nodo se almacenan en `xds.node` en lugar de `node`.
Los atributos Wasm deben estar completamente cualificados; por ejemplo, usa `filter_state["wasm.istio_responseClass"]` en lugar de `istio_responseClass`.

El operador de presencia se puede usar para expresiones compatibles hacia atrás en un escenario de proxies mixtos; por ejemplo, `has(filter_state.downstream_peer) ? filter_state.downstream_peer.namespace : filter_state["wasm.downstream_peer"].namespace` para leer el namespace del peer.

Los metadatos del peer usan codificación baggage con los siguientes atributos de campo:

- `namespace`
- `cluster`
- `service`
- `revision`
- `app`
- `version`
- `workload`
- `type` (por ejemplo, `"deployment"`)
- `name` (por ejemplo, `"pod-foo-12345"`)
