---
title: ¿Cómo configurar el tiempo de vida de los certificados de Istio?
weight: 70
---

Para los workloads que se ejecutan en Kubernetes, el tiempo de vida de sus certificados de Istio es, de forma predeterminada, de 24 horas.

Esta configuración se puede anular personalizando el campo `proxyMetadata` de la [configuración del proxy](/es/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig). Por ejemplo:

{{< text yaml >}}
proxyMetadata:
  SECRET_TTL: 48h
{{< /text >}}

{{< tip >}}
No se aceptarán valores superiores a 90 días.
{{< /tip >}}
