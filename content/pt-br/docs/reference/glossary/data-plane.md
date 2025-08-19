---
title: Data Plane
test: n/a
---

The data plane is the part of the mesh that directly handles and routes traffic between workload instances.

In {{< gloss >}}sidecar{{< /gloss >}} mode, Istio's data plane uses [Envoy](/docs/reference/glossary/#envoy) proxies deployed as sidecars to mediate and control all traffic that your mesh services send and receive.

In {{< gloss >}}ambient{{< /gloss >}} mode, Istio's data plane uses node-level {{< gloss >}}ztunnel{{< /gloss >}} proxies deployed as a DaemonSet to mediate and control all traffic that your mesh services send and receive.
