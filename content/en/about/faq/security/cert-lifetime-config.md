---
title: How to configure the lifetime for Istio certificates?
weight: 70
---

For the workloads running in Kubernetes, the lifetime of their Istio certificates is by default 24 hours.

This configuration may be overridden by customizing the `proxyMetadata` field of the [proxy configuration](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig). For example:

{{< text yaml >}}
proxyMetadata:
  SECRET_TTL: 48h
{{< /text >}}

{{< tip >}}
Values over 90 days will not be accepted.
{{< /tip >}}
