---
title: Anuncio de Istio 1.29.4
linktitle: 1.29.4
subtitle: Versión de Parche
description: Parche de Istio 1.29.4.
publishdate: 2026-06-04
release: 1.29.4
aliases:
    - /news/announcing-1.29.4
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.29.3 e Istio 1.29.4.

{{< relnote >}}

## Actualización de seguridad

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (puntuación CVSS 7.5, Alta): Un atacante remoto no autenticado puede causar una denegación de servicio agotando la memoria en el proceso de Envoy. Los bytes de la cabecera Cookie no se contabilizan completamente durante la validación del tamaño de la cabecera de solicitud, y los límites de bloques de cabecera HPACK se aplican sobre bytes codificados sin un límite correspondiente al tamaño total de cabecera decodificada, lo que permite a un atacante desencadenar un consumo excesivo de memoria mediante solicitudes HTTP/2 especialmente diseñadas.

## Cambios

- **Añadida** una verificación de inicialización que comprueba si el binario `nft` incluido admite salida JSON. El backend nativo de nftables requiere JSON para leer la configuración durante la eliminación de pods. En hosts cuyo binario `nft` no admite JSON, esas llamadas fallan con `Error: JSON support not compiled-in` en cada eliminación, y el agente CNI reintenta indefinidamente. La nueva verificación detecta este error al inicio y vuelve al backend de iptables.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Corregido** un problema donde los listeners HTTPS definidos mediante `ListenerSet` no entregaban certificados TLS cuando el `Gateway` padre usaba despliegue manual.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Corregido** un problema donde los filtros de `HTTPRoute` y `GRPCRoute` con valores de cabecera no válidos se descartaban silenciosamente de la configuración de Envoy en lugar de informar un estado de filtro no válido.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Corregido** un problema donde el modo ambient en múltiples redes no enrutaba al waypoint cuando el ingress de una red llamaba a un servicio en una red diferente, incluso cuando el `Service` estaba configurado con `istio.io/ingress-use-waypoint`.

- **Corregido** un pánico fatal de `concurrent map writes` en el agente istio-cni cuando dos pods se añadían al mesh ambient en el mismo nodo al mismo tiempo.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Corregido** un error en el modo ambient donde un único `Service` que combinaba `publishNotReadyAddresses: true` con una distribución de tráfico `PreferSameZone` o `PreferSameNode` hacía que ztunnel recibiera `healthPolicy: AllowAll` para todos los demás `Service` que usaban el mismo ajuste preestablecido de distribución de tráfico, lo que llevaba a que el tráfico se enrutara a endpoints no listos en todo el clúster.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))
