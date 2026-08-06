---
title: ISTIO-SECURITY-2026-002
subtitle: Security Bulletin
description: Ataque Man-in-the-Middle a través de VirtualService.
cves: []
cvss: "5.9"
vector: "AV:N/AC:L/PR:H/UI:R/S:C/C:L/I:L/A:L"
releases: ["All releases since the introduction of the mesh gateway option in the `VirtualService` resource"]
publishdate: 2026-03-21
skip_seealso: true
---

{{< security_bulletin >}}

El Comité de Seguridad de Istio desea abordar un posible escenario de ataque Man-in-the-Middle en el que un `VirtualService` puede redirigir o interceptar el tráfico dentro del service mesh. Solo afecta a entornos multi-tenant basados en namespaces.

Este ataque permite que un atacante con permiso de `VirtualService` en un namespace redirija el tráfico desde cualquier Pod en el service mesh de Istio a un servicio controlado por el atacante. El escenario de ataque abusa de la capacidad de establecer nombres de host arbitrarios en el campo `spec.hosts.[]` del recurso `VirtualService` cuando se establece el gateway `mesh`. Un atacante puede interceptar, redirigir y descartar el tráfico comunicado entre servicios. Esto afecta al tráfico hacia otros servicios en el mesh y hacia servicios externos. Sin embargo, el atacante no puede eludir las [Políticas de Autorización](/docs/reference/config/security/authorization-policy/) ni la autenticación TLS mutua configurada en el servicio de destino.

Ten en cuenta que los problemas incluso se extienden más allá del alcance del clúster en un [_despliegue de "mesh único con múltiples clústeres"_](/docs/ops/deployment/deployment-models/#multiple-clusters).

Los mantenedores de Istio consideran que este problema es un comportamiento esperado en Istio. Varios de sus recursos, como `VirtualService`, `DestinationRule` y `ServiceEntry`, modifican el tráfico hacia un nombre de host particular en todo el mesh, y aunque estos recursos están en un namespace, afectan los patrones de tráfico del mesh (dentro de un clúster determinado). Este es un compromiso intencional de experiencia de usuario para evitar controles de administración tediosos para cada nombre de host y namespace. En contraste con la más reciente [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/), estos CRDs fueron creados y efectivamente estabilizados antes de que el RBAC basado en namespaces llegara a Kubernetes, y los cambios romperían la funcionalidad existente.

Por lo tanto, los operadores que ejecutan Istio en configuraciones de multi-tenancy basadas en namespaces u operan un mesh único a través de múltiples clústeres deben aplicar salvaguardas adicionales para mantener un aislamiento sólido. Sin estos controles, puede ocurrir una manipulación del tráfico no intencional entre namespaces en el nivel del data plane.

La mitigación recomendada es migrar a la Gateway API más reciente en esas configuraciones. Cuando tales cambios y restricciones no son viables en configuraciones heredadas, se deben aplicar [mayor endurecimiento y restricciones](/blog/2026/security-considerations-on-namespace-based-multi-tenancy/#mitigation-and-best-practices) para reducir el impacto de estas debilidades.

Se pueden encontrar más detalles sobre el problema y la mitigación en la [publicación del blog](/blog/2026/security-considerations-on-namespace-based-multi-tenancy/).

El Comité de Seguridad de Istio desea agradecer a Sven Nobis y Lorin Lehawany de ERNW Enno Rey Netzwerke GmbH por revelar este problema.
