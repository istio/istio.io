---
title: Anuncio de Istio 1.30.1
linktitle: 1.30.1
subtitle: Versión de Parche
description: Parche de Istio 1.30.1.
publishdate: 2026-06-04
release: 1.30.1
aliases:
    - /news/announcing-1.30.1
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.30.0 e Istio 1.30.1.

{{< relnote >}}

## Actualización de Seguridad

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (puntuación CVSS 7.5, Alta): Un atacante remoto no autenticado puede causar denegación de servicio agotando la memoria del proceso Envoy. Los bytes de la cabecera de cookie no se contabilizan completamente durante la validación del tamaño de la cabecera de solicitud, y los límites del bloque de cabecera HPACK se aplican sobre los bytes codificados sin un límite correspondiente en el tamaño total de cabecera decodificado, permitiendo a los atacantes desencadenar un consumo excesivo de memoria mediante solicitudes HTTP/2 especialmente diseñadas.

## Cambios

- **Actualizado** el addon Kiali a la versión `v2.26.0`.

- **Añadido** soporte para excluir la configuración de política de Istio cuando la
  anotación `istio.io/ignore-policy-attachment` está establecida en `"true"` en un objeto
  `BackendTLSPolicy` o `XBackendTrafficPolicy`. Esto permite a los usuarios
  evitar que políticas específicas sean traducidas a configuración de Istio
  cuando la política está destinada a un controlador de gateway diferente a Istio.
  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **Añadida** una verificación de inicialización que comprueba que el binario `nft` incluido
  soporta la salida JSON. El backend nativo de nftables requiere JSON para leer
  la configuración durante la eliminación de pods. En hosts cuyo binario `nft` no
  soporta JSON, esas llamadas fallan con `Error: JSON support not compiled-in` en
  cada eliminación, y el agente CNI reintenta indefinidamente. La nueva verificación detecta
  este error al inicio y recurre al backend iptables.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Añadida** la comprobación `IST0176` de `istioctl analyze` que marca los CRDs de la Gateway API instalados con una
  versión por debajo de la mínima requerida por la versión actual de Istio. Los recursos respaldados por dichos
  CRDs son filtrados silenciosamente por istiod, lo que anteriormente dificultaba descubrir la rotura del TLS
  passthrough al actualizar a Istio 1.30 con CRDs de la Gateway API desactualizados.

- **Corregida** la resolución de conflictos de `BackendTLSPolicy` en la Gateway API.
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **Corregido** un problema donde los listeners HTTPS definidos mediante `ListenerSet` no podían entregar certificados TLS cuando el `Gateway` padre usaba despliegue manual.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Corregido** un problema donde los filtros de `HTTPRoute` y `GRPCRoute` con valores de cabecera inválidos se descartaban silenciosamente de la configuración de Envoy en lugar de reportar un estado de filtro inválido.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Corregido** un problema donde ambient multi-red no enrutaba al waypoint
  cuando el ingreso en una red llamaba a un servicio en una red diferente, incluso
  cuando el `Service` estaba configurado con `istio.io/ingress-use-waypoint`.

- **Corregido** un problema donde el balanceo de carga `consistentHash` en `DestinationRule` no enviaba tráfico
  a nuevos endpoints tras el escalado, debido a una regresión de Envoy (`envoyproxy/envoy#45212`) donde el
  anillo `RING_HASH` no se reconstruía ante cambios de endpoints durante actualizaciones por lotes.
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **Corregido** un pánico fatal de `concurrent map writes` en el agente istio-cni cuando
  dos pods se añadían al mesh ambient en el mismo nodo al mismo tiempo.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Corregido** un error del modo ambient donde un único `Service` que combinaba `publishNotReadyAddresses: true` con una distribución de tráfico `PreferSameZone` o `PreferSameNode` causaba que ztunnel recibiera `healthPolicy: AllowAll` para todos los demás `Services` que usaban el mismo preset de distribución de tráfico, lo que resultaba en que el tráfico se enrutara a endpoints no listos en todo el clúster.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **Corregido** un problema donde pilot generaba configuración para agentgateway ignorando
  los recursos `ListenerSet` y las rutas adjuntas a ellos. Pilot ahora incluye correctamente
  los recursos `ListenerSet` en la configuración de agentgateway, permitiendo que agentgateway en Istio
  gestione los recursos `ListenerSet` correctamente.

- **Corregido** el reporte de estado de `ListenerSet` cuando `ListenerSet` no está permitido por el recurso `Gateway` padre
  para agentgateway. Cuando `ListenerSet` no está permitido por el `Gateway` padre,
  el estado de la condición `Accepted` ahora se reporta correctamente como `False`. Además, dado
  que la característica `ListenerSet` no es experimental a partir de la Gateway API `v1.5.0`, ya no
  está protegida por el flag de característica `PILOT_ENABLE_ALPHA_GATEWAY_API`.

- **Corregido** el proveedor SDS externo para gateways para usar el nombre de credencial (después de eliminar el prefijo `sds://`)
  como nombre del recurso SDS en lugar del nombre del proveedor. Esto permite que múltiples gateways que usan
  el mismo proveedor SDS soliciten diferentes certificados. Para TLS mutuo, el nombre del recurso del certificado CA
  se deriva correctamente como `<credential-name>-cacert`. Cuando no se configura ni un socket UDS ni un proveedor de extensión SDS,
  el gateway ahora recurre a obtener certificados a través de ADS (Kubernetes `Secrets`)
  en lugar de fallar silenciosamente.
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **Corregido** un deadlock en el `ClusterStore` multiclúster donde `AllReady` podía adquirir recursivamente el `RWMutex` del almacén para lectura a través de `triggerRecomputeOnSync` -> `GetByID` mientras un escritor esperaba, bloqueando lecturas y escrituras adicionales contra el almacén.
