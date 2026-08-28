---
title: Anuncio de Istio 1.28.1
linktitle: 1.28.1
subtitle: Versión de Parche
description: Parche de Istio 1.28.1.
publishdate: 2025-12-03
release: 1.28.1
aliases:
    - /news/announcing-1.28.1
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.28.0 e Istio 1.28.1.

Esta versión implementa las actualizaciones de seguridad descritas en nuestra publicación del 3 de diciembre, [`ISTIO-SECURITY-2025-003`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Cambios

- **Añadido** soporte para múltiples `targetPorts` en un `InferencePool`. La posibilidad de tener más de un `targetPort` se añadió como parte de GIE v1.1.0.
  ([Issue #57638](https://github.com/istio/istio/issues/57638))

- **Corregidos** conflictos de estado en recursos Route cuando se instalan múltiples revisiones de Istio.
  ([Issue #57734](https://github.com/istio/istio/issues/57734))

- **Corregidos** los recursos `ServiceEntry` con nombres de host superpuestos dentro del mismo namespace, que causaban un comportamiento impredecible
en modo ambient.
  ([Issue #57291](https://github.com/istio/istio/issues/57291))

- **Corregido** un fallo en `istio-init` al usar nftables nativo con el modo TPROXY y tener una anotación `traffic.sidecar.istio.io/includeInboundPorts` vacía.
  ([Issue #58135](https://github.com/istio/istio/issues/58135))

- **Corregido** un problema donde el código de generación de EDS no consideraba el alcance del servicio y, como resultado, los endpoints de clústeres remotos que no deberían ser accesibles se incluían en la configuración del waypoint.
  ([Issue #58139](https://github.com/istio/istio/issues/58139))

- **Corregido** un problema donde, debido a un almacenamiento en caché incorrecto de EDS en pilot, el gateway E/W de ambient o los waypoints se configuraban con endpoints EDS inutilizables.
  ([Issue #58141](https://github.com/istio/istio/issues/58141))

- **Corregido** un problema donde los recursos de Secret de Envoy podían quedar bloqueados en estado `WARMING` cuando el mismo Secret de Kubernetes se referenciaba desde objetos Gateway de Istio usando tanto el formato `secret-name` como `namespace/secret-name`.
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

- **Corregido** un problema donde las reglas nftables de IPv6 se programaban cuando IPv6 estaba explícitamente desactivado en modo ambient.
  ([Issue #58249](https://github.com/istio/istio/issues/58249))

- **Corregida** la creación de la tabla de nombres DNS para servicios headless donde las entradas de pods no tenían en cuenta que los pods podían tener múltiples IPs.
  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **Corregido** un problema que causaba fallos en las conexiones ambient multi-red al usar un dominio de confianza personalizado.
  ([Issue #58427](https://github.com/istio/istio/issues/58427))

- **Corregido** un problema donde los servidores HTTPS procesados primero impedían que los servidores HTTP crearan rutas en el mismo puerto con diferentes direcciones de enlace.
  ([Issue #57706](https://github.com/istio/istio/issues/57706))

- **Corregido** un error que causaba que los recursos experimentales `XListenerSet` no pudieran acceder a los Secrets TLS.
