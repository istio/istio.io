---
title: Anuncio de Istio 1.28.2
linktitle: 1.28.2
subtitle: Versión de Parche
description: Parche de Istio 1.28.2.
publishdate: 2025-12-22
release: 1.28.2
aliases:
    - /news/announcing-1.28.2
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.28.1 e Istio 1.28.2.

{{< relnote >}}

## Actualización de seguridad

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f) (CVSS score 5.3, Moderate): El uso después de liberar puede hacer que Envoy falle debido a DNS con mal funcionamiento o comprometido. Se trata de una vulnerabilidad de heap use-after-free en la biblioteca c-ares que puede ser explotada por un atacante que controle la infraestructura DNS local para causar una Denegación de Servicio (DoS) en Envoy.

## Cambios

- **Corregida** una condición de carrera poco frecuente donde eliminar un `ServiceEntry` que comparte un nombre de host con otro `ServiceEntry` en el mismo namespace ocasionalmente causaba que los clientes ambient perdieran la capacidad de enviar tráfico a ese nombre de host hasta que istiod se reiniciara.

- **Corregidos** los casos de uso donde actualizar desde el backend de iptables al backend de nftables en ambient creaba reglas iptables obsoletas en la red. El código ahora continúa usando iptables en el nodo hasta que se reinicia.
  ([Issue #58353](https://github.com/istio/istio/issues/58353))

- **Corregida** la creación de la tabla de nombres DNS para servicios headless donde las entradas de pods no tenían en cuenta que los pods podían tener múltiples IPs.
  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **Corregida** la anotación `sidecar.istio.io/statsEvictionInterval` con valores de 60 segundos o más que causaba fallos en el inicio del sidecar `istio-proxy`.
  ([Issue #58500](https://github.com/istio/istio/issues/58500))

- **Corregido** un problema donde los proxies Envoy que se conectaban a los proxies waypoint obtenían en casos raros actualizaciones XDS innecesarias o perdían algunas actualizaciones por completo.
