---
title: What are the differences in telemetry reported by in-proxy telemetry (aka v2) and Mixer-based telemetry (aka v1)?
weight: 10
---

In-proxy telemetry (aka v2) reduces resource cost and improves proxy
performance as compared to the Mixer-based telemetry (aka v1) approach,
and is the preferred mechanism for surfacing telemetry in Istio.
However, there are few differences in reported telemetry between v1 and
v2 which are listed below:

* **Missing labels for out-of-mesh traffic**
  In-proxy telemetry relies on metadata exchange between Envoy proxies to gather
  information like peer workload name, namespace and labels. In Mixer-based telemetry
  this functionality was performed by Mixer as part of combining request attributes
  with the platform data. This metadata exchange is performed by the Envoy proxies
  by adding a specific HTTP header for HTTP protocol or augmenting
  ALPN protocol for TCP protocol as described
  [here](/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection).
  This requires Envoy proxies to be injected at both the client & server workloads,
  implying that the telemetry reported when one peer is not in the mesh will be
  missing peer attributes like workload name, namespace and labels.
  However, if both peers have proxies injected all the labels mentioned
  [here](/docs/reference/config/metrics/) are available in the generated metrics.
  When the server workload is out of the mesh, server workload metadata is still
  distributed to client sidecar, causing client side metrics to have server workload
  metadata labels filled.

* **TCP metadata exchange requires mTLS**
  TCP metadata exchange relies on the [Istio ALPN protocol](/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection)
  which requires mutual TLS (mTLS) to be enabled for the Envoy proxies
  to exchange metadata successfully. This implies that if mTLS is not
  enabled in your cluster, telemetry for TCP protocol will not include
  peer information like workload name, namespace and labels.

* **No mechanism for configuring custom buckets for histogram metrics**
  Mixer-based telemetry supported customizing buckets for histogram type metrics
  like request duration and TCP byte sizes. In-proxy telemetry has no such
  available mechanism. Additionally, the buckets available for latency metrics
  in in-proxy telemetry are in milliseconds as compared to seconds
  in Mixer-based telemetry. However, more buckets are available by default
  in in-proxy telemetry for latency metrics at the lower latency levels.

* **No metric expiration for short-lived metrics**
  Mixer-based telemetry supported metric expiration whereby metrics which were
  not generated for a configurable amount of time were de-registered for
  collection by Prometheus. This is useful in scenarios, such as one-off jobs, that generate short-lived metrics. De-registering
  the metrics prevents reporting of metrics which would no longer change in the
  future, thereby reducing network traffic and storage in Prometheus.
  This expiration mechanism is not available in in-proxy telemetry.
  The workaround for this can be found [here](/about/faq/#metric-expiry).
